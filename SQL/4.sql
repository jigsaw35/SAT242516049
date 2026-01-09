use [SAT242516049]
go

create or alter procedure Sp_Customers_Chart
as
begin

    with cte_data as
             (
                 select c.Id as CustomerId
                      , concat(c.FirstName, ' ', c.LastName) as CustomerName -- Ad ve Soyadı birleştirdik
                      
                      -- SENARYO: Müşterinin faturalarının hangi aya denk geldiğini buluyoruz.
                      -- Invoice tablosunda 'InvoiceDate' olduğu için gerçek tarihi kullanıyoruz.
                      , case 
                          when i.Id is null then 0 
                          else MONTH(i.InvoiceDate) 
                        end as MonthNum
                      
                      , i.Id as InvoiceId
                 from Customer c
                      -- Müşteriden Faturaya geçiş (Left Join: Hiç faturası olmayanları da listede görelim)
                      left join Invoice i on i.CustomerId = c.Id
             )
    select CustomerId, CustomerName
           -- 1'den 12'ye kadar olan aylar (Ocak - Aralık)
         , isnull([1], 0) as Ocak
         , isnull([2], 0) as Subat
         , isnull([3], 0) as Mart
         , isnull([4], 0) as Nisan
         , isnull([5], 0) as Mayis
         , isnull([6], 0) as Haziran
         , isnull([7], 0) as Temmuz
         , isnull([8], 0) as Agustos
         , isnull([9], 0) as Eylul
         , isnull([10], 0) as Ekim
         , isnull([11], 0) as Kasim
         , isnull([12], 0) as Aralik
    from cte_data
             pivot
             (
             -- Hangi ayda (MonthNum) kaç tane fatura (InvoiceId) kesilmiş sayıyoruz
             count(InvoiceId) for MonthNum in ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
             ) p
    order by CustomerId

end
go