import Foundation
import RevenueCat
import RevenueCatUI
import os

/// Service for handling RevenueCat IAP operations and subscription management
class RevenueCatService: NSObject, RevenueCatServiceProtocol {
    private let serviceLocator: ServiceLocator
    private let errorHandler: ErrorHandlerProtocol
    private let supabaseService: SupabaseServiceProtocol

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app-template", category: "RevenueCat")

    // Track purchaser info
    private var purchaserID: String = UUID().uuidString

    // Caching for subscription status sync
    private var lastSyncTime: Date?
    private var cachedSubscriptionStatus: Bool?
    private let syncCacheDuration: TimeInterval = 300 // 5 minutes cache

    private let signposter = OSSignposter(subsystem: Bundle.main.bundleIdentifier ?? "app-template", category: "IAP")

    /// Initialize RevenueCat service with dependencies
    /// - Parameter serviceLocator: Dependency injection container
    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        self.errorHandler = serviceLocator.errorHandler
        self.supabaseService = serviceLocator.supabaseService
        super.init()
        configureRevenueCat(apiKey: Configuration.revenueCatAPIKey)
        Task { await self.configurePurchaserIdentification() }
    }

    private static var hasConfiguredSDK = false

    /// Configure RevenueCat SDK with API key
    private func configureRevenueCat(apiKey: String) {
        guard !apiKey.isEmpty else {
            errorHandler.logError(NSError(domain: "RevenueCat", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid API key"]), category: "IAP")
            logger.error("RevenueCat API key is empty; skipping configuration")
            return
        }

        if !Self.hasConfiguredSDK {
            logger.info("Configuring RevenueCat SDK")
            Purchases.configure(withAPIKey: apiKey)
            Purchases.logLevel = .debug
            Self.hasConfiguredSDK = true
        } else {
            logger.warning("RevenueCat SDK already configured; skipping reconfiguration")
        }

        Purchases.shared.delegate = self
        logger.info("RevenueCat delegate set")
    }

    // MARK: - IAP Operations

    func fetchOfferings() async throws -> Offerings {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("fetchOfferings", id: id)
        do {
            let result = try await Purchases.shared.offerings()
            signposter.endInterval("fetchOfferings", state)
            return result
        } catch {
            signposter.endInterval("fetchOfferings", state)
            errorHandler.logError(error, category: "IAP")
            throw error
        }
    }

    func purchase(package: Package) async throws -> CustomerInfo {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("purchase", id: id)
        do {
            let result = try await Purchases.shared.purchase(package: package)
            signposter.endInterval("purchase", state)

            let info = result.customerInfo
            let entitlementActive: Bool
            if let entitlementID = Configuration.revenueCatEntitlementID, !entitlementID.isEmpty {
                entitlementActive = info.entitlements[entitlementID]?.isActive == true
                logger.info("Purchase result: entitlement '\(entitlementID, privacy: .public)' active=\(entitlementActive, privacy: .public)")
            } else {
                entitlementActive = !info.entitlements.active.isEmpty
                logger.info("Purchase result: active entitlements count=\(info.entitlements.active.count, privacy: .public) active=\(entitlementActive, privacy: .public)")
            }
            cachedSubscriptionStatus = entitlementActive
            lastSyncTime = Date()

            if let currentUser = try? await supabaseService.getCurrentUser(),
               let userId = currentUser.userId {
                logger.info("Syncing subscription to backend for user \(userId, privacy: .private)")
                try? await supabaseService.syncSubscriptionStateFromClient(
                    isPremium: entitlementActive,
                    subscriptionStatus: entitlementActive ? "active" : "free"
                )
            } else {
                logger.warning("Skipping backend sync: no authenticated Supabase user")
            }

            return info
        } catch {
            signposter.endInterval("purchase", state)
            errorHandler.logError(error, category: "IAP")
            throw error
        }
    }

    func getCustomerInfo() async throws -> CustomerInfo {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("getCustomerInfo", id: id)
        do {
            let info = try await Purchases.shared.customerInfo()
            signposter.endInterval("getCustomerInfo", state)
            return info
        } catch {
            signposter.endInterval("getCustomerInfo", state)
            errorHandler.logError(error, category: "IAP")
            throw error
        }
    }

    func restorePurchases() async throws -> CustomerInfo {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("restorePurchases", id: id)
        do {
            let info = try await Purchases.shared.restorePurchases()
            signposter.endInterval("restorePurchases", state)
            return info
        } catch {
            signposter.endInterval("restorePurchases", state)
            errorHandler.logError(error, category: "IAP")
            throw error
        }
    }

    func isSubscriptionActive() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()

            if let entitlementID = Configuration.revenueCatEntitlementID, !entitlementID.isEmpty {
                let active = customerInfo.entitlements[entitlementID]?.isActive == true
                logger.info("isSubscriptionActive: entitlement '\(entitlementID, privacy: .public)' active=\(active, privacy: .public)")
                return active
            } else {
                let count = customerInfo.entitlements.active.count
                logger.info("isSubscriptionActive: active entitlements count=\(count, privacy: .public)")
                return count > 0
            }
        } catch {
            errorHandler.logError(error, category: "IAP")
            logger.error("isSubscriptionActive error: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    // MARK: - Purchaser Identification

    func linkPurchaser(with identifier: String) async throws {
        do {
            logger.info("Logging in RevenueCat with appUserID \(identifier, privacy: .private)")
            _ = try await Purchases.shared.logIn(identifier)
            try await supabaseService.linkPurchaser(withID: identifier)
            self.purchaserID = identifier
            logger.info("RevenueCat logIn and backend link complete for \(identifier, privacy: .private)")
        } catch {
            errorHandler.logError(error, category: "IAP")
            logger.error("linkPurchaser error: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func configurePurchaserIdentification() async {
        if let currentUser = try? await supabaseService.getCurrentUser(),
           let userId = currentUser.userId {
            do {
                logger.info("configurePurchaserIdentification logging in as \(userId, privacy: .private)")
                _ = try await Purchases.shared.logIn(userId)
                self.purchaserID = userId
                let isActive = await self.isSubscriptionActive()
                logger.info("configurePurchaserIdentification: isActive=\(isActive, privacy: .public). Syncing to backend.")
                try? await supabaseService.syncSubscriptionStateFromClient(
                    isPremium: isActive,
                    subscriptionStatus: isActive ? "active" : "free"
                )
            } catch {
                errorHandler.logError(error, category: "IAP")
                logger.error("configurePurchaserIdentification error: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            logger.warning("configurePurchaserIdentification: no Supabase user; leaving RC anonymous")
        }
    }

    // MARK: - Paywall Methods

    func loadPaywall() async throws -> PaywallViewController {
        return PaywallViewController()
    }

    func renderPaywall(for locale: Locale) async throws -> PaywallViewController {
        return PaywallViewController()
    }

    func getOptimizedPaywall() async throws -> PaywallViewController {
        return PaywallViewController()
    }

    func loadPaywallWithFallback() async -> PaywallViewController? {
        return PaywallViewController()
    }

    // MARK: - Subscription Sync

    func syncSubscriptionStatus() async throws -> Bool {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("syncSubscriptionStatus", id: id)
        defer { signposter.endInterval("syncSubscriptionStatus", state) }

        let revenueCatStatus = await isSubscriptionActive()
        logger.info("syncSubscriptionStatus: RC says active=\(revenueCatStatus, privacy: .public)")

        if let currentUser = try? await supabaseService.getCurrentUser(),
           let userId = currentUser.userId,
           !userId.isEmpty {
            do {
                logger.info("syncSubscriptionStatus: pushing status to backend for user \(userId, privacy: .private)")
                try await supabaseService.syncSubscriptionStateFromClient(
                    isPremium: revenueCatStatus,
                    subscriptionStatus: revenueCatStatus ? "active" : "free"
                )
            } catch {
                errorHandler.logError(error, category: "SubscriptionSync")
                logger.error("syncSubscriptionStatus backend push error: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            logger.warning("syncSubscriptionStatus: no Supabase user; skipping backend push")
        }

        lastSyncTime = Date()
        cachedSubscriptionStatus = revenueCatStatus
        return revenueCatStatus
    }
}

extension RevenueCatService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        let entitlementActive: Bool
        if let entitlementID = Configuration.revenueCatEntitlementID, !entitlementID.isEmpty {
            entitlementActive = customerInfo.entitlements[entitlementID]?.isActive == true
            logger.info("PurchasesDelegate update: entitlement '\(entitlementID, privacy: .public)' active=\(entitlementActive, privacy: .public)")
        } else {
            let count = customerInfo.entitlements.active.count
            entitlementActive = count > 0
            logger.info("PurchasesDelegate update: active entitlements count=\(count, privacy: .public)")
        }

        cachedSubscriptionStatus = entitlementActive
        lastSyncTime = Date()

        Task {
            if let currentUser = try? await supabaseService.getCurrentUser(),
               let userId = currentUser.userId {
                logger.info("PurchasesDelegate: pushing state to backend for user \(userId, privacy: .private)")
                try? await supabaseService.syncSubscriptionStateFromClient(
                    isPremium: entitlementActive,
                    subscriptionStatus: entitlementActive ? "active" : "free"
                )
            } else {
                logger.warning("PurchasesDelegate: no Supabase user; skipping backend push")
            }
        }
    }
}