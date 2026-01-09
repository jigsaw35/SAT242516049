use [SAT242516049]
go

-- 3. Tablo Oluşturma (Tahsilat / Ödeme)
-- Tablo yoksa oluşturur
if object_id('[dbo].[Payment]', 'U') is null
begin
    create table [dbo].[Payment]
    (
        [Id]            [int] identity (1,1) not null,
        [InvoiceId]     [int]                not null, -- Foreign Key
        [PaymentDate]   [datetime]           default getdate(), -- Ödeme Tarihi
        [Amount]        [decimal](18, 2)     null,     -- Ödenen Tutar
        [PaymentMethod] [nvarchar](50)       null,     -- Ödeme Yöntemi (Kredi Kartı, Nakit, Havale vb.)
        
        constraint [PK_Payment] primary key clustered
            (
             [Id] asc
            ) with (pad_index = off, statistics_norecompute = off, ignore_dup_key = off, allow_row_locks = on, allow_page_locks = on, optimize_for_sequential_key = off) on [PRIMARY],

        -- Foreign Key: Fatura Tablosu ile İlişki
        constraint [FK_Payment_Invoice] foreign key ([InvoiceId]) 
            references [dbo].[Invoice] ([Id])
            on delete cascade -- Fatura silinirse ödeme kaydı da silinsin
    ) on [PRIMARY]
end
go

-- View Index için SCHEMABINDING kullanımı (CREATE OR ALTER)
create or alter view [dbo].[Vw_Payment]
with schemabinding
as
    select p.Id
         , p.InvoiceId
         , p.PaymentDate
         , p.Amount
         , p.PaymentMethod
    from dbo.Payment as p
go

-- View üzerinde Clustered Index
if not exists (select * from sys.indexes where name = 'IX_Vw_Payment_Id' and object_id = object_id('[dbo].[Vw_Payment]'))
begin
    create unique clustered index [IX_Vw_Payment_Id] on [dbo].[Vw_Payment]
        (
         [Id] asc
        )
end
go

-- Arama performansı için Index
if not exists (select * from sys.indexes where name = 'IX_Payment_Search' and object_id = object_id('[dbo].[Payment]'))
begin
    create nonclustered index [IX_Payment_Search] on [dbo].[Payment]
        (
         [InvoiceId] asc,
         [PaymentDate] asc,
         [PaymentMethod] asc,
         [Id] asc
        )
end
go

-- CRUD İşlemleri (CREATE OR ALTER)
create or alter procedure [dbo].[sp_Payment_Add_Update_Remove] @operation varchar(10), @jsonvalues nvarchar(max)
as
begin

    select *
    into #temp
    from openjson(@jsonvalues)
                 with
                     (
                     Id int,
                     InvoiceId int,
                     PaymentDate datetime,
                     Amount decimal(18, 2),
                     PaymentMethod nvarchar(50)
                     )

    declare @rowcount int = null

    if @operation = 'add'
        begin
            insert Payment (InvoiceId, PaymentDate, Amount, PaymentMethod)
            select InvoiceId, PaymentDate, Amount, PaymentMethod
            from #temp

            set @rowcount = @@rowcount
        end

    if @operation = 'update'
        begin
            update s
            set s.InvoiceId = t.InvoiceId,
                s.PaymentDate = t.PaymentDate,
                s.Amount = t.Amount,
                s.PaymentMethod = t.PaymentMethod
            from #temp t join Payment s on t.Id = s.Id

            set @rowcount = @@rowcount
        end

    if @operation = 'remove'
        begin
            delete s
            from #temp t join Payment s on t.Id = s.Id

            set @rowcount = @@rowcount
        end

    select @operation [Key], iif(isnull(@rowcount, 0) > 0, 1, 0) [Value]

end
go

-- Listeleme ve Filtreleme Prosedürü (CREATE OR ALTER)
create or alter procedure [dbo].[Sp_Payments] @pagination Type_Dictionary_String_String readonly,
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

    -- Generic search (Ödeme Yöntemi içinde arama)
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
                          from Vw_Payment
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
                                      -- Ödeme Yöntemi içinde arama (Nakit, KK vs.)
                                      select 1 from @table_names t 
                                      where s.PaymentMethod like concat('%', t.value, '%')
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
                                  case when @orderby = 'PaymentDate asc' then PaymentDate end asc,
                                  case when @orderby = 'PaymentDate desc' then PaymentDate end desc,
                                  case when @orderby = 'Amount asc' then Amount end asc,
                                  case when @orderby = 'Amount desc' then Amount end desc,
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
create or alter trigger [dbo].[Trg_Payment_Insert_Update_Delete]
    on [dbo].[Payment]
    after insert, update, delete
    as
begin
    set nocount on;

    declare @tableName nvarchar(100) = 'Payment'
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