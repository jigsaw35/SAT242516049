using Attributes;

namespace SAT242516049.DbModels;

public class Customer
{
    [Title("Kayıt No")]
    public int ID { get; set; }

    [Title("Ad")]
    public string Name { get; set; } = string.Empty;

    [Title("Soyad")]
    public string Surname { get; set; } = string.Empty;

    [Title("T.C. Kimlik No")]
    public string IdentityNo { get; set; } = string.Empty;

    [Title("Telefon")]
    public string? Phone { get; set; }

    [Title("E-Posta")]
    public string? Email { get; set; }

    [Title("Adres")]
    public string? Address { get; set; }

    [Title("Durum")]
    public bool IsActive { get; set; } = true;

    [Title("Oluşturulma Tarihi")]
    public DateTime CreatedDate { get; set; }
}