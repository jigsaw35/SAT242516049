using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using SAT242516049.DbModels;

namespace SAT242516049.Data
{
    public class PdfService
    {
        public byte[] GenerateBillsPdf(List<Bill> bills)
        {
            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(2, Unit.Centimetre);
                    page.PageColor(Colors.White);
                    page.DefaultTextStyle(x => x.FontSize(12));

                    page.Header()
                        .Text("Fatura Listesi Raporu")
                        .SemiBold().FontSize(20).FontColor(Colors.Blue.Medium);

                    page.Content()
                        .PaddingVertical(1, Unit.Centimetre)
                        .Table(table =>
                        {
                            table.ColumnsDefinition(columns =>
                            {
                                columns.ConstantColumn(50);
                                columns.RelativeColumn();
                                columns.RelativeColumn();
                                columns.ConstantColumn(80);
                                columns.ConstantColumn(80);
                            });

                            table.Header(header =>
                            {
                                header.Cell().Element(CellStyle).Text("No");
                                header.Cell().Element(CellStyle).Text("Müşteri");
                                header.Cell().Element(CellStyle).Text("Tür");
                                header.Cell().Element(CellStyle).Text("Tutar");
                                header.Cell().Element(CellStyle).Text("Durum");
                                static IContainer CellStyle(IContainer container) => container.DefaultTextStyle(x => x.SemiBold()).PaddingVertical(5).BorderBottom(1).BorderColor(Colors.Black);
                            });

                            foreach (var bill in bills)
                            {
                                table.Cell().Element(CellStyle).Text(bill.ID.ToString());
                                table.Cell().Element(CellStyle).Text(bill.CustomerName ?? "-");
                                table.Cell().Element(CellStyle).Text(bill.BillTypeName ?? "-");
                                table.Cell().Element(CellStyle).Text($"{bill.Amount:C2}");
                                table.Cell().Element(CellStyle).Text(bill.IsPaid ? "Ödendi" : "Ödenmedi");
                                static IContainer CellStyle(IContainer container) => container.BorderBottom(1).BorderColor(Colors.Grey.Lighten2).PaddingVertical(5);
                            }
                        });

                    page.Footer().AlignCenter().Text(x => { x.Span("Sayfa "); x.CurrentPageNumber(); });
                });
            })
            .GeneratePdf();
        }
    }
}