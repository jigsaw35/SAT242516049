using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SAT242516049.Components;
using SAT242516049.Components.Account;
using SAT242516049.Data;

// --- PROJE ÝÇÝN GEREKLÝ NAMESPACE'LER ---

using UnitOfWorks;
using Providers;
using DbContexts;
// -----------------------------------------
QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;
var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents(); // Madde 16: Server Etkileþimi

builder.Services.AddCascadingAuthenticationState();
builder.Services.AddScoped<SAT242516049.Data.PdfService>();
builder.Services.AddScoped<IdentityUserAccessor>();
builder.Services.AddScoped<IdentityRedirectManager>();
builder.Services.AddScoped<AuthenticationStateProvider, IdentityRevalidatingAuthenticationStateProvider>();

builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = IdentityConstants.ApplicationScheme;
    options.DefaultSignInScheme = IdentityConstants.ExternalScheme;
})
    .AddIdentityCookies();

// Veritabaný Baðlantý Cümlesi
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

// 1. STANDART IDENTITY CONTEXT (Kullanýcý tablolarý için)
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

// -----------------------------------------------------------------------------
// 2. PROJE ALTYAPI SERVÝSLERÝ (Yönerge Madde 22 Hiyerarþisi)
// -----------------------------------------------------------------------------

// A. Kendi DbContext Yapýmýz (Veri tabaný ile iletiþim)
builder.Services.AddDbContext<MyDbModel_DbContext>(options =>
    options.UseSqlServer(connectionString));

// B. UnitOfWork Kaydý (SP Çalýþtýrma Motoru)
// Generic yapýda olduðu için DbContext tipini belirtiyoruz.
builder.Services.AddScoped<IMyDbModel_UnitOfWork, MyDbModel_UnitOfWork<MyDbModel_DbContext>>();

// C. Provider Kaydý (Arayüzün muhatap olduðu katman)
builder.Services.AddScoped<IMyDbModel_Provider, MyDbModel_Provider>();

// -----------------------------------------------------------------------------

builder.Services.AddDatabaseDeveloperPageExceptionFilter();

// Identity Ayarlarý (Madde 17)
builder.Services.AddIdentityCore<ApplicationUser>(options => options.SignIn.RequireConfirmedAccount = true)
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddSignInManager()
    .AddDefaultTokenProviders();

builder.Services.AddSingleton<IEmailSender<ApplicationUser>, IdentityNoOpEmailSender>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseMigrationsEndPoint();
}
else
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode(); // Server Modu Aktif

// Add additional endpoints required by the Identity /Account Razor components.
app.MapAdditionalIdentityEndpoints();

app.Run();