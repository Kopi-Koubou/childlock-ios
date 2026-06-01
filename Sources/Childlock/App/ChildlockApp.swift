import SwiftUI

#if !SWIFT_PACKAGE
@main
struct ChildlockApp: App {
    init() {
        let config = BackendConfig.current
        if let revenueCatAPIKey = config.revenueCatAPIKey {
            SubscriptionService.shared.configure(apiKey: revenueCatAPIKey)
        }

        if let postHogAPIKey = config.postHogAPIKey {
            AnalyticsService.configure(
                apiKey: postHogAPIKey,
                host: config.postHogHost ?? "https://us.i.posthog.com"
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            ChildlockRootView()
        }
    }
}
#endif
