using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Data.SqlClient;
using System.Linq;
using System.Security.Principal;
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
        // D-P3-NAME (مصوب مالک 2026-11-07): `localhost` در SAN certificate هست ولی `.` نیست؛ Shared Memory و مقصد ثابت حفظ می‌شوند.
        public const string ApprovedLocalDataSource = @"lpc:localhost\SQLSERVER2019";
        public const string ApprovedDatabase = "BAZDID_Development";
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
            if (!string.Equals(b.DataSource,ApprovedLocalDataSource,StringComparison.Ordinal) || !string.Equals(b.InitialCatalog,ApprovedDatabase,StringComparison.Ordinal) || !b.IntegratedSecurity ||
                b.ShouldSerialize("Password") || b.ShouldSerialize("User ID") || !b.Encrypt || b.TrustServerCertificate ||
                b.AttachDBFilename.Length != 0 || b.MultipleActiveResultSets || b.FailoverPartner.Length != 0 ||
                b.UserInstance)
                throw new InvalidOperationException("مقصد/احراز هویت/سیاست اتصال محلی مجاز نیست.");
            b.ConnectTimeout=ConnectionTimeoutSeconds; b.ConnectRetryCount=0; b.ApplicationName="BAZDID-2F";
            b.Enlist=false; b.ApplicationIntent=ApplicationIntent.ReadWrite;
            return b.ConnectionString;
        }
    }
    /// <summary>
    /// نشانهٔ اجرای آزمون SQL متصل (P4). فقط اسمبلی‌های آزمون از طریق InternalsVisibleTo به آن دسترسی دارند؛
    /// DI برنامه فقط سازندهٔ public کارخانه را می‌بیند، پس Production و API عمومی همیشه پشت gate بسته می‌مانند.
    /// ساخت فقط وقتی ممکن است که محیط Testing، انتخاب صریح، مقصد ثابت و token واقعی Writer غیرمدیر برقرار باشد.
    /// </summary>
    internal sealed class ConnectedTestAcceptance
    {
        internal const string SelectionVariable = "BAZDID_CONNECTED_SQL";
        internal const string WriterAccount = "BAZDIDDevWriter";
        private const string AdministratorsSid = "S-1-5-32-544";
        private ConnectedTestAcceptance(string principal) { Principal=principal; }
        internal string Principal { get; }
        internal static bool Selected => Environment.GetEnvironmentVariable(SelectionVariable) == "1";
        internal static string ExpectedPrincipal => Environment.MachineName + @"\" + WriterAccount;
        internal static ConnectedTestAcceptance Create(string environment, SqlRuntimeOptions options)
        {
            if (!string.Equals(environment,"Testing",StringComparison.Ordinal)) throw new InvalidOperationException("آزمون SQL متصل فقط در محیط Testing مجاز است.");
            if (!Selected) throw new InvalidOperationException("اجرای SQL متصل صریحاً انتخاب نشده است.");
            if (options == null || options.Enabled) throw new InvalidOperationException("flag زمان اجرا باید بسته بماند؛ نشانهٔ آزمون جای آن نیست.");
            if (string.IsNullOrEmpty(options.ConnectionString)) throw new InvalidOperationException("مقصد SQL متصل تنظیم نشده است.");
            options.Validate(environment);
            options.BuildLocalConnectionString();
            var expected=ExpectedPrincipal;
            if (!string.Equals(options.ApprovedWriterPrincipal,expected,StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("principal مصوب Writer برابر نیست.");
            using (var identity=WindowsIdentity.GetCurrent())
            {
                if (!string.Equals(identity.Name,expected,StringComparison.OrdinalIgnoreCase) || identity.IsSystem || identity.IsGuest || identity.IsAnonymous)
                    throw new InvalidOperationException("token جاری Windows متعلق به Writer مصوب نیست.");
                // گروه Administrators حتی به‌صورت deny-only نیز پذیرفته نمی‌شود.
                if (identity.Groups != null && identity.Groups.Any(g => g.Value == AdministratorsSid))
                    throw new InvalidOperationException("token Writer نباید عضو Administrators باشد.");
            }
            return new ConnectedTestAcceptance(expected);
        }
    }
    public interface IBazdidWriteConnectionFactory { Task<SqlConnection> OpenAsync(CancellationToken cancellationToken); }
    public interface ISourceReadConnectionFactory { Task<SqlConnection> OpenAsync(CancellationToken cancellationToken); }
}
