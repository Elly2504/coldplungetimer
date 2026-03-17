import StoreKit
import OSLog
import WidgetKit

@MainActor
@Observable
final class PurchaseManager {
    private static let logger = Logger(subsystem: "com.icedip.app", category: "Purchases")

    static let monthlyID = "com.icedip.app.pro.monthly"
    static let yearlyID = "com.icedip.app.pro.yearly"
    static let productIDs: Set<String> = [monthlyID, yearlyID]

    enum ProductLoadState {
        case notLoaded, loading, loaded, failed(String)
    }

    var products: [Product] = []
    var productLoadState: ProductLoadState = .notLoaded
    var isProUser: Bool = false {
        didSet {
            syncProStatusToAppGroup()
        }
    }
    var purchaseError: String?
    var isPurchasing = false

    private var transactionListener: Task<Void, Never>?

    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }
    var yearlyProduct: Product? { products.first { $0.id == Self.yearlyID } }

    init() {
        transactionListener = Task { [weak self] in
            await self?.listenForTransactions()
        }
    }

    // MARK: - Load Products

    func loadProducts() async {
        productLoadState = .loading
        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
            if products.isEmpty {
                productLoadState = .failed(String(localized: "Subscriptions are temporarily unavailable. Please try again later."))
                Self.logger.error("Product.products returned empty array — check App Store Connect configuration")
            } else {
                productLoadState = .loaded
                Self.logger.info("Loaded \(self.products.count) products")
            }
        } catch {
            productLoadState = .failed(String(localized: "Could not load subscriptions. Please check your connection and try again."))
            Self.logger.error("Failed to load products: \(error, privacy: .public)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if let transaction = try? verification.payloadValue {
                    await transaction.finish()
                    await checkEntitlements()
                    Self.logger.info("Purchase succeeded: \(product.id, privacy: .public)")
                } else {
                    purchaseError = "Purchase verification failed."
                    Self.logger.error("Purchase verification failed for \(product.id, privacy: .public)")
                }
            case .userCancelled:
                Self.logger.info("User cancelled purchase")
            case .pending:
                Self.logger.info("Purchase pending (ask-to-buy)")
            @unknown default:
                Self.logger.info("Unknown purchase result")
            }
        } catch {
            purchaseError = error.localizedDescription
            Self.logger.error("Purchase failed: \(error, privacy: .public)")
        }

        isPurchasing = false
    }

    // MARK: - Check Entitlements

    func checkEntitlements() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue {
                if Self.productIDs.contains(transaction.productID)
                    && transaction.revocationDate == nil {
                    hasActiveSubscription = true
                    await transaction.finish()
                }
            }
        }

        isProUser = hasActiveSubscription
        Self.logger.info("Entitlement check: isProUser = \(self.isProUser)")
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkEntitlements()
            Self.logger.info("Restore purchases completed")
        } catch {
            purchaseError = "Could not restore purchases. Please try again."
            Self.logger.error("Restore failed: \(error, privacy: .public)")
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? result.payloadValue {
                await transaction.finish()
                await checkEntitlements()
                Self.logger.info("Transaction update: \(transaction.productID, privacy: .public)")
            }
        }
    }

    // MARK: - App Group Sync

    private func syncProStatusToAppGroup() {
        UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)?
            .set(isProUser, forKey: PreferenceKey.isProUser)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
