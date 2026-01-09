using Microsoft.EntityFrameworkCore;
using SAT242516049.Entities;

namespace SAT242516049.Models.DbContexts;

public class MyDbModel_DbContext : DbContext
{
    public MyDbModel_DbContext(DbContextOptions<MyDbModel_DbContext> options)
        : base(options)
    {
    }

    public DbSet<Customer> Customers { get; set; }
    public DbSet<Invoice> Invoices { get; set; }
    public DbSet<Payment> Payments { get; set; }

}
