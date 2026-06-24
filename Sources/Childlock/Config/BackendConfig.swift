import Foundation

public struct BackendConfig: Equatable, Sendable {
    public let supabaseURL: URL?
    public let supabasePublishableKey: String?
    public let googleIOSClientID: String?
    public let googleWebClientID: String?
    public let googleReversedClientID: String?
    public let revenueCatAPIKey: String?
    public let postHogAPIKey: String?
    public let postHogHost: String?

    public static let current = BackendConfig()

    public init(bundle: Bundle = .main, environment: [String: String] = ProcessInfo.processInfo.environment) {
        supabaseURL = Self.urlValue(named: "SUPABASE_URL", bundle: bundle, environment: environment)
        supabasePublishableKey = Self.stringValue(named: "SUPABASE_PUBLISHABLE_KEY", bundle: bundle, environment: environment)
        googleIOSClientID = Self.stringValue(named: "GIDClientID", bundle: bundle, environment: environment)
            ?? Self.stringValue(named: "GOOGLE_IOS_CLIENT_ID", bundle: bundle, environment: environment)
        googleWebClientID = Self.stringValue(named: "GIDServerClientID", bundle: bundle, environment: environment)
            ?? Self.stringValue(named: "GOOGLE_WEB_CLIENT_ID", bundle: bundle, environment: environment)
        googleReversedClientID = Self.stringValue(named: "GOOGLE_REVERSED_CLIENT_ID", bundle: bundle, environment: environment)
        revenueCatAPIKey = Self.stringValue(named: "REVENUECAT_API_KEY", bundle: bundle, environment: environment)
        postHogAPIKey = Self.stringValue(named: "POSTHOG_API_KEY", bundle: bundle, environment: environment)
        postHogHost = Self.stringValue(named: "POSTHOG_HOST", bundle: bundle, environment: environment)
    }

    public var isSupabaseConfigured: Bool {
        supabaseURL != nil && supabasePublishableKey?.isEmpty == false
    }

    public var isGoogleSignInConfigured: Bool {
        guard
            let googleIOSClientID,
            !googleIOSClientID.isEmpty,
            googleWebClientID?.isEmpty == false,
            let googleReversedClientID,
            !googleReversedClientID.isEmpty
        else {
            return false
        }

        return googleReversedClientID == Self.expectedGoogleReversedClientID(for: googleIOSClientID)
    }

    private static func stringValue(
        named name: String,
        bundle: Bundle,
        environment: [String: String]
    ) -> String? {
        let bundleValue = bundle.object(forInfoDictionaryKey: name) as? String
        let value = environment[name] ?? bundleValue
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else {
            return nil
        }

        guard !isPlaceholderValue(trimmed) else {
            return nil
        }

        return trimmed
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

    private static func isPlaceholderValue(_ value: String) -> Bool {
        if value.hasPrefix("$("), value.hasSuffix(")") {
            return true
        }

        let uppercased = value.uppercased()
        return uppercased.contains("YOUR_") || uppercased.contains("_YOUR_")
    }

    private static func expectedGoogleReversedClientID(for iosClientID: String) -> String? {
        let suffix = ".apps.googleusercontent.com"
        guard iosClientID.hasSuffix(suffix) else { return nil }

        let clientPrefix = String(iosClientID.dropLast(suffix.count))
        guard !clientPrefix.isEmpty else { return nil }

        return "com.googleusercontent.apps.\(clientPrefix)"
    }
}
