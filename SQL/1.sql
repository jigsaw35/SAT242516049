use [SAT242516049]
go

-- Eğer tablo yoksa oluşturur (Tablo için CREATE OR ALTER yoktur, bu kontrol güvenlidir)
if object_id('[dbo].[Customer]', 'U') is null
begin
    create table [dbo].[Customer]
    (
        [Id]           [int] identity (1,1) not null,
        [FirstName]    [nvarchar](50)       null, -- Müşteri Adı
        [LastName]     [nvarchar](50)       null, -- Müşteri Soyadı
        [TCKN]         [varchar](11)        null, -- TC Kimlik No
        [SubscriberNo] [varchar](20)        null, -- Abone Numarası
        [Phone]        [nvarchar](20)       null, -- Telefon
        constraint [PK_Customer] primary key clustered
            (
             [Id] asc
                ) with (pad_index = off, statistics_norecompute = off, ignore_dup_key = off, allow_row_locks = on, allow_page_locks = on, optimize_for_sequential_key = off) on [PRIMARY]
    ) on [PRIMARY]
end
go

-- View Index için SCHEMABINDING kullanımı (CREATE OR ALTER kullanıldı)
create or alter view [dbo].[Vw_Customer]
with schemabinding
as
    select c.Id
         , c.FirstName
         , c.LastName
         , c.TCKN
         , c.SubscriberNo
         , c.Phone
    from dbo.Customer as c
go

-- View üzerinde Clustered Index (Index'ler için ALTER olmaz, mevcutsa geçiyoruz)
if not exists (select * from sys.indexes where name = 'IX_Vw_Customer_Id' and object_id = object_id('[dbo].[Vw_Customer]'))
begin
    create unique clustered index [IX_Vw_Customer_Id] on [dbo].[Vw_Customer]
        (
         [Id] asc
        )
end
go

-- İsim, TCKN ve AboneNo ile arama performansı için NonClustered Index
if not exists (select * from sys.indexes where name = 'IX_Customer_Search' and object_id = object_id('[dbo].[Customer]'))
begin
    create nonclustered index [IX_Customer_Search] on [dbo].[Customer]
        (
         [FirstName] asc,
         [LastName] asc,
         [TCKN] asc,
         [SubscriberNo] asc,
         [Id] asc
            )
end
go

-- CRUD İşlemleri (CREATE OR ALTER kullanıldı)
create or alter procedure [dbo].[sp_Customer_Add_Update_Remove] @operation varchar(10), @jsonvalues nvarchar(max)
as
begin

    select *
    into #temp
    from openjson(@jsonvalues)
                 with
                     (
                     Id int,
                     FirstName nvarchar(50),
                     LastName nvarchar(50),
                     TCKN varchar(11),
                     SubscriberNo varchar(20),
                     Phone nvarchar(20)
                     )

    declare @rowcount int = null

    if @operation = 'add'
        begin
            insert Customer (FirstName, LastName, TCKN, SubscriberNo, Phone)
            select FirstName, LastName, TCKN, SubscriberNo, Phone
            from #temp

            set @rowcount = @@rowcount
        end

    if @operation = 'update'
        begin
            update s
            set s.FirstName = t.FirstName,
                s.LastName = t.LastName,
                s.TCKN = t.TCKN,
                s.SubscriberNo = t.SubscriberNo,
                s.Phone = t.Phone
            from #temp t join Customer s on t.Id = s.Id

            set @rowcount = @@rowcount
        end

    if @operation = 'remove'
        begin
            -- İlişkisel bütünlük için önce bu müşteriye ait faturalar kontrol edilebilir
            -- Ancak şimdilik direkt siliyoruz (Cascade ayarlı ise faturalar da gider)
            delete s
            from #temp t join Customer s on t.Id = s.Id

            set @rowcount = @@rowcount
        end

    select @operation [Key], iif(isnull(@rowcount, 0) > 0, 1, 0) [Value]

end
go

-- Listeleme ve Filtreleme Prosedürü (CREATE OR ALTER kullanıldı)
create or alter procedure [dbo].[Sp_Customers] @pagination Type_Dictionary_String_String readonly,
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

    -- Generic search
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
                          from Vw_Customer
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
                                      where s.FirstName like concat('%', t.value, '%') 
                                           or s.LastName like concat('%', t.value, '%')
                                           or s.TCKN like concat('%', t.value, '%')
                                           or s.SubscriberNo like concat('%', t.value, '%')
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
                                  case when @orderby = 'FirstName asc' then FirstName end asc,
                                  case when @orderby = 'FirstName desc' then FirstName end desc,
                                  case when @orderby = 'LastName asc' then LastName end asc,
                                  case when @orderby = 'LastName desc' then LastName end desc,
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

-- Loglama Trigger'ı (CREATE OR ALTER kullanıldı)
create or alter trigger [dbo].[Trg_Customer_Insert_Update_Delete]
    on [dbo].[Customer]
    after insert, update, delete
    as
begin
    set nocount on;

    declare @tableName nvarchar(100) = 'Customer'
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

    -- Logs_Table sistemde yoksa hata vermemesi için kontrol eklenebilir ama standart şablona sadık kalıyorum
    insert into Logs_Table (TableName, RowId, ActionType, OldValue, NewValue)
    values (@tableName, @rowid, @actiontype, @oldvalues, @newvalues)
end
go