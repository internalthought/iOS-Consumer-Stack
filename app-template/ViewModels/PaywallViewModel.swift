import Foundation
import Combine
import RevenueCat

/// ViewModel for handling paywall UI logic and RevenueCat integration
class PaywallViewModel: ObservableObject {
    // Dependencies
    private let revenueCatService: RevenueCatServiceProtocol
    private let errorHandler: ErrorHandlerProtocol
    private let analytics: AnalyticsServiceProtocol

    // Published properties for UI state
    @Published var offerings: [Package] = []
    @Published var selectedPackage: Package? = nil
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var purchaseError: Error? = nil
    @Published var subscriptionStatus: String? = nil
    @Published var isSubscribed = false
    @Published var promotionalCode = ""
    @Published var isPromotionalCodeValid = false
    @Published var paywallLoaded = false

    /// Initialize ViewModel with RevenueCat service dependency
    /// - Parameter revenueCatService: Service for handling IAP operations
    /// - Parameter errorHandler: Service for error handling
    /// - Parameter onPurchase: Closure to call when purchase completes successfully
    init(revenueCatService: RevenueCatServiceProtocol,
         errorHandler: ErrorHandlerProtocol = ServiceLocator.shared.errorHandler,
         onPurchase: (() -> Void)? = nil,
         analytics: AnalyticsServiceProtocol = ServiceLocator.shared.analyticsService) {
        self.revenueCatService = revenueCatService
        self.errorHandler = errorHandler
        self.onPurchase = onPurchase
        self.analytics = analytics
    }

    private let onPurchase: (() -> Void)?

    /// Load subscription offerings from RevenueCat
    @MainActor
    func loadOfferings() async {
        isLoading = true
        purchaseError = nil

        do {
            let offeringsData = try await revenueCatService.fetchOfferings()
            if let currentOffering = offeringsData.current {
                offerings = currentOffering.availablePackages
            } else {
                var allPackages: [Package] = []
                for (_, offering) in offeringsData.all {
                    allPackages.append(contentsOf: offering.availablePackages)
                }
                offerings = allPackages
            }

            if selectedPackage == nil {
                if let monthly = offerings.first(where: { $0.storeProduct.subscriptionPeriod?.unit == .month }) {
                    selectedPackage = monthly
                } else {
                    selectedPackage = offerings.first
                }
            }

            trackAnalytics("paywall_offerings_loaded", data: ["package_count": offerings.count])
        } catch {
            offerings = []
            purchaseError = error
            errorHandler.logError(error, category: "Paywall")
            trackAnalytics("paywall_offerings_failed")
        }
        isLoading = false
    }

    /// Verify current subscription status
    @MainActor
    func verifySubscriptionStatus() async {
        do {
            let customerInfo = try await revenueCatService.getCustomerInfo()
            isSubscribed = !customerInfo.entitlements.active.isEmpty

            if isSubscribed {
                subscriptionStatus = "active"
            } else if !customerInfo.entitlements.all.isEmpty {
                subscriptionStatus = "expired"
            } else {
                subscriptionStatus = "none"
            }

            trackAnalytics("paywall_subscription_verified", data: [
                "has_active_entitlements": isSubscribed,
                "entitlement_count": customerInfo.entitlements.all.count
            ])
        } catch {
            isSubscribed = false
            subscriptionStatus = "unknown"
            purchaseError = error
            errorHandler.logError(error, category: "Paywall")
            trackAnalytics("paywall_subscription_verification_failed")
        }
    }

    /// Restore user subscriptions
    @MainActor
    func restoreSubscriptions() async {
        purchaseError = nil

        do {
            let customerInfo = try await revenueCatService.restorePurchases()
            isSubscribed = !customerInfo.entitlements.active.isEmpty

            if isSubscribed {
                subscriptionStatus = "restored"
            } else if !customerInfo.entitlements.all.isEmpty {
                subscriptionStatus = "expired"
            } else {
                subscriptionStatus = "none"
            }

            let synced = try await revenueCatService.syncSubscriptionStatus()
            isSubscribed = synced

            trackAnalytics("paywall_restore_success", data: [
                "has_active_entitlements": isSubscribed,
                "entitlement_count": customerInfo.entitlements.all.count
            ])
        } catch {
            purchaseError = error
            errorHandler.logError(error, category: "Paywall")
            trackAnalytics("paywall_restore_failed")
        }
    }

