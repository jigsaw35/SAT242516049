using Attributes;

namespace SAT242516049.DbModels;

public class StatItem
{
    [Title("Etiket")]
    public string Label { get; set; } = "";

    [Title("Değer")]
    public decimal Value { get; set; }
}