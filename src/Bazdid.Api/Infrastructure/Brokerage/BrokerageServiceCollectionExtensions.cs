using System;
using Bazdid.Api.Application;
using Bazdid.Api.Configuration;
using Bazdid.Api.Domain.Brokerage;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;

namespace Bazdid.Api.Infrastructure.Brokerage
{
    public static class BrokerageServiceCollectionExtensions
    {
        public static IServiceCollection AddBrokerageReader(this IServiceCollection services,
            FoundationOptions settings, IHostingEnvironment environment)
        {
            if (settings == null || environment == null) throw new ArgumentNullException();
            settings.Validate(environment.EnvironmentName);
            if (settings.BrokerageAdapterMode == "Synthetic")
                services.AddSingleton<IBrokerageRequestReader, SyntheticBrokerageRequestReader>();
            else services.AddSingleton<IBrokerageRequestReader, SqlBrokerageRequestReader>();
            services.AddSingleton<IClock>(new SystemClock());
            var scope = string.IsNullOrEmpty(settings.BrokerageId) ? null :
                new BrokerageScope(settings.BrokerageId, settings.BrokerageSourceSystem);
            services.AddSingleton(provider => new BrokerageRequestService(provider.GetRequiredService<IBrokerageRequestReader>(), scope));
            return services;
        }
        private sealed class SystemClock : IClock { public DateTimeOffset UtcNow => DateTimeOffset.UtcNow; }
    }
}