    /// Select a subscription plan
    /// - Parameter package: Package to select
    func selectPlan(_ package: Package) {
        selectedPackage = package
        trackAnalytics("paywall_plan_selected", data: ["package_id": package.identifier])
    }

    /// Get pricing information for a package
    /// - Parameter package: Package to get pricing for
    /// - Returns: Formatted price string
    func getPricingDisplay(for package: Package) -> String {
        let storeProduct = package.storeProduct
        let priceString = storeProduct.localizedPriceString

        let period: String
        if let subscriptionPeriod = storeProduct.subscriptionPeriod {
            switch subscriptionPeriod.unit {
            case .day:
                period = subscriptionPeriod.value == 1 ? "/day" : "/\(subscriptionPeriod.value) days"
            case .week:
                period = subscriptionPeriod.value == 1 ? "/week" : "/\(subscriptionPeriod.value) weeks"
            case .month:
                period = subscriptionPeriod.value == 1 ? "/month" : "/\(subscriptionPeriod.value) months"
            case .year:
                period = subscriptionPeriod.value == 1 ? "/year" : "/\(subscriptionPeriod.value) years"
            @unknown default:
                period = ""
            }
        } else {
            period = ""
        }

        return "\(priceString)\(period)"
    }

    /// Apply promotional code
    /// - Parameter code: Promotional code to apply
    @MainActor
    func applyPromotionalCode(_ code: String) async {
        promotionalCode = code
        isPromotionalCodeValid = !code.isEmpty && code.count >= 3

        trackAnalytics("paywall_promo_code_applied", data: [
            "code": code,
            "valid": isPromotionalCodeValid,
            "code_length": code.count
        ])
    }

    /// Handle subscription purchase flow
    /// - Parameter package: Package to purchase
    @MainActor
    func purchaseSubscription(package: Package) async {
        await purchaseSubscription(package: package, promoCode: nil)
    }

    /// Purchase subscription with promotional code
    /// - Parameter package: Package to purchase
    /// - Parameter promoCode: Optional promotional code
    @MainActor
    func purchaseSubscription(package: Package, promoCode: String? = nil) async {
        guard !isPurchasing else { return }

        isPurchasing = true
        purchaseError = nil

        if let code = promoCode {
            promotionalCode = code
        }

        do {
            let customerInfo = try await revenueCatService.purchase(package: package)
            _ = customerInfo

            let synced = try await revenueCatService.syncSubscriptionStatus()
            isSubscribed = synced
            subscriptionStatus = synced ? "active" : "inactive"

            trackAnalytics("paywall_purchase_success", data: [
                "package_id": package.identifier,
                "promo_code_used": promoCode != nil,
                "promo_code": promoCode ?? ""
            ])
            onPurchase?()
        } catch {
            purchaseError = error
            errorHandler.logError(error, category: "Paywall")
            trackAnalytics("paywall_purchase_failed", data: [
                "package_id": package.identifier,
                "promo_code_used": promoCode != nil,
                "error": error.localizedDescription
            ])
        }
        isPurchasing = false
    }

    /// Load paywall configuration
    @MainActor
    func loadPaywall() async {
        do {
            _ = try await revenueCatService.loadPaywall()
            paywallLoaded = true
            trackAnalytics("paywall_loaded")
        } catch {
            errorHandler.logError(error, category: "Paywall")
            paywallLoaded = false
            trackAnalytics("paywall_load_failed")
        }
    }

    private func trackAnalytics(_ event: String, data: [String: Any] = [:]) {
        analytics.logEvent(event, properties: data)
    }

    func getAnalyticsEvents() -> [String] {
        return []
    }
}