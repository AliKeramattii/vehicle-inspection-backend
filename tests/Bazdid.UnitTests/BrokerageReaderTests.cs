using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api.Application;
using Bazdid.Api.Domain.Brokerage;
using Bazdid.Api.Infrastructure.Brokerage;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.FileProviders;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Bazdid.UnitTests
{
    public class BrokerageReaderTests
    {
        private static BrokerageScope Scope => new BrokerageScope("TEST-BROKERAGE", "SYNTHETIC");
        private static readonly DateTimeOffset Now = new DateTimeOffset(2026, 11, 2, 10, 0, 0, TimeSpan.Zero);
        private static SyntheticBrokerageRequestReader Reader(string environment = "Testing") =>
            new SyntheticBrokerageRequestReader(new TestEnvironment { EnvironmentName = environment }, new FixedClock());
        private static BrokerageRequestReference Ref(string id) => new BrokerageRequestReference(Scope, id);
        private static async Task<BrokerageRequestSnapshot> Snapshot(string id) =>
            (await Reader().GetRequestSnapshotAsync(Ref(id), CancellationToken.None)).Value;

        [Theory]
        [InlineData("A4K9P2", BrokerageReadStatus.Found)]
        [InlineData("UNKNOWN", BrokerageReadStatus.NotFound)]
        [InlineData("AMB001", BrokerageReadStatus.Ambiguous)]
        [InlineData("INEL01", BrokerageReadStatus.Ineligible)]
        [InlineData("DOWN01", BrokerageReadStatus.Unavailable)]
        public async Task Referral_outcomes_are_distinct_and_failures_have_no_payload(string code, BrokerageReadStatus expected)
        {
            var result = await Reader().ResolveReferralAsync(Scope, code, CancellationToken.None);
            Assert.Equal(expected, result.Status);
            if (expected == BrokerageReadStatus.Found) Assert.Equal("TEST-REQUEST-001", result.Value.SourceRequestId);
            else Assert.Null(result.Value);
        }

        [Fact]
        public async Task Resolution_does_not_include_mobile_customer_or_vehicle_data()
        {
            var result = await Reader().ResolveReferralAsync(Scope, "A4K9P2", CancellationToken.None);
            var json = JsonConvert.SerializeObject(result);
            Assert.DoesNotContain("09000000001", json);
            Assert.DoesNotContain("TEST-CUSTOMER-001", json);
            Assert.DoesNotContain("SYNTHETIC-VIN-001", json);
        }

        [Fact]
        public async Task Full_snapshot_has_trusted_immutable_fields_and_separate_source_and_retrieval_versions()
        {
            var snapshot = await Snapshot("TEST-REQUEST-001");
            Assert.Equal("TEST-CUSTOMER-001", snapshot.SourceCustomerId);
            Assert.Equal("09000000001", snapshot.TrustedMobile.Value);
            Assert.True(snapshot.TrustedMobile.IsReadOnly);
            Assert.Equal(RequestEligibility.Eligible, snapshot.Eligibility);
            Assert.Equal("synthetic-v1", snapshot.SourceVersion);
            Assert.Equal(Now, snapshot.RetrievedAtUtc);
            var v = snapshot.Vehicle;
            foreach (var field in new[] { v.Manufacturer, v.Model, v.ModelYear, v.Color, v.LicensePlate, v.Vin, v.ChassisNumber })
            {
                Assert.Equal(BrokerageFieldStatus.Present, field.Status);
                Assert.Equal(BrokerageFieldSource.Brokerage, field.Source);
                Assert.True(field.IsReadOnly);
                Assert.Equal(FieldValidationStatus.Valid, field.Validation.Status);
                Assert.NotEmpty(field.Validation.PolicyId);
            }
            Assert.NotEqual(v.Vin.Value, v.ChassisNumber.Value);
        }

        [Theory]
        [InlineData("ModelYear")]
        [InlineData("Color")]
        [InlineData("Vin")]
        public async Task Explicit_missing_is_null_and_only_approved_vehicle_fields_allow_manual_entry(string name)
        {
            var snapshot = await Snapshot("TEST-MISSING");
            var field = (BrokerageField)typeof(BrokerageVehicleSnapshot).GetProperty(name).GetValue(snapshot.Vehicle);
            Assert.Null(field.Value);
            Assert.Equal(BrokerageFieldStatus.Missing, field.Status);
            Assert.False(field.IsReadOnly);
            Assert.Equal(FieldValidationStatus.NotApplicable, field.Validation.Status);
            Assert.True(snapshot.TrustedMobile.IsReadOnly);
            Assert.True(snapshot.Vehicle.Manufacturer.IsReadOnly);
        }

        [Theory]
        [InlineData("ModelYear")]
        [InlineData("Vin")]
        public async Task Invalid_source_is_preserved_and_never_becomes_manual_missing(string name)
        {
            var snapshot = await Snapshot("TEST-INVALID");
            var field = (BrokerageField)typeof(BrokerageVehicleSnapshot).GetProperty(name).GetValue(snapshot.Vehicle);
            Assert.Equal("invalid", field.Value);
            Assert.Equal(BrokerageFieldStatus.Invalid, field.Status);
            Assert.True(field.IsReadOnly);
            Assert.Equal(FieldValidationStatus.Invalid, field.Validation.Status);
        }

        [Fact]
        public async Task Zero_policy_is_field_specific_and_does_not_erase_a_valid_zero_label()
        {
            var snapshot = await Snapshot("TEST-ZERO");
            Assert.Null(snapshot.Vehicle.ModelYear.Value);
            Assert.Equal(BrokerageFieldStatus.Missing, snapshot.Vehicle.ModelYear.Status);
            Assert.Equal("0", snapshot.Vehicle.Color.Value);
            Assert.Equal(BrokerageFieldStatus.Present, snapshot.Vehicle.Color.Status);
            Assert.True(snapshot.Vehicle.Color.IsReadOnly);
            Assert.NotEqual(snapshot.Vehicle.ModelYear.Validation.PolicyId, snapshot.Vehicle.Color.Validation.PolicyId);
        }

        [Fact]
        public void Missing_without_manual_policy_and_unavailable_remain_read_only()
        {
            Assert.True(BrokerageField.Missing("test-no-manual-v1", false).IsReadOnly);
            var field = BrokerageField.Unavailable("test-unavailable-v1");
            Assert.Null(field.Value);
            Assert.True(field.IsReadOnly);
            Assert.Equal(BrokerageFieldStatus.Unavailable, field.Status);
            Assert.Equal(FieldValidationStatus.NotEvaluated, field.Validation.Status);
        }

        [Theory]
        [InlineData("MOB001", "TEST-MOBILE-CONFLICT", BrokerageFailureReason.TrustedMobileConflict)]
        [InlineData("MOB002", "TEST-MOBILE-MISSING", BrokerageFailureReason.TrustedMobileMissing)]
        [InlineData("MOB003", "TEST-MOBILE-INVALID", BrokerageFailureReason.TrustedMobileInvalid)]
        [InlineData("CUST00", "TEST-NO-CUSTOMER", BrokerageFailureReason.InvalidSourceIdentity)]
        [InlineData("ELIG00", "TEST-UNKNOWN-ELIGIBILITY", BrokerageFailureReason.EligibilityUnknown)]
        public async Task Untrusted_identity_candidates_fail_closed_without_selecting_a_mobile(
            string code, string request, BrokerageFailureReason reason)
        {
            var reader = Reader();
            var resolution = await reader.ResolveReferralAsync(Scope, code, CancellationToken.None);
            var snapshot = await reader.GetRequestSnapshotAsync(Ref(request), CancellationToken.None);
            Assert.Equal(BrokerageReadStatus.Unavailable, resolution.Status);
            Assert.Equal(reason, resolution.Reason);
            Assert.Null(resolution.Value);
            Assert.Equal(BrokerageReadStatus.Unavailable, snapshot.Status);
            Assert.Equal(reason, snapshot.Reason);
            Assert.Null(snapshot.Value);
        }

        [Theory]
        [InlineData("NOT-PRESENT", BrokerageReadStatus.NotFound)]
        [InlineData("TEST-INELIGIBLE", BrokerageReadStatus.Ineligible)]
        [InlineData("TEST-UNAVAILABLE", BrokerageReadStatus.Unavailable)]
        public async Task Snapshot_failures_have_no_customer_payload(string id, BrokerageReadStatus status)
        {
            var result = await Reader().GetRequestSnapshotAsync(Ref(id), CancellationToken.None);
            Assert.Equal(status, result.Status);
            Assert.Null(result.Value);
        }

        [Fact]
        public async Task A_customer_can_have_two_independently_resolved_requests()
        {
            var reader = Reader();
            var first = await reader.ResolveReferralAsync(Scope, "A4K9P2", CancellationToken.None);
            var second = await reader.ResolveReferralAsync(Scope, "SECOND", CancellationToken.None);
            Assert.NotEqual(first.Value, second.Value);
            var a = await reader.GetRequestSnapshotAsync(first.Value, CancellationToken.None);
            var b = await reader.GetRequestSnapshotAsync(second.Value, CancellationToken.None);
            Assert.Equal(a.Value.SourceCustomerId, b.Value.SourceCustomerId);
            Assert.NotEqual(a.Value.Reference.SourceRequestId, b.Value.Reference.SourceRequestId);
        }

        [Fact]
        public async Task Large_external_identifiers_survive_json_as_exact_strings()
        {
            var result = await Reader().ResolveReferralAsync(Scope, "BIG001", CancellationToken.None);
            var snapshot = (await Reader().GetRequestSnapshotAsync(result.Value, CancellationToken.None)).Value;
            var json = JObject.Parse(JsonConvert.SerializeObject(snapshot));
            Assert.Equal(JTokenType.String, json["Reference"]["SourceRequestId"].Type);
            Assert.Equal("9223372036854775807", (string)json["Reference"]["SourceRequestId"]);
            Assert.Equal(JTokenType.String, json["SourceCustomerId"].Type);
            Assert.Equal("9007199254740993", (string)json["SourceCustomerId"]);
        }

        [Fact]
        public async Task Opaque_identifiers_preserve_unicode_case_and_trailing_space()
        {
            var resolved = await Reader().ResolveReferralAsync(Scope, "OPAQUE", CancellationToken.None);
            Assert.Equal("Opaque-درخواست ", resolved.Value.SourceRequestId);
            Assert.Equal(BrokerageReadStatus.Found, (await Reader().GetRequestSnapshotAsync(resolved.Value, CancellationToken.None)).Status);
            Assert.Equal(BrokerageReadStatus.NotFound, (await Reader().GetRequestSnapshotAsync(Ref("Opaque-درخواست"), CancellationToken.None)).Status);
            Assert.Equal(BrokerageReadStatus.NotFound, (await Reader().GetRequestSnapshotAsync(Ref("opaque-درخواست "), CancellationToken.None)).Status);
        }

        [Theory]
        [InlineData("TEST-BROKERAGE", "SYNTHETIC", "TEST-REQUEST-001")]
        [InlineData("OTHER-BROKERAGE", "SYNTHETIC", "OTHER-REQUEST")]
        [InlineData("TEST-BROKERAGE", "OTHER-SYNTHETIC", "OTHER-SOURCE-REQUEST")]
        public async Task Same_referral_is_resolved_only_inside_its_exact_scope(string brokerage, string source, string id)
        {
            var scope = new BrokerageScope(brokerage, source);
            var result = await Reader().ResolveReferralAsync(scope, "A4K9P2", CancellationToken.None);
            Assert.Equal(id, result.Value.SourceRequestId);
            Assert.Equal(scope, result.Value.Scope);
        }

        [Theory]
        [InlineData("test-brokerage", "SYNTHETIC")]
        [InlineData("TEST-BROKERAGE", "synthetic")]
        [InlineData("UNKNOWN", "SYNTHETIC")]
        public async Task Unknown_or_differently_cased_scope_cannot_resolve_or_read_another_request(string brokerage, string source)
        {
            var scope = new BrokerageScope(brokerage, source);
            Assert.Equal(BrokerageReadStatus.NotFound, (await Reader().ResolveReferralAsync(scope, "A4K9P2", CancellationToken.None)).Status);
            Assert.Equal(BrokerageReadStatus.NotFound, (await Reader().GetRequestSnapshotAsync(new BrokerageRequestReference(scope, "TEST-REQUEST-001"), CancellationToken.None)).Status);
        }

        [Theory]
        [InlineData("a4k9p2")]
        [InlineData(" A4K9P2")]
        [InlineData("A4K9P2 ")]
        public async Task No_unapproved_referral_normalization_is_applied(string referral)
        { Assert.Equal(BrokerageReadStatus.NotFound, (await Reader().ResolveReferralAsync(Scope, referral, CancellationToken.None)).Status); }

        [Theory]
        [InlineData(false)]
        [InlineData(true)]
        public async Task Both_reader_boundaries_honor_cancellation(bool sql)
        {
            IBrokerageRequestReader reader = sql ? (IBrokerageRequestReader)new SqlBrokerageRequestReader() : Reader();
            var token = new CancellationToken(true);
            await Assert.ThrowsAnyAsync<OperationCanceledException>(() => reader.ResolveReferralAsync(Scope, "A4K9P2", token));
            await Assert.ThrowsAnyAsync<OperationCanceledException>(() => reader.GetRequestSnapshotAsync(Ref("TEST-REQUEST-001"), token));
        }

        [Theory]
        [InlineData("Production")]
        [InlineData("Staging")]
        [InlineData("development")]
        public void Synthetic_constructor_itself_rejects_other_environments(string environment)
        { Assert.Throws<InvalidOperationException>(() => Reader(environment)); }

        [Fact]
        public async Task Sql_boundary_never_substitutes_the_known_synthetic_fixture()
        {
            var reader = new SqlBrokerageRequestReader();
            var a = await reader.ResolveReferralAsync(Scope, "A4K9P2", CancellationToken.None);
            var b = await reader.GetRequestSnapshotAsync(Ref("TEST-REQUEST-001"), CancellationToken.None);
            Assert.Equal(BrokerageFailureReason.SourceNotConfigured, a.Reason);
            Assert.Equal(BrokerageReadStatus.Unavailable, a.Status);
            Assert.Equal(BrokerageFailureReason.SourceNotConfigured, b.Reason);
            Assert.Null(a.Value); Assert.Null(b.Value);
        }

        [Theory]
        [InlineData(false)]
        [InlineData(true)]
        public async Task Source_timeout_or_source_cancellation_is_unavailable_never_notfound(bool timeout)
        {
            var fake = new FakeReader { Resolve = (scope, code, token) =>
                throw (timeout ? (Exception)new TimeoutException("sensitive-source-message") : new OperationCanceledException("sensitive-source-message")) };
            var result = await new BrokerageRequestService(fake, Scope).ResolveReferralAsync("A4K9P2", CancellationToken.None);
            Assert.Equal(BrokerageReadStatus.Unavailable, result.Status);
            Assert.Equal(BrokerageFailureReason.SourceUnavailable, result.Reason);
            Assert.DoesNotContain("sensitive-source-message", JsonConvert.SerializeObject(result));
        }

        [Fact]
        public async Task Caller_cancellation_is_propagated_even_if_an_adapter_ignores_it()
        {
            using (var cancellation = new CancellationTokenSource())
            {
                var fake = new FakeReader { Resolve = (scope, code, token) =>
                { cancellation.Cancel(); return Task.FromResult(BrokerageReadResult<BrokerageRequestReference>.Found(Ref("TEST-REQUEST-001"))); } };
                await Assert.ThrowsAnyAsync<OperationCanceledException>(() => new BrokerageRequestService(fake, Scope).ResolveReferralAsync("A4K9P2", cancellation.Token));
            }
        }

        [Theory]
        [InlineData(false)]
        [InlineData(true)]
        public async Task Snapshot_source_timeout_or_source_cancellation_cannot_return_missing_fields(bool timeout)
        {
            var fake = new FakeReader { Snapshot = (request, token) =>
                throw (timeout ? (Exception)new TimeoutException("private-source-error") : new OperationCanceledException("private-source-error")) };
            var result = await new BrokerageRequestService(fake, Scope).GetRequestSnapshotAsync(Ref("TEST-REQUEST-001"), CancellationToken.None);
            Assert.Equal(BrokerageReadStatus.Unavailable, result.Status);
            Assert.Equal(BrokerageFailureReason.SourceUnavailable, result.Reason);
            Assert.Null(result.Value);
        }

        [Fact]
        public async Task Caller_cancellation_precedes_unconfigured_service_outcomes()
        {
            var service = new BrokerageRequestService(new FakeReader(), null);
            var token = new CancellationToken(true);
            await Assert.ThrowsAnyAsync<OperationCanceledException>(() => service.ResolveReferralAsync("A4K9P2", token));
            await Assert.ThrowsAnyAsync<OperationCanceledException>(() => service.GetRequestSnapshotAsync(Ref("TEST-REQUEST-001"), token));
        }

        [Fact]
        public async Task Wrong_scope_is_rejected_before_calling_the_adapter()
        {
            var fake = new FakeReader();
            var request = new BrokerageRequestReference(new BrokerageScope("OTHER-BROKERAGE", "SYNTHETIC"), "TEST-REQUEST-001");
            var result = await new BrokerageRequestService(fake, Scope).GetRequestSnapshotAsync(request, CancellationToken.None);
            Assert.Equal(BrokerageReadStatus.NotFound, result.Status);
            Assert.Equal(0, fake.SnapshotCalls);
        }

        [Fact]
        public async Task Unexpected_adapter_identity_is_not_released_to_the_consumer()
        {
            var fake = new FakeReader { Resolve = (scope, code, token) => Task.FromResult(
                BrokerageReadResult<BrokerageRequestReference>.Found(new BrokerageRequestReference(new BrokerageScope("OTHER", "SOURCE"), "opaque"))) };
            var service = new BrokerageRequestService(fake, Scope);
            Assert.Equal(BrokerageFailureReason.InvalidSourceIdentity, (await service.ResolveReferralAsync("A4K9P2", CancellationToken.None)).Reason);
            var wrong = await Snapshot("TEST-REQUEST-002");
            fake.Snapshot = (request, token) => Task.FromResult(BrokerageReadResult<BrokerageRequestSnapshot>.Found(wrong));
            Assert.Equal(BrokerageFailureReason.InvalidSourceIdentity, (await service.GetRequestSnapshotAsync(Ref("TEST-REQUEST-001"), CancellationToken.None)).Reason);
        }

        [Fact]
        public async Task Unconfigured_service_fails_closed_and_does_not_invoke_adapter()
        {
            var fake = new FakeReader();
            var service = new BrokerageRequestService(fake, null);
            Assert.Equal(BrokerageFailureReason.SourceNotConfigured, (await service.ResolveReferralAsync("A4K9P2", CancellationToken.None)).Reason);
            Assert.Equal(BrokerageFailureReason.SourceNotConfigured, (await service.GetRequestSnapshotAsync(Ref("TEST-REQUEST-001"), CancellationToken.None)).Reason);
            Assert.Equal(0, fake.SnapshotCalls);
        }

        [Fact]
        public async Task Programming_errors_are_not_hidden_as_missing_data()
        {
            var fake = new FakeReader { Resolve = (scope, code, token) => throw new InvalidOperationException("test-error") };
            await Assert.ThrowsAsync<InvalidOperationException>(() => new BrokerageRequestService(fake, Scope).ResolveReferralAsync("A4K9P2", CancellationToken.None));
        }

        private sealed class FixedClock : IClock { public DateTimeOffset UtcNow => Now; }
        private sealed class TestEnvironment : IHostingEnvironment
        {
            public string EnvironmentName { get; set; }
            public string ApplicationName { get; set; }
            public string WebRootPath { get; set; }
            public IFileProvider WebRootFileProvider { get; set; }
            public string ContentRootPath { get; set; }
            public IFileProvider ContentRootFileProvider { get; set; }
        }
        private sealed class FakeReader : IBrokerageRequestReader
        {
            public int SnapshotCalls { get; private set; }
            public Func<BrokerageScope, string, CancellationToken, Task<BrokerageReadResult<BrokerageRequestReference>>> Resolve { get; set; }
            public Func<BrokerageRequestReference, CancellationToken, Task<BrokerageReadResult<BrokerageRequestSnapshot>>> Snapshot { get; set; }
            public Task<BrokerageReadResult<BrokerageRequestReference>> ResolveReferralAsync(BrokerageScope scope, string code, CancellationToken token) => Resolve(scope, code, token);
            public Task<BrokerageReadResult<BrokerageRequestSnapshot>> GetRequestSnapshotAsync(BrokerageRequestReference request, CancellationToken token)
            { SnapshotCalls++; return Snapshot(request, token); }
        }
    }
}
