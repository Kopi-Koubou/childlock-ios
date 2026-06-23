import Foundation
#if canImport(Supabase)
@preconcurrency import Supabase
#endif

public enum DataSyncError: LocalizedError {
    case supabaseNotConfigured
    case noAuthenticatedUser

    public var errorDescription: String? {
        switch self {
        case .supabaseNotConfigured:
            return "Supabase is not configured."
        case .noAuthenticatedUser:
            return "No authenticated Supabase user is available."
        }
    }
}

@MainActor
public final class DataSyncService {
    public static let shared = DataSyncService()

    private let isoFormatter: ISO8601DateFormatter
    private let dayFormatter: DateFormatter

    public init() {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.isoFormatter = isoFormatter

        let dayFormatter = DateFormatter()
        dayFormatter.calendar = Calendar(identifier: .gregorian)
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dayFormatter.dateFormat = "yyyy-MM-dd"
        self.dayFormatter = dayFormatter
    }

    public var isConfigured: Bool {
        #if canImport(Supabase)
        SupabaseClientProvider.shared != nil
        #else
        false
        #endif
    }

    public func syncParentProfile(
        appleUserID: String?,
        email: String?,
        fullName: PersonNameComponents?
    ) async throws {
        try await syncParentProfile(
            appleUserID: appleUserID,
            email: email,
            fullName: fullName.map(Self.displayName(from:))
        )
    }

    public func syncParentProfile(
        appleUserID: String?,
        email: String?,
        fullName: String?
    ) async throws {
        #if canImport(Supabase)
        let client = try configuredClient()
        let user = try await currentUser(client: client)

        try await client
            .from("parent_profiles")
            .upsert(
                ParentProfileRow(
                    id: user.id,
                    appleUserID: appleUserID,
                    email: email,
                    fullName: fullName,
                    revenueCatAppUserID: user.id.uuidString
                ),
                onConflict: "id"
            )
            .execute()
        #else
        throw DataSyncError.supabaseNotConfigured
        #endif
    }

    public func sync(appState: AppState) async throws {
        let snapshot = appState.snapshot()
        let syncedIDs = try await sync(snapshot: snapshot)
        appState.markSessionsSynced(ids: syncedIDs)
    }

    @discardableResult
    public func sync(snapshot: AppStateSnapshot) async throws -> Set<UUID> {
        #if canImport(Supabase)
        let client = try configuredClient()
        let user = try await currentUser(client: client)
        let parentID = user.id

        try await upsertSettings(snapshot.settings, activeProfileID: snapshot.activeProfileID, parentID: parentID, client: client)
        try await upsertProfiles(snapshot.profiles, parentID: parentID, client: client)

        let unsyncedSessions = snapshot.sessions.filter { !$0.synced }
        guard !unsyncedSessions.isEmpty else {
            return []
        }

        try await upsertSessions(unsyncedSessions, parentID: parentID, client: client)
        try await upsertResults(unsyncedSessions, parentID: parentID, client: client)
        return Set(unsyncedSessions.map(\.id))
        #else
        throw DataSyncError.supabaseNotConfigured
        #endif
    }

    #if canImport(Supabase)
    private func configuredClient() throws -> SupabaseClient {
        guard let client = SupabaseClientProvider.shared else {
            throw DataSyncError.supabaseNotConfigured
        }

        return client
    }

    private func currentUser(client: SupabaseClient) async throws -> User {
        do {
            return try await client.auth.session.user
        } catch {
            throw DataSyncError.noAuthenticatedUser
        }
    }

    private func upsertSettings(
        _ settings: AppSettings,
        activeProfileID: UUID?,
        parentID: UUID,
        client: SupabaseClient
    ) async throws {
        try await client
            .from("app_settings")
            .upsert(
                AppSettingsRow(
                    parentID: parentID,
                    hasCompletedOnboarding: settings.hasCompletedOnboarding,
                    voicePromptsEnabled: settings.voicePromptsEnabled,
                    dailySummaryNotification: settings.dailySummaryNotification,
                    challengeAlertNotification: settings.challengeAlertNotification,
                    freeChallengesUsedToday: settings.freeChallengesUsedToday,
                    freeChallengesResetDate: settings.freeChallengesResetDate,
                    activeProfileID: activeProfileID
                ),
                onConflict: "parent_id"
            )
            .execute()
    }

    private func upsertProfiles(
        _ profiles: [ChildProfile],
        parentID: UUID,
        client: SupabaseClient
    ) async throws {
        guard !profiles.isEmpty else { return }

        let rows = profiles.map { profile in
            ChildProfileRow(
                id: profile.id,
                parentID: parentID,
                ageBand: profile.ageBand.rawValue,
                avatarName: profile.avatarName,
                intervalMinutes: profile.intervalMinutes,
                difficultyOverride: profile.difficultyOverride.rawValue,
                createdAt: isoFormatter.string(from: profile.createdAt),
                updatedAt: isoFormatter.string(from: profile.updatedAt)
            )
        }

        try await client
            .from("child_profiles")
            .upsert(rows, onConflict: "id")
            .execute()
    }

