import XCTest
@testable import Childlock

@MainActor
final class AppStatePersistenceTests: XCTestCase {
    func testInitLoadsSnapshotFromStore() {
        let profile = ChildProfile(name: "Nia", age: 8, avatarName: "owl", intervalMinutes: 15)
        let session = ChallengeSession(
            childProfileID: profile.id,
            screenTimeSeconds: 900,
            results: []
        )
        let settings = AppSettings(
            hasCompletedOnboarding: true,
            voicePromptsEnabled: false,
            dailySummaryNotification: false,
            challengeAlertNotification: true,
            freeChallengesUsedToday: 2,
            freeChallengesResetDate: "2026-03-14"
        )
        let snapshot = AppStateSnapshot(
            hasCompletedOnboarding: true,
            currentTab: .apps,
            isPINLocked: false,
            profiles: [profile],
            sessions: [session],
            activeProfileID: profile.id,
            settings: settings
        )
        let store = InMemoryAppStateStore(snapshot: snapshot)

        let appState = AppState(store: store)

        XCTAssertTrue(appState.hasCompletedOnboarding)
        XCTAssertEqual(appState.currentTab, .apps)
        XCTAssertFalse(appState.isPINLocked)
        XCTAssertEqual(appState.profiles, [profile])
        XCTAssertEqual(appState.sessions, [session])
        XCTAssertEqual(appState.activeProfileID, profile.id)
        XCTAssertEqual(appState.settings, settings)
    }

    func testCompleteOnboardingPersistsSnapshot() {
        let store = InMemoryAppStateStore()
        let appState = AppState(store: store)
        let profile = ChildProfile(name: "Mia", age: 7, avatarName: "fox", intervalMinutes: 10)

        appState.completeOnboarding(with: profile, pinConfigured: true)

        guard let saved = store.snapshot else {
            XCTFail("Expected persisted snapshot")
            return
        }

        XCTAssertTrue(saved.hasCompletedOnboarding)
        XCTAssertEqual(saved.activeProfileID, profile.id)
        XCTAssertEqual(saved.profiles.first?.id, profile.id)
        XCTAssertTrue(saved.settings.hasCompletedOnboarding)
    }

    func testSettingsAndTabMutationsPersist() {
        let store = InMemoryAppStateStore()
        let appState = AppState(store: store)

        var updatedSettings = appState.settings
        updatedSettings.voicePromptsEnabled = false
        updatedSettings.dailySummaryNotification = false
        appState.settings = updatedSettings
        appState.currentTab = .settings

        guard let saved = store.snapshot else {
            XCTFail("Expected persisted snapshot")
            return
        }

        XCTAssertFalse(saved.settings.voicePromptsEnabled)
        XCTAssertFalse(saved.settings.dailySummaryNotification)
        XCTAssertEqual(saved.currentTab, .settings)
    }

    func testAppGroupFileStoreRoundTrip() {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("childlock-tests-\(UUID().uuidString)", isDirectory: true)
        let store = AppGroupFileAppStateStore(
            fileName: "state.json",
            stateDirectoryURL: directory,
            fallbackDefaults: UserDefaults.standard,
            fallbackKey: "appStateSnapshot.test.roundtrip"
        )

        let profile = ChildProfile(name: "Kai", age: 8, avatarName: "owl", intervalMinutes: 15)
        let snapshot = AppStateSnapshot(
            hasCompletedOnboarding: true,
            currentTab: .children,
            isPINLocked: false,
            profiles: [profile],
            sessions: [],
            activeProfileID: profile.id,
            settings: .default
        )

        store.save(snapshot)
        let loaded = store.load()

        XCTAssertEqual(loaded, snapshot)
        store.clear()
    }

    func testAppGroupFileStoreMigratesFromFallbackDefaults() {
        let suiteName = "childlock.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected test defaults suite")
            return
        }

        let fallbackKey = "appStateSnapshot.legacy"
        let fallbackStore = UserDefaultsAppStateStore(defaults: defaults, key: fallbackKey)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("childlock-tests-\(UUID().uuidString)", isDirectory: true)
        let fileStore = AppGroupFileAppStateStore(
            fileName: "state.json",
            stateDirectoryURL: directory,
            fallbackDefaults: defaults,
            fallbackKey: fallbackKey
        )

        let profile = ChildProfile(name: "Nia", age: 9, avatarName: "bear", intervalMinutes: 20)
        let snapshot = AppStateSnapshot(
            hasCompletedOnboarding: true,
            currentTab: .apps,
            isPINLocked: true,
            profiles: [profile],
            sessions: [],
            activeProfileID: profile.id,
            settings: .default
        )

        fallbackStore.save(snapshot)
        let loaded = fileStore.load()

        XCTAssertEqual(loaded, snapshot)
        fileStore.clear()
        defaults.removePersistentDomain(forName: suiteName)
    }
}
