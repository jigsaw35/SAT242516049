using System.Data;
using Microsoft.Data.SqlClient; // <-- BU EKLENDÝ (SqlParameter için þart)
using Extensions;
using Microsoft.EntityFrameworkCore;
using MyDbModels;

namespace UnitOfWorks;

public interface IMyDbModel_UnitOfWork
{
    Task Execute<T>(IMyDbModel<T> myDbModel, string spName = "", bool isPagination = true)
        where T : class, new();
}

public sealed class MyDbModel_UnitOfWork<TDbContext>(TDbContext context) : IMyDbModel_UnitOfWork where TDbContext : DbContext
{
    private readonly DbContext _context = context;

    public async Task Execute<T>(IMyDbModel<T> myDbModel, string spName = "", bool isPagination = true) where T : class, new()
    {
        var con = _context.Database.GetDbConnection();
        try
        {
            if (con.State != ConnectionState.Open) await con.OpenAsync();

            using (var cmd = con.CreateCommand())
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = spName;
                cmd.CommandTimeout = 60; // Timeout süresi

                var pageno = myDbModel.Parameters.PageNumber;
                var pagesize = myDbModel.Parameters.PageSize;
                var orderby = myDbModel.Parameters.OrderBy;
                var _params = myDbModel.Parameters.Params;
                var where = myDbModel.Parameters.Where;

                cmd.Parameters.Clear();

                // 1. OTOMATÝK SAYFALAMA (Execute(..., isPagination: true) denilirse burasý çalýþýr)
                if (isPagination)
                {
                    var pagination = new Dictionary<string, string> { { "PageNumber", pageno.ToString() }, { "PageSize", pagesize.ToString() }, { "OrderBy", orderby } };
                    cmd.Parameters.Add(pagination.ToSqlParameter_Table_Type_Dictionary("pagination"));
                }

                // 2. FÝLTRELER (Varsa)
                if (where?.Any() == true)
                    cmd.Parameters.Add(where.ToSqlParameter_Table_Type_Dictionary("where"));

                // 3. EKSTRA PARAMETRELER (Sorunun kaynaðý burasýydý, düzelttik)
                if (_params?.Any() == true)
                {
                    foreach (var param in _params)
                    {
                        // KRÝTÝK DÜZELTME:
                        // Eðer gönderilen deðer zaten SQL'e hazýr bir 'SqlParameter' ise (Bills.razor'da yaptýðýn gibi),
                        // onu tekrar dönüþtürme, direkt ekle.
                        if (param.Value is SqlParameter sqlParam)
                        {
                            cmd.Parameters.Add(sqlParam);
                        }
                        else
                        {
                            // Deðilse (int, string vs.) dönüþtürüp ekle.
                            cmd.Parameters.Add(param.Value.ToSqlParameter_Data_Type(param.Key));
                        }
                    }
                }

                // --- ÇALIÞTIRMA ---
                var table = new DataTable();
                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    table.Load(reader);
                }

                // --- SONUÇLARI ALMA ---
                if (isPagination && table.Rows.Count > 0 && table.Columns.Contains("TotalRecordCount"))
                    myDbModel.Parameters.TotalRecordCount = Convert.ToInt32(table.Rows[0]["TotalRecordCount"]);

                myDbModel.Items = table.DataTableToList<T>();
            }
        }
        catch (Exception ex)
        {
            myDbModel.Message = $"Ýþlem Hatasý ({spName}): {ex.Message}";
        }
        finally
        {
            if (con.State == ConnectionState.Open) await con.CloseAsync();
        }
    }
}