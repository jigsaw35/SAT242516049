using System.Collections.Generic; // Dictionary hatasý için þart!
using System.Data;
using Microsoft.Data.SqlClient;

namespace Extensions;

public static class Extensions_SqlParameter
{
    // --- 1. SÝLÝNEN PARÇA GERÝ GELDÝ (Hatayý Çözen Kýsým) ---
    #region ToSqlParameter_Table_Type_Dictionary

    public static SqlParameter ToSqlParameter_Table_Type_Dictionary<TKey, TValue>(
        this IDictionary<TKey, TValue> dictionary,
        string parameterName,
        string parameterTypeName = "",
        int length = 0,
        SqlDbType sqlDbType = SqlDbType.Structured,
        ParameterDirection direction = ParameterDirection.Input)
    {
        var keyTypeName = "Int";
        var keyType = typeof(TKey);
        if (keyType == typeof(int) || keyType == typeof(int?)) keyTypeName = "Int";
        else if (keyType == typeof(string)) keyTypeName = "String";
        else if (keyType == typeof(object)) keyTypeName = "Object";

        var valueTypeName = "Int";
        var valueType = typeof(TValue);
        if (valueType == typeof(int) || valueType == typeof(int?)) valueTypeName = "Int";
        else if (valueType == typeof(string)) valueTypeName = "String";
        else if (valueType == typeof(object)) valueTypeName = "Object";

        parameterTypeName = $"Type_Dictionary_{keyTypeName}_{valueTypeName}";

        var dt = new DataTable();
        dt.Columns.Add("Key", typeof(TKey));
        dt.Columns.Add("Value", typeof(TValue));
        foreach (var item in dictionary)
        {
            var row = dt.NewRow();
            row[0] = item.Key;
            row[1] = item.Value;
            dt.Rows.Add(row);
        }

        return new SqlParameter()
        {
            SqlDbType = sqlDbType,
            Direction = direction,
            ParameterName = parameterName,
            TypeName = parameterTypeName,
            Value = dt
        };
    }

    #endregion

    // --- 2. TARÝH VE NULL HATASINI ÇÖZEN KISIM ---
    #region ToSqlParameter_Data_Type

    public static SqlParameter ToSqlParameter_Data_Type<T>(
        this T value,
        string parameterName,
        ParameterDirection direction = ParameterDirection.Input,
        SqlDbType sqlDbType = SqlDbType.NVarChar)
    {
        Type type = value?.GetType() ?? typeof(object);

        if (type == typeof(int) || type == typeof(int?))
            sqlDbType = SqlDbType.Int;
        else if (type == typeof(long) || type == typeof(long?))
            sqlDbType = SqlDbType.BigInt;
        else if (type == typeof(decimal) || type == typeof(decimal?))
            sqlDbType = SqlDbType.Decimal;
        else if (type == typeof(float) || type == typeof(float?))
            sqlDbType = SqlDbType.Float;
        else if (type == typeof(double) || type == typeof(double?))
            sqlDbType = SqlDbType.Float;
        else if (type == typeof(DateTime) || type == typeof(DateTime?))
            sqlDbType = SqlDbType.DateTime2;
        else if (type == typeof(bool) || type == typeof(bool?))
            sqlDbType = SqlDbType.Bit;
        else if (type == typeof(Guid) || type == typeof(Guid?))
            sqlDbType = SqlDbType.UniqueIdentifier;

        var parameter = new SqlParameter
        {
            SqlDbType = sqlDbType,
            Direction = direction,
            ParameterName = parameterName,
            Value = (object)value ?? DBNull.Value
        };

        return parameter;
    }

    #endregion
}