    private func upsertSessions(
        _ sessions: [ChallengeSession],
        parentID: UUID,
        client: SupabaseClient
    ) async throws {
        let rows = sessions.map { session in
            ChallengeSessionRow(
                id: session.id,
                parentID: parentID,
                childProfileID: session.childProfileID,
                sessionDate: dayFormatter.string(from: session.date),
                screenTimeSeconds: session.screenTimeSeconds,
                challengesPresented: session.challengesPresented,
                challengesCompleted: session.challengesCompleted,
                accuracy: session.accuracy
            )
        }

        try await client
            .from("challenge_sessions")
            .upsert(rows, onConflict: "id")
            .execute()
    }

    private func upsertResults(
        _ sessions: [ChallengeSession],
        parentID: UUID,
        client: SupabaseClient
    ) async throws {
        let rows = sessions.flatMap { session in
            session.results.map { result in
                ChallengeResultRow(
                    id: result.id,
                    parentID: parentID,
                    sessionID: session.id,
                    childProfileID: session.childProfileID,
                    type: result.type.rawValue,
                    difficultyLevel: result.difficultyLevel,
                    presentedAt: isoFormatter.string(from: result.presentedAt),
                    completedAt: result.completedAt.map { isoFormatter.string(from: $0) },
                    attempts: result.attempts,
                    completed: result.completed,
                    hintUsed: result.hintUsed,
                    solveTimeSeconds: result.solveTimeSeconds ?? result.solveTime
                )
            }
        }

        guard !rows.isEmpty else { return }

        try await client
            .from("challenge_results")
            .upsert(rows, onConflict: "id")
            .execute()
    }
    #endif

    private static func displayName(from components: PersonNameComponents) -> String {
        PersonNameComponentsFormatter().string(from: components)
    }
}

private struct ParentProfileRow: Encodable {
    let id: UUID
    let appleUserID: String?
    let email: String?
    let fullName: String?
    let revenueCatAppUserID: String

    enum CodingKeys: String, CodingKey {
        case id
        case appleUserID = "apple_user_id"
        case email
        case fullName = "full_name"
        case revenueCatAppUserID = "revenuecat_app_user_id"
    }
}

private struct ChildProfileRow: Encodable {
    let id: UUID
    let parentID: UUID
    let ageBand: String
    let avatarName: String
    let intervalMinutes: Int
    let difficultyOverride: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case parentID = "parent_id"
        case ageBand = "age_band"
        case avatarName = "avatar_name"
        case intervalMinutes = "interval_minutes"
        case difficultyOverride = "difficulty_override"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private struct AppSettingsRow: Encodable {
    let parentID: UUID
    let hasCompletedOnboarding: Bool
    let voicePromptsEnabled: Bool
    let dailySummaryNotification: Bool
    let challengeAlertNotification: Bool
    let freeChallengesUsedToday: Int
    let freeChallengesResetDate: String
    let activeProfileID: UUID?

    enum CodingKeys: String, CodingKey {
        case parentID = "parent_id"
        case hasCompletedOnboarding = "has_completed_onboarding"
        case voicePromptsEnabled = "voice_prompts_enabled"
        case dailySummaryNotification = "daily_summary_notification"
        case challengeAlertNotification = "challenge_alert_notification"
        case freeChallengesUsedToday = "free_challenges_used_today"
        case freeChallengesResetDate = "free_challenges_reset_date"
        case activeProfileID = "active_profile_id"
    }
}

private struct ChallengeSessionRow: Encodable {
    let id: UUID
    let parentID: UUID
    let childProfileID: UUID
    let sessionDate: String
    let screenTimeSeconds: Int
    let challengesPresented: Int
    let challengesCompleted: Int
    let accuracy: Double

    enum CodingKeys: String, CodingKey {
        case id
        case parentID = "parent_id"
        case childProfileID = "child_profile_id"
        case sessionDate = "session_date"
        case screenTimeSeconds = "screen_time_seconds"
        case challengesPresented = "challenges_presented"
        case challengesCompleted = "challenges_completed"
        case accuracy
    }
}

private struct ChallengeResultRow: Encodable {
    let id: UUID
    let parentID: UUID
    let sessionID: UUID
    let childProfileID: UUID
    let type: String
    let difficultyLevel: Int
    let presentedAt: String
    let completedAt: String?
    let attempts: Int
    let completed: Bool
    let hintUsed: Bool
    let solveTimeSeconds: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case parentID = "parent_id"
        case sessionID = "session_id"
        case childProfileID = "child_profile_id"
        case type
        case difficultyLevel = "difficulty_level"
        case presentedAt = "presented_at"
        case completedAt = "completed_at"
        case attempts
        case completed
        case hintUsed = "hint_used"
        case solveTimeSeconds = "solve_time_seconds"
    }
}
