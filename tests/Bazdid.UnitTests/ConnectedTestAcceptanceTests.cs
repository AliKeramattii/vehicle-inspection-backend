using System;
using System.Linq;
using System.Reflection;
using Bazdid.Api.Infrastructure.Sql;
using Xunit;

namespace Bazdid.UnitTests
{
    // مسیر فعال‌سازی آزمون متصل (P4) باید در هر شرط ناقص بسته بماند.
    public class ConnectedTestAcceptanceTests
    {
        private static SqlRuntimeOptions Valid() => new SqlRuntimeOptions {
            ConnectionString="Data Source="+SqlRuntimeOptions.ApprovedLocalDataSource+";Initial Catalog=BAZDID_Development;Integrated Security=true;Encrypt=true;TrustServerCertificate=false",
            ApprovedWriterPrincipal=ConnectedTestAcceptance.ExpectedPrincipal
        };
        private static void WithSelection(Action action)
        {
            var previous=Environment.GetEnvironmentVariable(ConnectedTestAcceptance.SelectionVariable);
            Environment.SetEnvironmentVariable(ConnectedTestAcceptance.SelectionVariable,"1");
            try { action(); } finally { Environment.SetEnvironmentVariable(ConnectedTestAcceptance.SelectionVariable,previous); }
        }

        [Theory]
        [InlineData("Production")] [InlineData("Development")] [InlineData("testing")] [InlineData("")]
        public void Only_Testing_environment_can_create_acceptance(string environment)
        { WithSelection(()=>Assert.Throws<InvalidOperationException>(()=>ConnectedTestAcceptance.Create(environment,Valid()))); }

        [Fact]
        public void Acceptance_requires_explicit_selection()
        {
            var previous=Environment.GetEnvironmentVariable(ConnectedTestAcceptance.SelectionVariable);
            Environment.SetEnvironmentVariable(ConnectedTestAcceptance.SelectionVariable,null);
            try { Assert.Throws<InvalidOperationException>(()=>ConnectedTestAcceptance.Create("Testing",Valid())); }
            finally { Environment.SetEnvironmentVariable(ConnectedTestAcceptance.SelectionVariable,previous); }
        }

        [Fact]
        public void Acceptance_rejects_runtime_flag_wrong_principal_target_or_certificate_bypass()
        {
            WithSelection(()=>
            {
                var enabled=Valid(); enabled.Enabled=true;
                Assert.Throws<InvalidOperationException>(()=>ConnectedTestAcceptance.Create("Testing",enabled));
                var principal=Valid(); principal.ApprovedWriterPrincipal=Environment.MachineName+@"\Administrator";
                Assert.Throws<InvalidOperationException>(()=>ConnectedTestAcceptance.Create("Testing",principal));
                var oldTarget=Valid(); oldTarget.ConnectionString=oldTarget.ConnectionString.Replace("lpc:localhost","lpc:.");
                Assert.Throws<InvalidOperationException>(()=>ConnectedTestAcceptance.Create("Testing",oldTarget));
                var bypass=Valid(); bypass.ConnectionString=bypass.ConnectionString.Replace("TrustServerCertificate=false","TrustServerCertificate=true");
                Assert.Throws<InvalidOperationException>(()=>ConnectedTestAcceptance.Create("Testing",bypass));
                var empty=Valid(); empty.ConnectionString="";
                Assert.Throws<InvalidOperationException>(()=>ConnectedTestAcceptance.Create("Testing",empty));
            });
        }

        [Fact]
        public void Acceptance_rejects_token_that_is_not_the_approved_writer()
        {
            // اجرای عادی آزمون‌ها با هویت توسعه‌دهنده است، نه BAZDIDDevWriter.
            if (string.Equals(Environment.UserName,ConnectedTestAcceptance.WriterAccount,StringComparison.OrdinalIgnoreCase)) return;
            WithSelection(()=>Assert.Throws<InvalidOperationException>(()=>ConnectedTestAcceptance.Create("Testing",Valid())));
        }

        [Fact]
        public void Dependency_injection_sees_only_the_gated_public_constructor()
        {
            var constructors=typeof(BazdidWriteConnectionFactory).GetConstructors(BindingFlags.Public|BindingFlags.Instance);
            var only=Assert.Single(constructors);
            Assert.Equal(new[]{typeof(SqlRuntimeOptions)},only.GetParameters().Select(p=>p.ParameterType).ToArray());
            Assert.False(typeof(ConnectedTestAcceptance).IsPublic);
            Assert.False(SqlRuntimeGate.ConnectedAcceptanceVerified);
        }
    }
}
