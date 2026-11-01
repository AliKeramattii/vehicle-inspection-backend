using System;
using System.Linq;

namespace Bazdid.Api.Configuration
{
    public sealed class FoundationOptions
    {
        public const string RequiredBasePath = "/API/BAZDID";
        public string ApiBasePath { get; set; } = RequiredBasePath;
        public string HostingMode { get; set; } = "Standalone";
        public string[] TrustedFrontendOrigins { get; set; } = new string[0];
        public bool SwaggerEnabled { get; set; }
        public bool HttpsRedirectionEnabled { get; set; } = true;
        public bool HstsEnabled { get; set; }
        public int HttpsPort { get; set; } = 443;
        public string BrokerageAdapterMode { get; set; } = "Disabled";

        public void Validate(string environmentName)
        {
            if (environmentName != "Development" && environmentName != "Testing" && environmentName != "Production")
                throw new InvalidOperationException("Unsupported hosting environment.");
            if (ApiBasePath != RequiredBasePath)
                throw new InvalidOperationException("Bazdid:ApiBasePath must be /API/BAZDID without a trailing slash.");
            if (HostingMode != "Standalone" && HostingMode != "Iis")
                throw new InvalidOperationException("Bazdid:HostingMode must be Standalone or Iis.");
            if (BrokerageAdapterMode != "Disabled")
                throw new InvalidOperationException("Brokerage adapters are disabled in Checkpoint 1.");
            if (HttpsPort < 1 || HttpsPort > 65535)
                throw new InvalidOperationException("Bazdid:HttpsPort is invalid.");
            if (environmentName == "Production" && !HttpsRedirectionEnabled)
                throw new InvalidOperationException("HTTPS redirection is required in Production.");
            if (TrustedFrontendOrigins == null || TrustedFrontendOrigins.Any(origin => !IsValidOrigin(origin, environmentName)))
                throw new InvalidOperationException("Trusted frontend origins must be exact HTTPS origins (HTTP loopback is permitted outside Production).");
        }

        private static bool IsValidOrigin(string origin, string environmentName)
        {
            Uri uri;
            if (string.IsNullOrWhiteSpace(origin) || origin.Contains("*") || !Uri.TryCreate(origin, UriKind.Absolute, out uri))
                return false;
            return uri.UserInfo.Length == 0 && uri.Query.Length == 0 && uri.Fragment.Length == 0
                && uri.AbsolutePath == "/" && !origin.EndsWith("/", StringComparison.Ordinal)
                && (uri.Scheme == "https" || (environmentName != "Production" && uri.Scheme == "http" && uri.IsLoopback));
        }
    }
}
