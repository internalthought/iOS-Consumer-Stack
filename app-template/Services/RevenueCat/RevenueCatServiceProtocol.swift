import Foundation
import RevenueCat
import RevenueCatUI

/// Protocol defining RevenueCat service interface for IAP management
protocol RevenueCatServiceProtocol {

    /// Fetch available offerings from RevenueCat
    /// - Returns: Available offerings including packages
    func fetchOfferings() async throws -> Offerings

    /// Purchase a subscription package
    /// - Parameter package: The package to purchase
    /// - Returns: Updated customer info after purchase
    func purchase(package: Package) async throws -> CustomerInfo

    /// Get customer info including subscription status
    /// - Returns: Current customer information
    func getCustomerInfo() async throws -> CustomerInfo

    /// Restore previous purchases
    /// - Returns: Customer info after restoring purchases
    func restorePurchases() async throws -> CustomerInfo

    /// Check if user has active subscription
    /// - Returns: Whether subscription is active
    func isSubscriptionActive() async -> Bool

    /// Link purchaser info with Supabase user ID
    /// - Parameter identifier: User identifier to link
    func linkPurchaser(with identifier: String) async throws

    /// Configure automatic purchaser identification
    func configurePurchaserIdentification() async

    // MARK: - Paywall Methods

    /// Load paywall configuration
    func loadPaywall() async throws -> PaywallViewController

    /// Render paywall for specific locale
    /// - Parameter locale: Target locale for localization
    func renderPaywall(for locale: Locale) async throws -> PaywallViewController

    /// Get optimized paywall variant (A/B testing)
    func getOptimizedPaywall() async throws -> PaywallViewController

    /// Load paywall with fallback configuration
    /// - Returns: Paywall with fallback if primary fails
    func loadPaywallWithFallback() async -> PaywallViewController?

    /// Sync subscription status with Supabase backend
    /// Fetches latest subscription status from Supabase and ensures local state is consistent
    /// - Returns: Boolean indicating if subscription is active after sync
    func syncSubscriptionStatus() async throws -> Bool
}