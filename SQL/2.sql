use [SAT242516049]
go

-- 2. Tablo Oluşturma (Fatura)
-- Eğer tablo yoksa oluşturur. Varsa dokunmaz.
if object_id('[dbo].[Invoice]', 'U') is null
begin
    create table [dbo].[Invoice]
    (
        [Id]          [int] identity (1,1) not null,
        [CustomerId]  [int]                not null, -- Foreign Key
        [InvoiceNo]   [varchar](20)        null,
        [Amount]      [decimal](18, 2)     null,
        [InvoiceDate] [datetime]           null,
        [DueDate]     [datetime]           null,
        [IsPaid]      [bit]                default 0,
        
        constraint [PK_Invoice] primary key clustered
            (
             [Id] asc
            ) with (pad_index = off, statistics_norecompute = off, ignore_dup_key = off, allow_row_locks = on, allow_page_locks = on, optimize_for_sequential_key = off) on [PRIMARY],

        -- Foreign Key Tanımlaması: Müşteri silinirse faturaları da silinsin (Cascade)
        constraint [FK_Invoice_Customer] foreign key ([CustomerId]) 
            references [dbo].[Customer] ([Id])
            on delete cascade
    ) on [PRIMARY]
end
go

-- View Index için SCHEMABINDING kullanımı (CREATE OR ALTER)
create or alter view [dbo].[Vw_Invoice]
with schemabinding
as
    select i.Id
         , i.CustomerId
         , i.InvoiceNo
         , i.Amount
         , i.InvoiceDate
         , i.DueDate
         , i.IsPaid
    from dbo.Invoice as i
go

-- View üzerinde Clustered Index (Varsa geç, yoksa oluştur)
if not exists (select * from sys.indexes where name = 'IX_Vw_Invoice_Id' and object_id = object_id('[dbo].[Vw_Invoice]'))
begin
    create unique clustered index [IX_Vw_Invoice_Id] on [dbo].[Vw_Invoice]
        (
         [Id] asc
        )
end
go

-- Arama performansı için Index (Varsa geç, yoksa oluştur)
if not exists (select * from sys.indexes where name = 'IX_Invoice_Search' and object_id = object_id('[dbo].[Invoice]'))
begin
    create nonclustered index [IX_Invoice_Search] on [dbo].[Invoice]
        (
         [InvoiceNo] asc,
         [CustomerId] asc,
         [IsPaid] asc,
         [Id] asc
        )
end
go

-- CRUD İşlemleri (CREATE OR ALTER)
create or alter procedure [dbo].[sp_Invoice_Add_Update_Remove] @operation varchar(10), @jsonvalues nvarchar(max)
as
begin

    select *
    into #temp
    from openjson(@jsonvalues)
                 with
                     (
                     Id int,
                     CustomerId int,
                     InvoiceNo varchar(20),
                     Amount decimal(18, 2),
                     InvoiceDate datetime,
                     DueDate datetime,
                     IsPaid bit
                     )

    declare @rowcount int = null

    if @operation = 'add'
        begin
            insert Invoice (CustomerId, InvoiceNo, Amount, InvoiceDate, DueDate, IsPaid)
            select CustomerId, InvoiceNo, Amount, InvoiceDate, DueDate, IsPaid
            from #temp

            set @rowcount = @@rowcount
        end

    if @operation = 'update'
        begin
            update s
            set s.CustomerId = t.CustomerId,
                s.InvoiceNo = t.InvoiceNo,
                s.Amount = t.Amount,
                s.InvoiceDate = t.InvoiceDate,
                s.DueDate = t.DueDate,
                s.IsPaid = t.IsPaid
            from #temp t join Invoice s on t.Id = s.Id

            set @rowcount = @@rowcount
        end

    if @operation = 'remove'
        begin
            delete s
            from #temp t join Invoice s on t.Id = s.Id

            set @rowcount = @@rowcount
        end

    select @operation [Key], iif(isnull(@rowcount, 0) > 0, 1, 0) [Value]

end
go

-- Listeleme ve Filtreleme Prosedürü (CREATE OR ALTER)
create or alter procedure [dbo].[Sp_Invoices] @pagination Type_Dictionary_String_String readonly,
                                    @where Type_Dictionary_String_String readonly
