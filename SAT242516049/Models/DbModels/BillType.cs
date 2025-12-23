using Attributes;

namespace SAT242516049.DbModels;

public class BillType
{
    [Title("Kayıt No")]
    public int ID { get; set; }

    [Title("Fatura Türü")]
    public string Name { get; set; } = string.Empty;

    [Title("Açıklama")]
    public string? Description { get; set; }
}