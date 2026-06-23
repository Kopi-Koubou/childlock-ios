import XCTest
@testable import Childlock

final class BackendConfigTests: XCTestCase {
    func testIgnoresUnresolvedBuildSettingPlaceholders() {
        let config = BackendConfig(environment: [
            "SUPABASE_URL": "$(SUPABASE_URL)",
            "SUPABASE_PUBLISHABLE_KEY": "$(SUPABASE_PUBLISHABLE_KEY)",
            "REVENUECAT_API_KEY": "$(REVENUECAT_API_KEY)",
            "POSTHOG_API_KEY": "$(POSTHOG_API_KEY)",
            "POSTHOG_HOST": "$(POSTHOG_HOST)",
        ])

        XCTAssertNil(config.supabaseURL)
        XCTAssertNil(config.supabasePublishableKey)
        XCTAssertNil(config.revenueCatAPIKey)
        XCTAssertNil(config.postHogAPIKey)
        XCTAssertNil(config.postHogHost)
        XCTAssertFalse(config.isSupabaseConfigured)
    }

    func testIgnoresCopiedExamplePlaceholders() {
        let config = BackendConfig(environment: [
            "SUPABASE_URL": "https://jkncpveupvozsmbbkvgq.supabase.co",
            "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_YOUR_PUBLIC_KEY",
            "REVENUECAT_API_KEY": "appl_YOUR_REVENUECAT_IOS_SDK_KEY",
            "POSTHOG_API_KEY": "phc_YOUR_POSTHOG_PROJECT_API_KEY",
        ])

        XCTAssertEqual(config.supabaseURL?.absoluteString, "https://jkncpveupvozsmbbkvgq.supabase.co")
        XCTAssertNil(config.supabasePublishableKey)
        XCTAssertNil(config.revenueCatAPIKey)
        XCTAssertNil(config.postHogAPIKey)
        XCTAssertFalse(config.isSupabaseConfigured)
    }

    func testAcceptsProductionAppFacingValues() {
        let config = BackendConfig(environment: [
            "SUPABASE_URL": "https://jkncpveupvozsmbbkvgq.supabase.co",
            "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_live_public_key",
            "REVENUECAT_API_KEY": "appl_live_public_key",
            "POSTHOG_API_KEY": "phc_live_public_key",
            "POSTHOG_HOST": "https://us.i.posthog.com",
        ])

        XCTAssertEqual(config.supabaseURL?.absoluteString, "https://jkncpveupvozsmbbkvgq.supabase.co")
        XCTAssertEqual(config.supabasePublishableKey, "sb_publishable_live_public_key")
        XCTAssertEqual(config.revenueCatAPIKey, "appl_live_public_key")
        XCTAssertEqual(config.postHogAPIKey, "phc_live_public_key")
        XCTAssertEqual(config.postHogHost, "https://us.i.posthog.com")
        XCTAssertTrue(config.isSupabaseConfigured)
    }
}
