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

    // Free tier limits
    public static let freeChallengesPerDay = 3
    public static let freeChildLimit = 1
    public static let premiumChildLimit = 5

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

    public func purchase(productID: String) async throws {
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
        if !result.userCancelled {
            updateTier(from: result.customerInfo)
        }
    }

    public func restorePurchases() async throws {
        guard isConfigured else { throw SubscriptionError.notConfigured }
        isLoading = true
        defer { isLoading = false }

        let customerInfo = try await Purchases.shared.restorePurchases()
        updateTier(from: customerInfo)
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
        currentTier == .premium ? Self.premiumChildLimit : Self.freeChildLimit
    }

    public var dailyChallengeLimit: Int? {
        currentTier == .premium ? nil : Self.freeChallengesPerDay
    }

    public func canAddChild(currentCount: Int) -> Bool {
        currentCount < childLimit
    }

    public func hasReachedDailyLimit(completedToday: Int) -> Bool {
        guard let limit = dailyChallengeLimit else { return false }
        return completedToday >= limit
    }

    private func updateTier(from customerInfo: CustomerInfo) {
        let hasActive = !customerInfo.entitlements.active.isEmpty
        currentTier = hasActive ? .premium : .free

        if let entitlement = customerInfo.entitlements.active.first?.value {
            expirationDate = entitlement.expirationDate

            if let originalPurchaseDate = entitlement.originalPurchaseDate,
               let expirationDate = entitlement.expirationDate {
                let trialLength: TimeInterval = 7 * 24 * 60 * 60
                let timeSincePurchase = Date().timeIntervalSince(originalPurchaseDate)
                if timeSincePurchase < trialLength {
                    isTrialActive = true
                    trialDaysRemaining = max(0, Int(ceil((trialLength - timeSincePurchase) / (24 * 60 * 60))))
                } else {
                    isTrialActive = false
                    trialDaysRemaining = nil
                }
            }
        } else {
            expirationDate = nil
            isTrialActive = false
            trialDaysRemaining = nil
        }
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
