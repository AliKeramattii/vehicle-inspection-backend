using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Data.SqlClient;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace Bazdid.Api.Infrastructure.Sql
{
    public static class SqlRuntimeGate
    {
        public const string BlockReason = "O24/O26: provider متصل و Windows principal کم‌اختیار مصوب/آزموده نشده‌اند؛ SQL runtime این نسخه بسته است.";
        // فقط پس از پذیرش مستند و تغییر بازبینی‌شدهٔ کد قابل بازشدن است؛ flag تنظیمات جای آن نیست.
        public static bool ConnectedAcceptanceVerified => false;
    }
    public sealed class SqlRuntimeOptions
    {
        public bool Enabled { get; set; }
        public int CommandTimeoutSeconds { get; set; } = 10;
        public int ConnectionTimeoutSeconds { get; set; } = 5;
        public string ConnectionString { get; set; } = "";
        public string ApprovedWriterPrincipal { get; set; } = "";
        public void Validate(string environment)
        {
            if (environment != "Development" && environment != "Testing" && environment != "Production") throw new InvalidOperationException("محیط SQL معتبر نیست.");
            if (CommandTimeoutSeconds < 1 || CommandTimeoutSeconds > 60 || ConnectionTimeoutSeconds < 1 || ConnectionTimeoutSeconds > 15)
                throw new InvalidOperationException("مهلت SQL خارج از بازه است.");
            if (environment == "Production" && (Enabled || !string.IsNullOrEmpty(ConnectionString) || !string.IsNullOrEmpty(ApprovedWriterPrincipal)))
                throw new InvalidOperationException("SQL محیط Production هنوز پیکربندی/پذیرفته نشده است.");
            if (!string.IsNullOrEmpty(ConnectionString)) BuildLocalConnectionString();
            if (Enabled && !SqlRuntimeGate.ConnectedAcceptanceVerified) throw new InvalidOperationException(SqlRuntimeGate.BlockReason);
        }
        public string BuildLocalConnectionString()
        {
            SqlConnectionStringBuilder b;
            try
            {
                if (ConnectionString == null || ConnectionString.Length>4096 ||
                    Regex.IsMatch(ConnectionString,@"(^|;)\s*(password|pwd|user\s*id|uid)\s*=",RegexOptions.IgnoreCase|RegexOptions.CultureInvariant))
                    throw new ArgumentException();
                // کلیدهای غیرخالی فقط از فهرست محدود پذیرفته می‌شوند؛ credential خالی نیز پیش از parser رد می‌شود.
                var raw=new DbConnectionStringBuilder {ConnectionString=ConnectionString};
                var allowed=new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
                    "Data Source","Initial Catalog","Integrated Security","Encrypt","TrustServerCertificate","Connect Timeout","Application Name"
                };
                foreach (string key in raw.Keys) if (!allowed.Contains(key)) throw new ArgumentException();
                b = new SqlConnectionStringBuilder(ConnectionString);
            }
            catch (ArgumentException) { throw new InvalidOperationException("ساختار تنظیم اتصال معتبر نیست."); }
            catch (NotSupportedException) { throw new InvalidOperationException("ساختار تنظیم اتصال پشتیبانی نمی‌شود."); }
            if (b.DataSource != @"lpc:.\SQLSERVER2019" || b.InitialCatalog != "BAZDID_Development" || !b.IntegratedSecurity ||
                b.ShouldSerialize("Password") || b.ShouldSerialize("User ID") || !b.Encrypt || b.TrustServerCertificate ||
                b.AttachDBFilename.Length != 0 || b.MultipleActiveResultSets || b.FailoverPartner.Length != 0 ||
                b.UserInstance)
                throw new InvalidOperationException("مقصد/احراز هویت/سیاست اتصال محلی مجاز نیست.");
            b.ConnectTimeout=ConnectionTimeoutSeconds; b.ConnectRetryCount=0; b.ApplicationName="BAZDID-2F";
            b.Enlist=false; b.ApplicationIntent=ApplicationIntent.ReadWrite;
            return b.ConnectionString;
        }
    }
    public interface IBazdidWriteConnectionFactory { Task<SqlConnection> OpenAsync(CancellationToken cancellationToken); }
    public interface ISourceReadConnectionFactory { Task<SqlConnection> OpenAsync(CancellationToken cancellationToken); }
}
