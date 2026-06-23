import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
public final class SubscriptionService {
    public static let shared = SubscriptionService()

    public enum Tier: String, Codable {
        case free
        case premium
    }

    public enum SubscriptionError: Error {
        case purchaseFailed(String)
        case restoreFailed(String)
        case notConfigured
    }

    public private(set) var currentTier: Tier = .free
    public private(set) var isTrialActive = false
    public private(set) var trialDaysRemaining: Int?
    public private(set) var expirationDate: Date?
    public private(set) var isLoading = false

    // Product IDs matching App Store Connect
    public static let monthlyProductID = "childlock_premium_monthly"
    public static let annualProductID = "childlock_premium_annual"
    public static let premiumEntitlementID = "Childlock Pro"

    // Keep Screen Time enforcement available to every family. Apple review is
    // sensitive to monetizing built-in Screen Time APIs, so subscriptions must
    // unlock non-enforcement value only.
    public static let includedChildLimit = 5
    public static let freeChildLimit = includedChildLimit
    public static let premiumChildLimit = includedChildLimit

    private var isConfigured = false

    private init() {}

    public func configure(apiKey: String) {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: apiKey)
        isConfigured = true
        Task { await refreshStatus() }
    }

    public func configure(apiKey: String, appUserID: String) {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: apiKey, appUserID: appUserID)
        isConfigured = true
        Task { await refreshStatus() }
    }

    public func refreshStatus() async {
        guard isConfigured else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateTier(from: customerInfo)
        } catch {
            // Keep current tier on failure (offline grace)
        }
    }

    @discardableResult
    public func purchase(productID: String) async throws -> Bool {
        guard isConfigured else { throw SubscriptionError.notConfigured }
        isLoading = true
        defer { isLoading = false }

        let offerings = try await Purchases.shared.offerings()
        guard let offering = offerings.current,
              let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == productID })
        else {
            throw SubscriptionError.purchaseFailed("Product not found")
        }

        let result = try await Purchases.shared.purchase(package: package)
        guard !result.userCancelled else {
            return false
        }

        updateTier(from: result.customerInfo)
        guard Self.isPremiumActive(in: result.customerInfo) else {
            throw SubscriptionError.purchaseFailed("Purchase finished, but Childlock Premium is not active yet. Check the RevenueCat entitlement mapping.")
        }

        return true
    }

    @discardableResult
    public func restorePurchases() async throws -> Bool {
        guard isConfigured else { throw SubscriptionError.notConfigured }
        isLoading = true
        defer { isLoading = false }

        let customerInfo = try await Purchases.shared.restorePurchases()
        updateTier(from: customerInfo)
        return Self.isPremiumActive(in: customerInfo)
    }

    public func getOfferings() async throws -> (monthly: StoreProduct?, annual: StoreProduct?) {
        guard isConfigured else { throw SubscriptionError.notConfigured }

        let offerings = try await Purchases.shared.offerings()
        guard let offering = offerings.current else {
            return (nil, nil)
        }

        let monthly = offering.availablePackages.first { $0.storeProduct.productIdentifier == Self.monthlyProductID }?.storeProduct
        let annual = offering.availablePackages.first { $0.storeProduct.productIdentifier == Self.annualProductID }?.storeProduct

        return (monthly, annual)
    }

    public var childLimit: Int {
        Self.includedChildLimit
    }

    public var dailyChallengeLimit: Int? {
        nil
    }

    public func canAddChild(currentCount: Int) -> Bool {
        currentCount < childLimit
    }

    public func hasReachedDailyLimit(completedToday: Int) -> Bool {
        _ = completedToday
        return false
    }

    private func updateTier(from customerInfo: CustomerInfo) {
        let hasActive = Self.isPremiumActive(in: customerInfo)
        currentTier = hasActive ? .premium : .free

        if let entitlement = customerInfo.entitlements.active[Self.premiumEntitlementID] {
            expirationDate = entitlement.expirationDate
            // Do not infer trial status from purchase age. If we surface trials
            // later, use verified StoreKit/RevenueCat period metadata instead.
            isTrialActive = false
            trialDaysRemaining = nil
        } else {
            expirationDate = nil
            isTrialActive = false
            trialDaysRemaining = nil
        }
    }

    private static func isPremiumActive(in customerInfo: CustomerInfo) -> Bool {
        customerInfo.entitlements.active[premiumEntitlementID] != nil
    }

    public func logIn(appUserID: String) async {
        guard isConfigured else { return }
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(appUserID)
            updateTier(from: customerInfo)
        } catch {
            // Silent failure - keep current state
        }
    }

    public func logOut() async {
        guard isConfigured else { return }
        do {
            let customerInfo = try await Purchases.shared.logOut()
            updateTier(from: customerInfo)
        } catch {
            currentTier = .free
        }
    }
}
