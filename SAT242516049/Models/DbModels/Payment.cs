using Attributes;

namespace SAT242516049.DbModels;

public class Payment
{
    [Title("İşlem No")]
    public int ID { get; set; }

    [Title("Fatura No")]
    public int BillID { get; set; }

    [Title("Ödeme Tarihi")]
    public DateTime PaymentDate { get; set; }

    [Title("Ödenen Tutar")]
    public decimal AmountPaid { get; set; }

    [Title("Ödeme Yöntemi")]
    public string? PaymentMethod { get; set; }
}