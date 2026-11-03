using Bazdid.Api.Application;
using Bazdid.Api.Domain.Persistence;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Bazdid.Api.Infrastructure.Sql
{
    public static class SqlRegistration
    {
        public static IServiceCollection AddBazdidPersistence(this IServiceCollection services, IConfiguration configuration, string environment)
        {
            var options=new SqlRuntimeOptions();
            configuration.GetSection("SqlRuntime").Bind(options);
            options.ConnectionString=configuration.GetConnectionString("Bazdid") ?? "";
            options.Validate(environment);
            services.AddSingleton(options);
            services.AddSingleton<IBazdidWriteConnectionFactory,BazdidWriteConnectionFactory>();
            services.AddSingleton<ISourceReadConnectionFactory,UnconfiguredSourceReadConnectionFactory>();
            services.AddSingleton<IBazdidTransactionFactory,SqlTransactionFactory>();
            services.AddSingleton<ICustomerLinkRepository,SqlCustomerLinkRepository>();
            services.AddSingleton<IRequestContextRepository,SqlRequestContextRepository>();
            services.AddSingleton<IAuditRepository,SqlAuditRepository>();
            services.AddTransient<LinkagePersistenceService>();
            return services;
        }
    }
}
