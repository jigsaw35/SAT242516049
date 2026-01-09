using System;
using System.ComponentModel.DataAnnotations;
using SAT242516049.Models.MyResource;

namespace SAT242516049.Entities;

public class Payment
{
    [Sortable(true)]
    [Editable(false)]
    [Viewable(true)]
    [LocalizedDescription("Id", typeof(MyResource))]
    public int Id { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("InvoiceId", typeof(MyResource))]
    public int InvoiceId { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("PaymentDate", typeof(MyResource))]
    public DateTime PaymentDate { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("Amount", typeof(MyResource))]
    public decimal Amount { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("PaymentMethod", typeof(MyResource))]
    public string PaymentMethod { get; set; }
}