as
begin
    --sıralama
    declare @orderby nvarchar(max) = isnull((
                                                select [Value]
                                                from @pagination
                                                where [Key] = 'OrderBy'
                                            ), 'Id asc')
    --sayfalama
    declare @pagenumber int = isnull((
                                     select [Value]
                                     from @pagination
                                     where [Key] = 'PageNumber'
                                     ), 1)
    declare @pagesize int = isnull((
                                   select [Value]
                                   from @pagination
                                   where [Key] = 'PageSize'
                                   ), 10)

    --- filtreleme

    declare @table_ids table (id int)
    insert @table_ids(id)
    select ss.value
    from @where w
             cross apply string_split(w.[Value], ',') ss
    where w.[Key] = 'Id' and isnull(ss.value, '') <> ''

    -- Generic search (Fatura Numarası araması için)
    declare @table_names table (value nvarchar(100))
    insert @table_names(value)
    select ss.value
    from @where w
             cross apply string_split(w.[Value], ',') ss
    where w.[Key] = 'Name' and isnull(ss.value, '') <> ''


    -----------
    ;
    with cte_data as (
                          select *
                          from Vw_Invoice
                      )
       , cte_filter as (
                          select s.*
                          from cte_data s
                          where (not exists
                                  (
                                      select 1
                                      from @table_ids
                                  ) or exists
                                  (
                                      select 1
                                      from @table_ids t
                                      where s.Id = t.id
                                  ))
                            and (not exists
                                  (
                                      select 1
                                      from @table_names
                                  ) or exists
                                  (
                                      select 1 from @table_names t 
                                      where s.InvoiceNo like concat('%', t.value, '%')
                                  )
                             )
                      )
       , cte_total_count as (
                          select count(*) TotalRecordCount
                               , ceiling(cast(count(*) as float) / @pagesize) TotalPageCount
                          from cte_filter
                      )
       , cte_ordered as (
                          select *
                               , row_number() over
                              (order by
                                  case when @orderby = 'Id asc' then Id end asc,
                                  case when @orderby = 'Id desc' then Id end desc,
                                  case when @orderby = 'InvoiceNo asc' then InvoiceNo end asc,
                                  case when @orderby = 'InvoiceNo desc' then InvoiceNo end desc,
                                  case when @orderby = 'Amount asc' then Amount end asc,
                                  case when @orderby = 'Amount desc' then Amount end desc,
                                  case when @orderby = 'DueDate asc' then DueDate end asc,
                                  case when @orderby = 'DueDate desc' then DueDate end desc,
                                  Id asc
                              ) RowNumber
                          from cte_filter
                      )

       , cte_pagination as (
                          select TotalRecordCount
                               , TotalPageCount
                               , iif(@pagenumber > TotalPageCount, TotalPageCount, @pagenumber) PageNumber
                          from cte_total_count
                      )
    select *
    from cte_ordered, cte_pagination
    where RowNumber between (@pagesize * (PageNumber - 1)) + 1 and @pagesize * PageNumber
    order by RowNumber
end
go

-- Loglama Trigger'ı (CREATE OR ALTER)
create or alter trigger [dbo].[Trg_Invoice_Insert_Update_Delete]
    on [dbo].[Invoice]
    after insert, update, delete
    as
begin
    set nocount on;

    declare @tableName nvarchar(100) = 'Invoice'
    declare @rowid int =
        (
            select coalesce(i.Id, d.Id, 0)
            from inserted i
                     full join deleted d on i.Id = d.Id
        )

    declare @actiontype varchar(10) =
        (
            select case
                       when i.Id is not null and d.Id is null then 'insert'
                       when i.Id is not null and d.Id is not null then 'update'
                       when i.Id is null and d.Id is not null then 'delete'
                       end
            from inserted i
                     full join deleted d on i.Id = d.Id
        )

    declare @oldvalues nvarchar(max) = (select * from deleted for json path)
    declare @newvalues nvarchar(max) = (select * from inserted for json path)

    insert into Logs_Table (TableName, RowId, ActionType, OldValue, NewValue)
    values (@tableName, @rowid, @actiontype, @oldvalues, @newvalues)
end
go