using System;
using System.ComponentModel.DataAnnotations;
using SAT242516049.Models.MyResource;

namespace SAT242516049.Entities;

public class Invoice
{
    [Sortable(true)]
    [Editable(false)]
    [Viewable(true)]
    [LocalizedDescription("Id", typeof(MyResource))]
    public int Id { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("CustomerId", typeof(MyResource))]
    public int CustomerId { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("InvoiceNo", typeof(MyResource))]
    public string InvoiceNo { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("Amount", typeof(MyResource))]
    public decimal Amount { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("InvoiceDate", typeof(MyResource))]
    public DateTime InvoiceDate { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("DueDate", typeof(MyResource))]
    public DateTime DueDate { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("IsPaid", typeof(MyResource))]
    public bool IsPaid { get; set; }
}