import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var hasCompletedOnboarding: Bool
    public var voicePromptsEnabled: Bool
    public var dailySummaryNotification: Bool
    public var challengeAlertNotification: Bool
    public var freeChallengesUsedToday: Int
    public var freeChallengesResetDate: String

    public init(
        hasCompletedOnboarding: Bool = false,
        voicePromptsEnabled: Bool = true,
        dailySummaryNotification: Bool = true,
        challengeAlertNotification: Bool = true,
        freeChallengesUsedToday: Int = 0,
        freeChallengesResetDate: String = ""
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.voicePromptsEnabled = voicePromptsEnabled
        self.dailySummaryNotification = dailySummaryNotification
        self.challengeAlertNotification = challengeAlertNotification
        self.freeChallengesUsedToday = freeChallengesUsedToday
        self.freeChallengesResetDate = freeChallengesResetDate
    }

    public static let `default` = AppSettings()
}
