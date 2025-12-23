using System.Data;
using System.Reflection;

namespace Extensions;

public static class Extensions_DataTable
{
    public static IEnumerable<T> DataTableToList<T>(this DataTable table) where T : class, new()
    {
        var list = new List<T>();
        // try-catch KALDIRILDI. Hata varsa görelim!

        var columnNames = new List<string>();
        foreach (DataColumn DataColumn in table.Columns)
            columnNames.Add(DataColumn.ColumnName);

        // Her satýrý çevir
        foreach (DataRow row in table.Rows)
        {
            list.Add(GetObject<T>(row, columnNames));
        }

        return list;
    }

    public static T GetObject<T>(this DataRow row, List<string> columnsName) where T : class, new()
    {
        T obj = new T();
        // try-catch KALDIRILDI.

        PropertyInfo[] Properties = typeof(T).GetProperties();
        foreach (PropertyInfo objProperty in Properties)
        {
            // Sütun ismini bul
            string columnname = columnsName.Find(name => name.Equals(objProperty.Name, StringComparison.OrdinalIgnoreCase));

            if (!string.IsNullOrEmpty(columnname))
            {
                object dbValue = row[columnname];
                if (dbValue != DBNull.Value)
                {
                    // TÜR DÖNÜÞÜMÜ (En çok hata buradaki uyumsuzluktan çýkar)
                    Type targetType = Nullable.GetUnderlyingType(objProperty.PropertyType) ?? objProperty.PropertyType;

                    try
                    {
                        object convertedValue = Convert.ChangeType(dbValue, targetType);
                        objProperty.SetValue(obj, convertedValue, null);
                    }
                    catch (Exception ex)
                    {
                        // HATA BURADA! Hangi kolonda patladýðýný konsola yazalým.
                        throw new Exception($"HATA: '{columnname}' kolonu '{targetType.Name}' türüne çevrilemedi. Gelen Deðer: {dbValue} - Hata: {ex.Message}");
                    }
                }
            }
        }
        return obj;
    }
}