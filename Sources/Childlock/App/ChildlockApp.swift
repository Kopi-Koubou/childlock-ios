import SwiftUI

#if !SWIFT_PACKAGE
@main
struct ChildlockApp: App {
    init() {
        SubscriptionService.shared.configure(apiKey: "test_NZImEiymFuHlDElZwpwoDGuipuU")
        AnalyticsService.configure(
            apiKey: "phc_zdyrzhuT46PWgpshfsfy4DibaTftEhdGTcpjmC6KDu5n"
        )
    }

    var body: some Scene {
        WindowGroup {
            ChildlockRootView()
        }
    }
}
#endif
