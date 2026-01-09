using System;
using System.ComponentModel.DataAnnotations;
using SAT242516049.Models.MyResource;

namespace SAT242516049.Entities;

public class Customer
{
    [Sortable(true)]
    [Editable(false)]
    [Viewable(true)]
    [LocalizedDescription("Id", typeof(MyResource))]
    public int Id { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("FirstName", typeof(MyResource))]
    public string FirstName { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("LastName", typeof(MyResource))]
    public string LastName { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("TCKN", typeof(MyResource))]
    public string TCKN { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("SubscriberNo", typeof(MyResource))]
    public string SubscriberNo { get; set; }

    [Sortable(true)]
    [Editable(true)]
    [Viewable(true)]
    [LocalizedDescription("Phone", typeof(MyResource))]
    public string Phone { get; set; }
}