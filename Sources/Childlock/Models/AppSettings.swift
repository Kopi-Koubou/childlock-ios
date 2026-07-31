import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public var hasCompletedOnboarding: Bool
    public var voicePromptsEnabled: Bool
    public var dailySummaryNotification: Bool
    public var challengeAlertNotification: Bool
    public var freeChallengesUsedToday: Int
    public var freeChallengesResetDate: String
    public var localOwnerUserID: String?
    public var rapidTestIntervalSeconds: Int?

    public init(
        hasCompletedOnboarding: Bool = false,
        voicePromptsEnabled: Bool = true,
        dailySummaryNotification: Bool = true,
        challengeAlertNotification: Bool = true,
        freeChallengesUsedToday: Int = 0,
        freeChallengesResetDate: String = "",
        localOwnerUserID: String? = nil,
        rapidTestIntervalSeconds: Int? = nil
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.voicePromptsEnabled = voicePromptsEnabled
        self.dailySummaryNotification = dailySummaryNotification
        self.challengeAlertNotification = challengeAlertNotification
        self.freeChallengesUsedToday = freeChallengesUsedToday
        self.freeChallengesResetDate = freeChallengesResetDate
        self.localOwnerUserID = localOwnerUserID
        self.rapidTestIntervalSeconds = rapidTestIntervalSeconds
    }

    public static let `default` = AppSettings()
}
