import Foundation

public struct BackendConfig: Equatable, Sendable {
    public let supabaseURL: URL?
    public let supabasePublishableKey: String?
    public let revenueCatAPIKey: String?
    public let postHogAPIKey: String?
    public let postHogHost: String?

    public static let current = BackendConfig()

    public init(bundle: Bundle = .main, environment: [String: String] = ProcessInfo.processInfo.environment) {
        supabaseURL = Self.urlValue(named: "SUPABASE_URL", bundle: bundle, environment: environment)
        supabasePublishableKey = Self.stringValue(named: "SUPABASE_PUBLISHABLE_KEY", bundle: bundle, environment: environment)
        revenueCatAPIKey = Self.stringValue(named: "REVENUECAT_API_KEY", bundle: bundle, environment: environment)
        postHogAPIKey = Self.stringValue(named: "POSTHOG_API_KEY", bundle: bundle, environment: environment)
        postHogHost = Self.stringValue(named: "POSTHOG_HOST", bundle: bundle, environment: environment)
    }

    public var isSupabaseConfigured: Bool {
        supabaseURL != nil && supabasePublishableKey?.isEmpty == false
    }

    private static func stringValue(
        named name: String,
        bundle: Bundle,
        environment: [String: String]
    ) -> String? {
        let bundleValue = bundle.object(forInfoDictionaryKey: name) as? String
        let value = environment[name] ?? bundleValue
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }

    private static func urlValue(
        named name: String,
        bundle: Bundle,
        environment: [String: String]
    ) -> URL? {
        guard let value = stringValue(named: name, bundle: bundle, environment: environment) else {
            return nil
        }

        return URL(string: value)
    }
}
