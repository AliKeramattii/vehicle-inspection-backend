using System;
using Bazdid.Api.Configuration;
using Xunit;

namespace Bazdid.UnitTests
{
    public class FoundationOptionsTests
    {
        [Theory]
        [InlineData("Development")]
        [InlineData("Testing")]
        [InlineData("Production")]
        public void Future_integrations_are_not_required_to_validate_foundation(string environment)
        {
            new FoundationOptions().Validate(environment);
        }

        [Theory]
        [InlineData("/api")]
        [InlineData("/API/BAZDID/")]
        [InlineData("/API/BAZDID/API/BAZDID")]
        public void Rejects_an_invalid_public_base(string path)
        {
            var settings = new FoundationOptions { ApiBasePath = path };
            Assert.Throws<InvalidOperationException>(() => settings.Validate("Testing"));
        }

        [Theory]
        [InlineData("*")]
        [InlineData("https://*.example.invalid")]
        [InlineData("https://frontend.example.invalid/path")]
        [InlineData("https://frontend.example.invalid/")]
        [InlineData("https://frontend.example.invalid?token=private")]
        [InlineData("https://user:password@frontend.example.invalid")]
        [InlineData("http://frontend.example.invalid")]
        public void Rejects_untrusted_origin_patterns_without_echoing_values(string origin)
        {
            var settings = new FoundationOptions { TrustedFrontendOrigins = new[] { origin } };
            var error = Assert.Throws<InvalidOperationException>(() => settings.Validate("Production"));
            Assert.DoesNotContain(origin, error.Message);
        }

        [Fact]
        public void Local_http_origin_is_allowed_only_outside_production()
        {
            var settings = new FoundationOptions { TrustedFrontendOrigins = new[] { "http://localhost:3000" } };
            settings.Validate("Development");
            Assert.Throws<InvalidOperationException>(() => settings.Validate("Production"));
        }

        [Fact]
        public void Production_requires_https_and_unconfigured_synthetic_is_rejected()
        {
            Assert.Throws<InvalidOperationException>(() => new FoundationOptions { HttpsRedirectionEnabled = false }.Validate("Production"));
            Assert.Throws<InvalidOperationException>(() => new FoundationOptions { BrokerageAdapterMode = "Synthetic" }.Validate("Testing"));
            Assert.Throws<InvalidOperationException>(() => new FoundationOptions { HostingMode = "Automatic" }.Validate("Testing"));
            Assert.Throws<InvalidOperationException>(() => new FoundationOptions().Validate("Staging"));
        }
    }
}
