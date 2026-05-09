import SwiftUI

#if canImport(RevenueCat)
import RevenueCat
#endif

public struct PaywallView: View {
    private let dismiss: () -> Void

    @State private var selectedPlan: Plan = .annual
    @State private var isLoading = false
    @State private var errorMessage: String?
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
                    ctaButton
                    restoreLink
                    footerLinks
                }
                .padding(.horizontal, ChildlockSpacing.lg)
                .padding(.top, ChildlockSpacing.xl)
                .padding(.bottom, ChildlockSpacing.section)
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
            Text("Unlock unlimited\nbrain breaks")
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

            comparisonRow(feature: "Challenges", free: "3/day", premium: "Unlimited")
            comparisonRow(feature: "Children", free: "1 child", premium: "5 children")
            comparisonRow(feature: "Statistics", free: "Basic stats", premium: "Full reports")
            comparisonRow(feature: "Challenge types", free: "2 types", premium: "All types")
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
                                Text("Best Value")
                                    .font(ChildlockTypography.label)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, ChildlockSpacing.xs)
                                    .padding(.vertical, 3)
                                    .background(ChildlockColor.primary)
                                    .clipShape(Capsule())
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

    private var ctaButton: some View {
        Button {
            Task { await handlePurchase() }
        } label: {
            Text("Start 7-day free trial")
        }
        .buttonStyle(ChildlockPrimaryButtonStyle())
        .disabled(isLoading)
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
        HStack(spacing: ChildlockSpacing.xxs) {
            Text("Terms")
                .font(ChildlockTypography.caption)
                .foregroundStyle(ChildlockColor.textMuted)
            Text("\u{00B7}")
                .font(ChildlockTypography.caption)
                .foregroundStyle(ChildlockColor.textMuted)
            Text("Privacy")
                .font(ChildlockTypography.caption)
                .foregroundStyle(ChildlockColor.textMuted)
        }
    }

    // MARK: - Price Text

    private var annualPriceText: String {
        #if canImport(RevenueCat)
        if let product = annualProduct {
            let monthlyEquiv = product.price as Decimal / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceFormatter?.locale ?? .current
            let monthlyStr = formatter.string(from: monthlyEquiv as NSDecimalNumber) ?? "$3.33"
            return "\(product.localizedPriceString)/year (\(monthlyStr)/mo \u{2013} save 33%)"
        }
        #endif
        return "$39.99/year ($3.33/mo \u{2013} save 33%)"
    }

    private var monthlyPriceText: String {
        #if canImport(RevenueCat)
        if let product = monthlyProduct {
            return "\(product.localizedPriceString)/month"
        }
        #endif
        return "$4.99/month"
    }

    // MARK: - Actions

    private func loadOfferings() async {
        #if canImport(RevenueCat)
        do {
            let products = try await SubscriptionService.shared.getOfferings()
            monthlyProduct = products.monthly
            annualProduct = products.annual
        } catch {
            // Use fallback prices
        }
        #endif
    }

    private func handlePurchase() async {
        #if canImport(RevenueCat)
        let productID = selectedPlan == .annual
            ? SubscriptionService.annualProductID
            : SubscriptionService.monthlyProductID

        isLoading = true
        defer { isLoading = false }

        do {
            try await SubscriptionService.shared.purchase(productID: productID)
            dismiss()
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
        #endif
    }

    private func handleRestore() async {
        #if canImport(RevenueCat)
        isLoading = true
        defer { isLoading = false }

        do {
            try await SubscriptionService.shared.restorePurchases()
            if SubscriptionService.shared.currentTier == .premium {
                dismiss()
            }
        } catch {
            errorMessage = "Could not restore purchases. Please try again."
            showError = true
        }
        #endif
    }
}
