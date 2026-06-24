import XCTest

final class PaywallCopyTests: XCTestCase {
    func testPaywallDoesNotAdvertiseUnavailableTrialsOrFallbackPrices() throws {
        let contents = try readRepoFile("Sources/Childlock/Views/Paywall/PaywallView.swift")

        XCTAssertFalse(contents.localizedCaseInsensitiveContains("free trial"))
        XCTAssertFalse(contents.contains("Start 7-day"))
        XCTAssertFalse(contents.contains("$39.99"))
        XCTAssertFalse(contents.contains("$4.99"))
        XCTAssertFalse(contents.contains("save 33%"))
        XCTAssertTrue(contents.contains("Screen Time enforcement stays included without Premium."))
        XCTAssertTrue(contents.contains("Subscriptions are not available right now. Screen Time enforcement remains included."))
        XCTAssertTrue(contents.contains("Premium unavailable"))
        XCTAssertTrue(contents.contains("Loading Premium..."))
        XCTAssertTrue(contents.contains("if shouldShowCTA"))
        XCTAssertTrue(contents.contains("isLoading || !hasLoadedOfferings || selectedProductIsAvailable"))
        XCTAssertTrue(contents.contains(".opacity(isLoading || !selectedProductIsAvailable ? 0.55 : 1)"))
        XCTAssertTrue(contents.contains(".padding(.bottom, ChildlockSpacing.section + 120)"))
        XCTAssertLessThan(
            try XCTUnwrap(contents.range(of: "restoreLink")?.lowerBound),
            try XCTUnwrap(contents.range(of: "ctaButton")?.lowerBound)
        )
    }

    func testUnavailablePlanRowsAreNotRenderedAsSelected() throws {
        let contents = try readRepoFile("Sources/Childlock/Views/Paywall/PaywallView.swift")

        XCTAssertTrue(contents.contains("private var annualPlanIsSelected: Bool"))
        XCTAssertTrue(contents.contains("selectedPlan == .annual && annualPlanAvailable"))
        XCTAssertTrue(contents.contains("private var monthlyPlanIsSelected: Bool"))
        XCTAssertTrue(contents.contains("selectedPlan == .monthly && monthlyPlanAvailable"))
        XCTAssertTrue(contents.contains("radioIndicator(selected: annualPlanIsSelected)"))
        XCTAssertTrue(contents.contains("radioIndicator(selected: monthlyPlanIsSelected)"))
        XCTAssertTrue(contents.contains("annualPlanIsSelected ? ChildlockColor.primarySoft : ChildlockColor.surface"))
        XCTAssertTrue(contents.contains("monthlyPlanIsSelected ? ChildlockColor.primarySoft : ChildlockColor.surface"))
        XCTAssertFalse(contents.contains("radioIndicator(selected: selectedPlan == .annual)"))
        XCTAssertFalse(contents.contains("radioIndicator(selected: selectedPlan == .monthly)"))
    }

    func testSubscriptionServiceDoesNotInferTrialStatusFromPurchaseAge() throws {
        let contents = try readRepoFile("Sources/Childlock/Services/SubscriptionService.swift")

        XCTAssertFalse(contents.contains("7 * 24 * 60 * 60"))
        XCTAssertFalse(contents.contains("trialLength"))
        XCTAssertTrue(contents.contains("Do not infer trial status from purchase age."))
    }

    func testSubscriptionServiceUsesDocumentedPremiumEntitlement() throws {
        let service = try readRepoFile("Sources/Childlock/Services/SubscriptionService.swift")
        let production = try readRepoFile("docs/PRODUCTION.md")
        let metadata = try readRepoFile("docs/APP_STORE_CONNECT_METADATA.md")

        XCTAssertTrue(service.contains("premiumEntitlementID = \"Childlock Pro\""))
        XCTAssertTrue(service.contains("customerInfo.entitlements.active[premiumEntitlementID] != nil"))
        XCTAssertTrue(service.contains("Purchase finished, but Childlock Premium is not active yet."))

        for contents in [production, metadata] {
            XCTAssertTrue(contents.contains("Childlock Pro"))
            XCTAssertTrue(contents.contains("childlock_premium_monthly"))
            XCTAssertTrue(contents.contains("childlock_premium_annual"))
        }
    }

    func testPaywallOnlyDismissesAfterPurchaseOrRestoreActivatesPremium() throws {
        let contents = try readRepoFile("Sources/Childlock/Views/Paywall/PaywallView.swift")

        XCTAssertTrue(contents.contains("let didActivatePremium = try await SubscriptionService.shared.purchase(productID: productID)"))
        XCTAssertTrue(contents.contains("if didActivatePremium {\n                dismiss()\n            }"))
        XCTAssertTrue(contents.contains("let didRestorePremium = try await SubscriptionService.shared.restorePurchases()"))
        XCTAssertTrue(contents.contains("if didRestorePremium {\n                dismiss()\n            } else {"))
        XCTAssertTrue(contents.contains("No active Childlock Premium purchase was found for this Apple ID."))
    }

    private func readRepoFile(_ relativePath: String) throws -> String {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repoRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = repoRoot.appendingPathComponent(relativePath)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }
}
