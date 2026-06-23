import SwiftUI

#if canImport(RevenueCat)
import RevenueCat
#endif

public struct PaywallView: View {
    private let dismiss: () -> Void
    private static let termsURL = URL(string: "https://kouboulabs.com/childlock/terms")!
    private static let privacyURL = URL(string: "https://kouboulabs.com/childlock/privacy")!
    private static let subscriptionUnavailableMessage =
        "Subscriptions are not available right now. Screen Time enforcement remains included."

    @State private var selectedPlan: Plan = .annual
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var offeringsErrorMessage: String?
    @State private var hasLoadedOfferings = false
    @State private var showError = false

    #if canImport(RevenueCat)
    @State private var monthlyProduct: StoreProduct?
    @State private var annualProduct: StoreProduct?
    #endif

    public enum Plan {
        case monthly
        case annual
    }

    public init(dismiss: @escaping () -> Void) {
        self.dismiss = dismiss
    }

    public var body: some View {
        ZStack {
            ChildlockColor.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: ChildlockSpacing.lg) {
                    header
                    comparisonTable
                    planCards
                    availabilityNotice
                    restoreLink
                    ctaButton
                    footerLinks
                }
                .padding(.horizontal, ChildlockSpacing.lg)
                .padding(.top, ChildlockSpacing.xl)
                .padding(.bottom, ChildlockSpacing.section + 120)
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: dismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(ChildlockColor.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(ChildlockColor.surfaceMuted)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, ChildlockSpacing.md)
                    .padding(.top, ChildlockSpacing.md)
                }
                Spacer()
            }

            if isLoading {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(ChildlockColor.primary)
                    .scaleEffect(1.2)
            }
        }
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again later.")
        }
        .task {
            await loadOfferings()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: ChildlockSpacing.xs) {
            Text("Unlock deeper\nreports")
                .font(ChildlockTypography.title)
                .foregroundStyle(ChildlockColor.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, ChildlockSpacing.lg)
    }

    // MARK: - Comparison Table

    private var comparisonTable: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("Feature")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("FREE")
                    .font(ChildlockTypography.label)
                    .foregroundStyle(ChildlockColor.textMuted)
                    .frame(width: 80)
                Text("PREMIUM")
                    .font(ChildlockTypography.label)
                    .foregroundStyle(ChildlockColor.primary)
                    .frame(width: 80)
            }
            .padding(.horizontal, ChildlockSpacing.md)
            .padding(.vertical, ChildlockSpacing.sm)

            Divider().foregroundStyle(ChildlockColor.surfaceMuted)

            comparisonRow(feature: "Brain breaks", free: "Included", premium: "Included")
            comparisonRow(feature: "Children", free: "5 children", premium: "5 children")
            comparisonRow(feature: "Child reports", free: "Today", premium: "Week + all time")
            comparisonRow(feature: "Activity history", free: "Recent", premium: "Extended")
        }
        .background(ChildlockColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
        .childlockShadow(ChildlockShadow.sm)
    }

    private func comparisonRow(feature: String, free: String, premium: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(feature)
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(free)
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textMuted)
                    .frame(width: 80)
                Text(premium)
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.primary)
                    .fontWeight(.semibold)
                    .frame(width: 80)
            }
            .padding(.horizontal, ChildlockSpacing.md)
            .padding(.vertical, ChildlockSpacing.sm)

            Divider().foregroundStyle(ChildlockColor.surfaceMuted)
        }
    }

    // MARK: - Plan Cards

    private var planCards: some View {
        VStack(spacing: ChildlockSpacing.sm) {
            // Annual plan (highlighted)
            Button { selectedPlan = .annual } label: {
                VStack(spacing: ChildlockSpacing.xxs) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: ChildlockSpacing.xs) {
                                Text("Annual")
                                    .font(ChildlockTypography.bodyBold)
                                    .foregroundStyle(ChildlockColor.textPrimary)
                                if annualSavingsText != nil {
                                    Text("Best Value")
                                        .font(ChildlockTypography.label)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, ChildlockSpacing.xs)
                                        .padding(.vertical, 3)
                                        .background(ChildlockColor.primary)
                                        .clipShape(Capsule())
                                }
                            }
                            Text(annualPriceText)
                                .font(ChildlockTypography.caption)
                                .foregroundStyle(ChildlockColor.textSecondary)
                        }
                        Spacer()
                        radioIndicator(selected: selectedPlan == .annual)
                    }
                }
                .padding(ChildlockSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ChildlockRadius.card)
                        .fill(ChildlockColor.primarySoft)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ChildlockRadius.card)
                        .stroke(ChildlockColor.primary, lineWidth: selectedPlan == .annual ? 2 : 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!annualPlanAvailable)
            .opacity(annualPlanAvailable ? 1 : 0.65)

            // Monthly plan
            Button { selectedPlan = .monthly } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monthly")
                            .font(ChildlockTypography.bodyBold)
                            .foregroundStyle(ChildlockColor.textPrimary)
                        Text(monthlyPriceText)
                            .font(ChildlockTypography.caption)
                            .foregroundStyle(ChildlockColor.textSecondary)
                    }
                    Spacer()
                    radioIndicator(selected: selectedPlan == .monthly)
                }
                .padding(ChildlockSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: ChildlockRadius.card)
                        .fill(ChildlockColor.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ChildlockRadius.card)
                        .stroke(ChildlockColor.surfaceMuted, lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
            .disabled(!monthlyPlanAvailable)
            .opacity(monthlyPlanAvailable ? 1 : 0.65)
        }
    }

    private func radioIndicator(selected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(selected ? ChildlockColor.primary : ChildlockColor.textFaint, lineWidth: 2)
                .frame(width: 22, height: 22)
            if selected {
                Circle()
                    .fill(ChildlockColor.primary)
                    .frame(width: 12, height: 12)
            }
        }
    }

    // MARK: - CTA

    private var availabilityNotice: some View {
        Group {
            if let offeringsErrorMessage {
                HStack(alignment: .top, spacing: ChildlockSpacing.xs) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ChildlockColor.textSecondary)
                    Text(offeringsErrorMessage)
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(ChildlockSpacing.sm)
                .background(ChildlockColor.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
            }
        }
    }

    @ViewBuilder
    private var ctaButton: some View {
        if shouldShowCTA {
            Button {
                Task { await handlePurchase() }
            } label: {
                Text(ctaButtonTitle)
            }
            .buttonStyle(ChildlockPrimaryButtonStyle())
            .disabled(isLoading || !selectedProductIsAvailable)
            .opacity(isLoading || !selectedProductIsAvailable ? 0.55 : 1)
        }
    }

    private var shouldShowCTA: Bool {
        isLoading || !hasLoadedOfferings || selectedProductIsAvailable
    }

    private var ctaButtonTitle: String {
        if isLoading {
            return "Loading..."
        }

        if !hasLoadedOfferings {
            return "Loading Premium..."
        }

        if !selectedProductIsAvailable {
            return "Premium unavailable"
        }

        return "Continue with Premium"
    }

    // MARK: - Restore

    private var restoreLink: some View {
        Button {
            Task { await handleRestore() }
        } label: {
            Text("Restore purchases")
                .font(ChildlockTypography.caption)
                .foregroundStyle(ChildlockColor.textMuted)
        }
        .disabled(isLoading)
    }

    // MARK: - Footer

    private var footerLinks: some View {
        VStack(spacing: ChildlockSpacing.xs) {
            Text("Screen Time enforcement stays included without Premium.")
                .font(ChildlockTypography.caption)
                .foregroundStyle(ChildlockColor.textMuted)
                .multilineTextAlignment(.center)

            HStack(spacing: ChildlockSpacing.xxs) {
                Link("Terms", destination: Self.termsURL)
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textMuted)
                Text("\u{00B7}")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textMuted)
                Link("Privacy", destination: Self.privacyURL)
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textMuted)
            }
        }
    }

    // MARK: - Price Text

    private var annualPriceText: String {
        #if canImport(RevenueCat)
        if let product = annualProduct {
            let baseText = "\(product.localizedPriceString)/year"
            guard let monthlyEquivalent = monthlyEquivalentText(for: product) else {
                return baseText
            }

            if let annualSavingsText {
                return "\(baseText) (\(monthlyEquivalent)/mo - \(annualSavingsText))"
            }

            return "\(baseText) (\(monthlyEquivalent)/mo)"
        }
        #endif
        return hasLoadedOfferings ? "Annual plan unavailable" : "Loading annual price..."
    }

    private var monthlyPriceText: String {
        #if canImport(RevenueCat)
        if let product = monthlyProduct {
            return "\(product.localizedPriceString)/month"
        }
        #endif
        return hasLoadedOfferings ? "Monthly plan unavailable" : "Loading monthly price..."
    }

    private var selectedProductIsAvailable: Bool {
        selectedPlan == .annual ? annualPlanAvailable : monthlyPlanAvailable
    }

    private var annualPlanAvailable: Bool {
        #if canImport(RevenueCat)
        annualProduct != nil
        #else
        false
        #endif
    }

    private var monthlyPlanAvailable: Bool {
        #if canImport(RevenueCat)
        monthlyProduct != nil
        #else
        false
        #endif
    }

    private var annualSavingsText: String? {
        #if canImport(RevenueCat)
        guard let annualProduct, let monthlyProduct else {
            return nil
        }

        let annualMonthlyEquivalent = NSDecimalNumber(decimal: annualProduct.price)
            .dividing(by: NSDecimalNumber(value: 12))
        let monthlyPrice = NSDecimalNumber(decimal: monthlyProduct.price)

        guard monthlyPrice.compare(NSDecimalNumber.zero) == .orderedDescending,
              monthlyPrice.compare(annualMonthlyEquivalent) == .orderedDescending
        else {
            return nil
        }

        let savingsPercent = monthlyPrice
            .subtracting(annualMonthlyEquivalent)
            .dividing(by: monthlyPrice)
            .multiplying(by: NSDecimalNumber(value: 100))
            .rounding(accordingToBehavior: NSDecimalNumberHandler(
                roundingMode: .plain,
                scale: 0,
                raiseOnExactness: false,
                raiseOnOverflow: false,
                raiseOnUnderflow: false,
                raiseOnDivideByZero: false
            ))

        guard savingsPercent.intValue > 0 else {
            return nil
        }

        return "save \(savingsPercent.intValue)%"
        #else
        return nil
        #endif
    }

    #if canImport(RevenueCat)
    private func monthlyEquivalentText(for product: StoreProduct) -> String? {
        let monthlyEquivalent = NSDecimalNumber(decimal: product.price)
            .dividing(by: NSDecimalNumber(value: 12))
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatter?.locale ?? .current
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: monthlyEquivalent)
    }
    #endif

    // MARK: - Actions

    private func loadOfferings() async {
        offeringsErrorMessage = nil
        #if canImport(RevenueCat)
        do {
            let products = try await SubscriptionService.shared.getOfferings()
            monthlyProduct = products.monthly
            annualProduct = products.annual
            hasLoadedOfferings = true

            if annualProduct == nil, monthlyProduct != nil {
                selectedPlan = .monthly
            } else if annualProduct != nil {
                selectedPlan = .annual
            }

            if monthlyProduct == nil, annualProduct == nil {
                offeringsErrorMessage = Self.subscriptionUnavailableMessage
            }
        } catch {
            hasLoadedOfferings = true
            offeringsErrorMessage = Self.subscriptionUnavailableMessage
        }
        #else
        hasLoadedOfferings = true
        offeringsErrorMessage = Self.subscriptionUnavailableMessage
        #endif
    }

    private func handlePurchase() async {
        guard selectedProductIsAvailable else {
            offeringsErrorMessage = Self.subscriptionUnavailableMessage
            errorMessage = Self.subscriptionUnavailableMessage
            showError = true
            return
        }

        #if canImport(RevenueCat)
        let productID = selectedPlan == .annual
            ? SubscriptionService.annualProductID
            : SubscriptionService.monthlyProductID

        isLoading = true
        defer { isLoading = false }

        do {
            let didActivatePremium = try await SubscriptionService.shared.purchase(productID: productID)
            if didActivatePremium {
                dismiss()
            }
        } catch let error as SubscriptionService.SubscriptionError {
            switch error {
            case .purchaseFailed(let message):
                errorMessage = message
                showError = true
            case .notConfigured:
                errorMessage = "Subscriptions are not available right now."
                showError = true
            default:
                errorMessage = "Purchase could not be completed."
                showError = true
            }
        } catch {
            // User cancelled or other non-fatal error
        }
        #else
        offeringsErrorMessage = Self.subscriptionUnavailableMessage
        errorMessage = Self.subscriptionUnavailableMessage
        showError = true
        #endif
    }

    private func handleRestore() async {
        #if canImport(RevenueCat)
        isLoading = true
        defer { isLoading = false }

        do {
            let didRestorePremium = try await SubscriptionService.shared.restorePurchases()
            if didRestorePremium {
                dismiss()
            } else {
                errorMessage = "No active Childlock Premium purchase was found for this Apple ID."
                showError = true
            }
        } catch {
            errorMessage = "Could not restore purchases. Please try again."
            showError = true
        }
        #endif
    }
}
