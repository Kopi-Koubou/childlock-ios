import XCTest
@testable import Childlock

@MainActor
final class AppStateTests: XCTestCase {
    func testRecordChallengeResultUpdatesDailySummary() {
        let appState = AppState(store: InMemoryAppStateStore())
        let profile = ChildProfile(name: "Mia", age: 7, avatarName: "fox", intervalMinutes: 10)
        appState.completeOnboarding(with: profile, pinConfigured: true)

        let result = ChallengeResult(
            type: .math,
            difficultyLevel: 5,
            presentedAt: Date(),
            completedAt: Date(),
            attempts: 1,
            completed: true,
            hintUsed: false,
            solveTimeSeconds: 8
        )

        appState.recordChallengeResult(result, for: profile.id)

        XCTAssertEqual(appState.todaySummary.challengesPresented, 1)
        XCTAssertEqual(appState.todaySummary.challengesCompleted, 1)
        XCTAssertEqual(appState.todaySummary.screenTimeSeconds, 600)
        XCTAssertEqual(appState.sessions.count, 1)
    }

    func testRecentActivityIncludesProfileMetadata() {
        let appState = AppState(store: InMemoryAppStateStore())
        let profile = ChildProfile(name: "Leo", age: 9, avatarName: "bear", intervalMinutes: 15)
        appState.completeOnboarding(with: profile, pinConfigured: true)

        let now = Date()
        let result = ChallengeResult(
            type: .pattern,
            difficultyLevel: 8,
            presentedAt: now,
            completedAt: now.addingTimeInterval(10),
            attempts: 2,
            completed: true,
            hintUsed: true,
            solveTimeSeconds: 10
        )

        appState.recordChallengeResult(result, for: profile.id)

        let activity = appState.recentActivity(limit: 5)
        XCTAssertEqual(activity.count, 1)
        XCTAssertEqual(activity.first?.profileName, "Leo")
        XCTAssertEqual(activity.first?.avatarName, "bear")
        XCTAssertEqual(activity.first?.result.type, .pattern)
    }

    func testSummarySupportsWindowAndProfileFiltering() {
        let appState = AppState(store: InMemoryAppStateStore())
        let profileA = ChildProfile(name: "Mia", age: 7, avatarName: "fox", intervalMinutes: 10)
        let profileB = ChildProfile(name: "Leo", age: 9, avatarName: "bear", intervalMinutes: 15)
        appState.completeOnboarding(with: profileA, pinConfigured: true)
        appState.updateProfile(profileB)

        let now = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: now) ?? now

        let todayResultA = ChallengeResult(
            type: .math,
            difficultyLevel: 5,
            presentedAt: now,
            completedAt: now.addingTimeInterval(12),
            attempts: 1,
            completed: true,
            hintUsed: false,
            solveTimeSeconds: 12
        )
        let threeDayResultA = ChallengeResult(
            type: .pattern,
            difficultyLevel: 6,
            presentedAt: threeDaysAgo,
            completedAt: threeDaysAgo.addingTimeInterval(18),
            attempts: 2,
            completed: true,
            hintUsed: true,
            solveTimeSeconds: 18
        )
        let oldResultA = ChallengeResult(
            type: .puzzle,
            difficultyLevel: 6,
            presentedAt: eightDaysAgo,
            completedAt: eightDaysAgo.addingTimeInterval(24),
            attempts: 1,
            completed: true,
            hintUsed: false,
            solveTimeSeconds: 24
        )
        let todayResultB = ChallengeResult(
            type: .memory,
            difficultyLevel: 5,
            presentedAt: now,
            completedAt: now.addingTimeInterval(15),
            attempts: 1,
            completed: true,
            hintUsed: false,
            solveTimeSeconds: 15
        )

        appState.recordChallengeResult(todayResultA, for: profileA.id)
        appState.recordChallengeResult(threeDayResultA, for: profileA.id)
        appState.recordChallengeResult(oldResultA, for: profileA.id)
        appState.recordChallengeResult(todayResultB, for: profileB.id)

