import SwiftUI
import StoreKit

struct ProPaywallView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var showError = false

    private let features: [(icon: String, text: String)] = [
        ("chart.bar.fill", String(localized: "Unlimited History & Charts")),
        ("wind", String(localized: "Breathing Exercise & Ambient Sounds")),
        ("applewatch", String(localized: "Apple Watch & Widget")),
        ("mic.fill", String(localized: "Siri Shortcuts & HealthKit")),
        ("icloud.fill", String(localized: "iCloud Sync & CSV Export")),
        ("slider.horizontal.3", String(localized: "Custom Zones & Themes"))
    ]

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Close button
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .accessibilityLabel("Close")
                    }
                    .padding(.horizontal, Theme.Spacing.md)

                    // Header
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "snowflake")
                            .font(.system(size: 56))
                            .foregroundStyle(Theme.Colors.iceBlue)

                        Text("Upgrade to Pro")
                            .font(Theme.Fonts.heading)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("Unlock the full IceDip experience")
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    // Feature list
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        ForEach(features, id: \.text) { feature in
                            HStack(spacing: Theme.Spacing.md) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.Colors.iceBlue)
                                    .font(.body)
                                Image(systemName: feature.icon)
                                    .foregroundStyle(Theme.Colors.iceBlue)
                                    .frame(width: 24)
                                Text(feature.text)
                                    .font(Theme.Fonts.body)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                            }
                        }
                    }
                    .padding(Theme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, Theme.Spacing.md)

                    // Pricing cards
                    switch purchaseManager.productLoadState {
                    case .notLoaded, .loading:
                        VStack(spacing: Theme.Spacing.md) {
                            ProgressView()
                                .tint(Theme.Colors.iceBlue)
                            Text("Loading subscription options...")
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .padding(Theme.Spacing.xl)

                    case .failed(let message):
                        VStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            Text(message)
                                .font(Theme.Fonts.body)
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                            Button {
                                Task { await purchaseManager.loadProducts() }
                            } label: {
                                Text("Try Again")
                                    .font(Theme.Fonts.headingSmall)
                                    .foregroundStyle(Theme.Colors.iceBlue)
                            }
                        }
                        .padding(Theme.Spacing.lg)
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, Theme.Spacing.md)

                    case .loaded:
                        HStack(spacing: Theme.Spacing.md) {
                            if let monthly = purchaseManager.monthlyProduct {
                                pricingCard(
                                    product: monthly,
                                    title: String(localized: "Monthly"),
                                    subtitle: String(localized: "\(monthly.displayPrice)/month"),
                                    badge: nil,
                                    isSelected: selectedProduct?.id == monthly.id
                                )
                                .onTapGesture { selectedProduct = monthly }
                            }

                            if let yearly = purchaseManager.yearlyProduct {
                                pricingCard(
                                    product: yearly,
                                    title: String(localized: "Yearly"),
                                    subtitle: String(localized: "\(yearly.displayPrice)/year"),
                                    badge: String(localized: "Save 44%"),
                                    isSelected: selectedProduct?.id == yearly.id
                                )
                                .onTapGesture { selectedProduct = yearly }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    }

                    // Subscribe button
                    Button {
                        guard let product = selectedProduct else { return }
                        Task { await purchaseManager.purchase(product) }
                    } label: {
                        Group {
                            if purchaseManager.isPurchasing {
                                ProgressView()
                                    .tint(Theme.Colors.background)
                            } else {
                                Text("Subscribe")
                                    .font(Theme.Fonts.heading)
                            }
                        }
                        .foregroundStyle(Theme.Colors.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            selectedProduct != nil
                                ? Theme.Colors.iceBlue
                                : Theme.Colors.iceBlue.opacity(0.4)
                        )
                        .clipShape(Capsule())
                    }
                    .disabled(selectedProduct == nil || purchaseManager.isPurchasing)
                    .padding(.horizontal, Theme.Spacing.md)

                    Text("Cancel anytime")
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    // Restore purchases
                    Button {
                        Task { await purchaseManager.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.iceBlue)
                    }

                    // Terms & Privacy
                    HStack(spacing: Theme.Spacing.md) {
                        Link("Terms of Use", destination: URL(string: "https://elly2504.github.io/coldplungetimer/terms/")!)
                        Text("·").foregroundStyle(Theme.Colors.textSecondary)
                        Link("Privacy Policy", destination: URL(string: "https://elly2504.github.io/coldplungetimer/privacy/")!)
                    }
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.bottom, Theme.Spacing.lg)
                }
            }
        }
        .task {
            // Retry loading if products weren't loaded at app startup
            if purchaseManager.products.isEmpty {
                await purchaseManager.loadProducts()
            }
            // Default to yearly (best value)
            selectedProduct = purchaseManager.yearlyProduct ?? purchaseManager.monthlyProduct
        }
        .onChange(of: purchaseManager.isProUser) { _, isPro in
            if isPro { dismiss() }
        }
        .onChange(of: purchaseManager.purchaseError) { _, error in
            if error != nil { showError = true }
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {
                purchaseManager.purchaseError = nil
            }
        } message: {
            Text(purchaseManager.purchaseError ?? "Could not complete purchase. Please try again.")
        }
    }

    // MARK: - Pricing Card

    private func pricingCard(
        product: Product,
        title: String,
        subtitle: String,
        badge: String?,
        isSelected: Bool
    ) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            if let badge {
                Text(badge)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.background)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Colors.iceBlue)
                    .clipShape(Capsule())
            }

            Text(title)
                .font(Theme.Fonts.headingSmall)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(product.displayPrice)
                .font(Theme.Fonts.heading)
                .foregroundStyle(Theme.Colors.iceBlue)

            Text(subtitle)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? Theme.Colors.iceBlue : Color.clear,
                    lineWidth: 2
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
