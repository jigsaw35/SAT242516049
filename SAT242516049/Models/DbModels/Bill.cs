using Attributes;

namespace SAT242516049.DbModels;

public class Bill
{
    public Bill()
    {
        // Varsayılan Değerler: Form açıldığında tarih bugün olsun.
        BillDate = DateTime.Now;
        DueDate = DateTime.Now.AddDays(30); // Son ödeme 1 ay sonra olsun
        Amount = 0;
    }

    [Title("Fatura No")]
    public int ID { get; set; }

    [Title("Müşteri")] // "Müşteri ID" yerine sadece "Müşteri" yazdık
    public int CustomerID { get; set; }

    // Listede görünmesi için (Veritabanında yok, View ile geliyor)
    [Title("Müşteri")]
    public string? CustomerName { get; set; }

    [Title("T.C. Kimlik No")]
    public string? IdentityNo { get; set; }

    [Title("Fatura Türü")] // "Fatura Türü ID" yerine düzgün isim
    public int BillTypeID { get; set; }

    [Title("Fatura Türü")]
    public string? BillTypeName { get; set; }

    [Title("Fatura Tarihi")]
    public DateTime BillDate { get; set; }

    [Title("Son Ödeme Tarihi")]
    public DateTime DueDate { get; set; }

    [Title("Tutar (₺)")]
    public decimal Amount { get; set; }

    [Title("Ödendi mi?")]
    public bool IsPaid { get; set; }
}