        let profileADay = appState.summary(window: .day, profileID: profileA.id, referenceDate: now)
        XCTAssertEqual(profileADay.challengesCompleted, 1)
        XCTAssertEqual(profileADay.challengeSolveSeconds, 12)

        let profileAWeek = appState.summary(window: .week, profileID: profileA.id, referenceDate: now)
        XCTAssertEqual(profileAWeek.challengesCompleted, 2)
        XCTAssertEqual(profileAWeek.challengeSolveSeconds, 30)

        let combinedWeek = appState.summary(window: .week, referenceDate: now)
        XCTAssertEqual(combinedWeek.challengesCompleted, 3)
        XCTAssertEqual(combinedWeek.challengeSolveSeconds, 45)
    }

    func testAddProfileCanInheritMonitoredSelectionFromActiveProfile() {
        let appState = AppState(store: InMemoryAppStateStore())
        var baseProfile = ChildProfile(name: "Mia", age: 7, avatarName: "fox", intervalMinutes: 10)
        let tokenData = Data([0x1, 0x2, 0x3])
        baseProfile.setMonitoredSelectionData(tokenData, displayNames: ["YouTube", "Netflix"])
        appState.completeOnboarding(with: baseProfile, pinConfigured: true)

        let newProfile = appState.addProfile(
            name: "Leo",
            age: 9,
            avatarName: "bear",
            intervalMinutes: 19
        )

        XCTAssertNotNil(newProfile)
        XCTAssertEqual(newProfile?.monitoredSelectionTokenData, tokenData)
        XCTAssertEqual(newProfile?.monitoredAppDisplayNames, ["YouTube", "Netflix"])
        XCTAssertEqual(newProfile?.intervalMinutes, 20)
        XCTAssertEqual(appState.activeProfileID, newProfile?.id)
    }

    func testSetMonitoredSelectionUpdatesTargetProfile() {
        let appState = AppState(store: InMemoryAppStateStore())
        let profile = ChildProfile(name: "Mia", age: 7, avatarName: "fox", intervalMinutes: 10)
        appState.completeOnboarding(with: profile, pinConfigured: true)

        let updated = appState.setMonitoredSelection(
            for: profile.id,
            tokenData: Data([0xA, 0xB]),
            displayNames: ["2 app tokens selected"]
        )

        XCTAssertTrue(updated)
        XCTAssertEqual(appState.activeProfile?.monitoredSelectionTokenData, Data([0xA, 0xB]))
        XCTAssertEqual(appState.activeProfile?.monitoredAppDisplayNames, ["2 app tokens selected"])
    }

    func testApplyActiveProfileMonitoredSelectionToAllChildrenCopiesSelection() {
        let appState = AppState(store: InMemoryAppStateStore())

        var profileA = ChildProfile(name: "Mia", age: 7, avatarName: "fox", intervalMinutes: 10)
        profileA.setMonitoredSelectionData(Data([0x1, 0x2]), displayNames: ["YouTube"])
        let profileB = ChildProfile(name: "Leo", age: 9, avatarName: "bear", intervalMinutes: 15)
        let profileC = ChildProfile(name: "Ana", age: 6, avatarName: "owl", intervalMinutes: 5)

        appState.completeOnboarding(with: profileA, pinConfigured: true)
        appState.updateProfile(profileB)
        appState.updateProfile(profileC)
        appState.setActiveProfile(id: profileA.id)

        let updatedCount = appState.applyActiveProfileMonitoredSelectionToAllChildren()

        XCTAssertEqual(updatedCount, 2)
        XCTAssertEqual(
            appState.profiles.first(where: { $0.id == profileB.id })?.monitoredAppDisplayNames,
            ["YouTube"]
        )
        XCTAssertEqual(
            appState.profiles.first(where: { $0.id == profileC.id })?.monitoredSelectionTokenData,
            Data([0x1, 0x2])
        )
    }
}
