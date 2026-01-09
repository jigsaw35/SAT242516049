using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using SAT242516049.Entities; // Doğru entity namespace'i

namespace MyReports;

public class Report_Customer
{
    static IContainer CellStyle(IContainer container) =>
        container
            .Padding(5)
            .BorderBottom(1)
            .BorderColor(Colors.Grey.Lighten2);

    public byte[] Generate(List<Customer> customers)
    {
        QuestPDF.Settings.License = LicenseType.Community;

        // Dosya yolu hatasını önlemek için kontrol
        var imagePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "logo_siyah.png");
        byte[] imageData = File.Exists(imagePath) ? File.ReadAllBytes(imagePath) : new byte[0];

        return Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(50);

                page.Header().Text("Customer List")
                    .FontSize(20)
                    .Bold()
                    .FontColor(Colors.Blue.Medium);

                page.Content().PaddingVertical(10).Column(col =>
                {
                    col.Item().Row(row =>
                    {
                        if (imageData.Length > 0)
                        {
                            row.ConstantColumn(100).Image(imageData);
                        }

                        row.RelativeColumn().AlignRight().Column(c =>
                        {
                            c.Item().Text("Rapor Detayı").FontSize(14).Bold();
                            c.Item().Text($"Tarih: {DateTime.Now:dd.MM.yyyy}");
                        });
                    });

                    col.Item().PaddingTop(20).Table(table =>
                    {
                        // DİKKAT: 5 kolonunuz olduğu için 5 RelativeColumn tanımlanmalı
                        table.ColumnsDefinition(columns =>
                        {
                            columns.RelativeColumn(1); // Id
                            columns.RelativeColumn(3); // Name
                            columns.RelativeColumn(2); // Rate
                            columns.RelativeColumn(2); // Date
                            columns.RelativeColumn(1); // Status
                        });

                        // Başlık
                        table.Header(header =>
                        {
                            header.Cell().Element(CellStyle).Text("Id").Bold();
                            header.Cell().Element(CellStyle).Text("Name").Bold();
                            header.Cell().Element(CellStyle).Text("TCKN").Bold();
                            header.Cell().Element(CellStyle).Text("SubscriberNo").Bold();
                            header.Cell().Element(CellStyle).Text("Phone").Bold();
                        });

                        foreach (var c in customers)
                        {
                            table.Cell().Element(CellStyle).Text(c.Id.ToString());
                            table.Cell().Element(CellStyle).Text(c.FirstName + " " + c.LastName);
                            table.Cell().Element(CellStyle).Text(c.TCKN);
                            table.Cell().Element(CellStyle).Text(c.SubscriberNo);
                            table.Cell().Element(CellStyle).Text(c.Phone);
                        }
                    });
                });

                page.Footer().AlignCenter().Text(t =>
                {
                    t.Span("Sayfa ");
                    t.CurrentPageNumber();
                    t.Span(" / ");
                    t.TotalPages();
                });
            });
        }).GeneratePdf();
    }
}