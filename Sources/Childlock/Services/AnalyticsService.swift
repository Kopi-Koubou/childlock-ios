import Foundation
#if canImport(PostHog)
import PostHog
#endif

@MainActor
public enum AnalyticsService {
    private static var isConfigured = false

    public static func configure(apiKey: String, host: String = "https://us.i.posthog.com") {
        #if canImport(PostHog)
        let config = PostHogConfig(projectToken: apiKey, host: host)
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = true
        PostHogSDK.shared.setup(config)
        isConfigured = true
        #endif
    }

    public static func identify(userID: String) {
        #if canImport(PostHog)
        guard isConfigured else { return }
        PostHogSDK.shared.identify(userID)
        #endif
    }

    public static func reset() {
        #if canImport(PostHog)
        guard isConfigured else { return }
        PostHogSDK.shared.reset()
        #endif
    }

    // MARK: - Events

    public static func trackOnboardingStep(_ step: String) {
        capture("onboarding_step", properties: ["step": step])
    }

    public static func trackOnboardingComplete() {
        capture("onboarding_complete")
    }

    public static func trackChallengePresented(type: String, ageBand: String, difficulty: Int) {
        capture("challenge_presented", properties: [
            "type": type,
            "age_band": ageBand,
            "difficulty": String(difficulty),
        ])
    }

    public static func trackChallengeCompleted(type: String, ageBand: String, attempts: Int, solveTimeSeconds: Double) {
        capture("challenge_completed", properties: [
            "type": type,
            "age_band": ageBand,
            "attempts": String(attempts),
            "solve_time_seconds": String(Int(solveTimeSeconds)),
        ])
    }

    public static func trackChallengeFailed(type: String, ageBand: String, attempts: Int) {
        capture("challenge_failed", properties: [
            "type": type,
            "age_band": ageBand,
            "attempts": String(attempts),
        ])
    }

    public static func trackHintUsed(type: String) {
        capture("hint_used", properties: ["type": type])
    }

    public static func trackSubscriptionViewed() {
        capture("paywall_viewed")
    }

    public static func trackSubscriptionStarted(plan: String) {
        capture("subscription_started", properties: ["plan": plan])
    }

    public static func trackChildAdded(age: Int) {
        capture("child_added", properties: ["age": String(age)])
    }

    private static func capture(_ event: String, properties: [String: String]? = nil) {
        #if canImport(PostHog)
        guard isConfigured else { return }
        PostHogSDK.shared.capture(event, properties: properties)
        #endif
    }
}
