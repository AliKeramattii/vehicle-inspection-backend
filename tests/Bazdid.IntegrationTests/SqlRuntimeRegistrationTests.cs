using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Bazdid.Api;
using Bazdid.Api.Application;
using Bazdid.Api.Domain.Persistence;
using Bazdid.Api.Infrastructure.Sql;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Bazdid.IntegrationTests
{
    public class SqlRuntimeRegistrationTests
    {
        private static TestServer Server(string environment, IDictionary<string,string> settings=null)
        {
            var root=new DirectoryInfo(AppContext.BaseDirectory);
            while (root!=null && !File.Exists(Path.Combine(root.FullName,"Bazdid.sln"))) root=root.Parent;
            return new TestServer(Program.CreateWebHostBuilder(new string[0]).UseContentRoot(Path.Combine(root.FullName,"src","Bazdid.Api"))
                .UseEnvironment(environment).ConfigureAppConfiguration((c,b)=>b.AddInMemoryCollection(settings??new Dictionary<string,string>())));
        }
        [Theory]
        [InlineData("Development")] [InlineData("Testing")] [InlineData("Production")]
        public async Task Actual_host_DI_is_closed_and_resolves_repositories_without_database_access(string environment)
        {
            using (var server=Server(environment))
            {
                var services=server.Host.Services;
                Assert.IsType<SqlCustomerLinkRepository>(services.GetRequiredService<ICustomerLinkRepository>());
                Assert.IsType<SqlRequestContextRepository>(services.GetRequiredService<IRequestContextRepository>());
                Assert.IsType<SqlAuditRepository>(services.GetRequiredService<IAuditRepository>());
                Assert.NotNull(services.GetRequiredService<LinkagePersistenceService>());
                Assert.False(services.GetRequiredService<SqlRuntimeOptions>().Enabled);
                var error=await Assert.ThrowsAsync<PersistenceException>(()=>services.GetRequiredService<IBazdidTransactionFactory>().BeginAsync(CancellationToken.None));
                Assert.Equal(PersistenceFailure.Blocked,error.Failure);
            }
        }
        [Theory]
        [InlineData("Development")] [InlineData("Testing")] [InlineData("Production")]
        public void Startup_rejects_attempt_to_enable_unaccepted_SQL_runtime(string environment)
        { Assert.ThrowsAny<Exception>(()=>Server(environment,new Dictionary<string,string>{{"SqlRuntime:Enabled","true"}})); }
        [Fact]
        public void Production_rejects_local_connection_even_while_disabled()
        { Assert.ThrowsAny<Exception>(()=>Server("Production",new Dictionary<string,string>{{"ConnectionStrings:Bazdid",@"Data Source=lpc:.\SQLSERVER2019;Initial Catalog=BAZDID_Development;Integrated Security=true;Encrypt=true"}})); }
    }
}
