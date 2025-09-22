import Foundation
import Testing
@testable import app_template

/// Mock RevenueCatService for testing paywall operations
class MockRevenueCatServiceForPaywall: RevenueCatServiceProtocol {
    var offerings: [String] = []
    var shouldThrowOfferingsError = false
    var shouldThrowPurchaseError = false
    var shouldThrowCustomerInfoError = false
    var shouldThrowRestoreError = false
    var shouldThrowLoadPaywallError = false
    var isActive = false
    var purchaseReturnValue: Any = [:]
    var customerInfoReturnValue: Any = [:]
    var restoreReturnValue: Any = [:]
    var calledMethods: [String] = []

    func fetchOfferings() async throws -> Any {
        calledMethods.append("fetchOfferings")
        if shouldThrowOfferingsError {
            throw NSError(domain: "RevenueCat", code: 1, userInfo: nil)
        }
        return offerings
    }

    func purchase(package: Any) async throws -> Any {
        calledMethods.append("purchase")
        if shouldThrowPurchaseError {
            throw NSError(domain: "RevenueCat", code: 2, userInfo: nil)
        }
        return purchaseReturnValue
    }

    func getCustomerInfo() async throws -> Any {
        calledMethods.append("getCustomerInfo")
        if shouldThrowCustomerInfoError {
            throw NSError(domain: "RevenueCat", code: 3, userInfo: nil)
        }
        return customerInfoReturnValue
    }

    func restorePurchases() async throws -> Any {
        calledMethods.append("restorePurchases")
        if shouldThrowRestoreError {
            throw NSError(domain: "RevenueCat", code: 4, userInfo: nil)
        }
        return restoreReturnValue
    }

    func isSubscriptionActive() async -> Bool {
        calledMethods.append("isSubscriptionActive")
        return isActive
    }

    func linkPurchaser(with identifier: String) async throws {
        calledMethods.append("linkPurchaser")
    }

    func configurePurchaserIdentification() async {
        calledMethods.append("configurePurchaserIdentification")
    }

    func loadPaywall() async -> Any {
        calledMethods.append("loadPaywall")
        if shouldThrowLoadPaywallError {
            throw NSError(domain: "RevenueCat", code: 5, userInfo: nil) as Error
        }
        return [:]
    }

    func renderPaywall(for locale: Locale) async -> Any {
        calledMethods.append("renderPaywall")
        return [:]
    }

    func getOptimizedPaywall() async -> Any {
        calledMethods.append("getOptimizedPaywall")
        return [:]
    }

    func loadPaywallWithFallback() async -> Any {
        calledMethods.append("loadPaywallWithFallback")
        return [:]
    }
}

/// Mock ErrorHandler for testing
class MockErrorHandlerForPaywall: ErrorHandlerProtocol {
    var loggedErrors: [(error: Error, category: String)] = []

    func logError(_ error: Error, category: String) {
        loggedErrors.append((error, category))
    }
}

struct PaywallViewModelTests {

    @Test func testInit() {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()

        // When
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // Then
        #expect(viewModel.offerings.isEmpty)
        #expect(viewModel.selectedPackage == nil)
        #expect(!viewModel.isLoading)
        #expect(!viewModel.isPurchasing)
        #expect(viewModel.purchaseError == nil)
        #expect(viewModel.subscriptionStatus == nil)
        #expect(!viewModel.isSubscribed)
        #expect(viewModel.promotionalCode.isEmpty)
        #expect(!viewModel.isPromotionalCodeValid)
        #expect(!viewModel.paywallLoaded)
    }

    @Test func testLoadOfferingsSuccess() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        mockService.offerings = ["monthly-plan", "yearly-plan"]
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // When
        await viewModel.loadOfferings()

        // Then
        #expect(viewModel.offerings == ["monthly-plan", "yearly-plan"])
        #expect(!viewModel.isLoading)
        #expect(viewModel.purchaseError == nil)
        #expect(mockService.calledMethods.contains("fetchOfferings"))
        #expect(viewModel.getAnalyticsEvents().contains("paywall_offerings_loaded"))
    }

    @Test func testLoadOfferingsFailure() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        mockService.shouldThrowOfferingsError = true
        let mockErrorHandler = MockErrorHandlerForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService, errorHandler: mockErrorHandler)

        // When
        await viewModel.loadOfferings()

        // Then
        #expect(viewModel.offerings.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.purchaseError != nil)
        #expect(!mockErrorHandler.loggedErrors.isEmpty)
        #expect(mockErrorHandler.loggedErrors.first?.category == "Paywall")
        #expect(viewModel.getAnalyticsEvents().contains("paywall_offerings_failed"))
    }

    @Test func testPurchaseSubscriptionSuccess() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        mockService.purchaseReturnValue = ["status": "active"]
        let viewModel = PaywallViewModel(revenueCatService: mockService)
        viewModel.selectedPackage = "monthly-plan"

        // When
        await viewModel.purchaseSubscription(packageId: "monthly-plan")

        // Then
        #expect(!viewModel.isPurchasing)
        #expect(viewModel.isSubscribed)
        #expect(viewModel.subscriptionStatus == "active")
        #expect(viewModel.purchaseError == nil)
        #expect(mockService.calledMethods.contains("purchase"))
        #expect(viewModel.getAnalyticsEvents().contains("paywall_purchase_success"))
    }

    @Test func testPurchaseSubscriptionFailure() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        mockService.shouldThrowPurchaseError = true
        let mockErrorHandler = MockErrorHandlerForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService, errorHandler: mockErrorHandler)

        // When
        await viewModel.purchaseSubscription(packageId: "monthly-plan")

        // Then
        #expect(!viewModel.isPurchasing)
        #expect(!viewModel.isSubscribed)
        #expect(viewModel.purchaseError != nil)
        #expect(!mockErrorHandler.loggedErrors.isEmpty)
        #expect(viewModel.getAnalyticsEvents().contains("paywall_purchase_failed"))
    }

    @Test func testPurchaseSubscriptionConcurrent() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService)
        viewModel.isPurchasing = true

        // When
        await viewModel.purchaseSubscription(packageId: "monthly-plan")

        // Then
        #expect(!mockService.calledMethods.contains("purchase")) // Should not call purchase when already purchasing
    }

    @Test func testVerifySubscriptionStatus() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        mockService.isActive = true
        mockService.customerInfoReturnValue = ["test": "data"]
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // When
        await viewModel.verifySubscriptionStatus()

        // Then
        #expect(mockService.calledMethods.contains("getCustomerInfo"))
        #expect(mockService.calledMethods.contains("isSubscriptionActive"))
        #expect(viewModel.isSubscribed)
        #expect(viewModel.subscriptionStatus == "active")
        #expect(viewModel.purchaseError == nil)
        #expect(viewModel.getAnalyticsEvents().contains("paywall_subscription_verified"))
    }

    @Test func testVerifySubscriptionStatusFailure() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        mockService.shouldThrowCustomerInfoError = true
        let mockErrorHandler = MockErrorHandlerForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService, errorHandler: mockErrorHandler)

        // When
        await viewModel.verifySubscriptionStatus()

        // Then
        #expect(viewModel.purchaseError != nil)
        #expect(!mockErrorHandler.loggedErrors.isEmpty)
        #expect(viewModel.getAnalyticsEvents().contains("paywall_subscription_verification_failed"))
    }

    @Test func testRestoreSubscriptionsSuccess() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        mockService.isActive = true
        mockService.restoreReturnValue = ["restored": true]
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // When
        await viewModel.restoreSubscriptions()

        // Then
        #expect(mockService.calledMethods.contains("restorePurchases"))
        #expect(mockService.calledMethods.contains("isSubscriptionActive"))
        #expect(viewModel.isSubscribed)
        #expect(viewModel.subscriptionStatus == "restored")
        #expect(viewModel.purchaseError == nil)
        #expect(viewModel.getAnalyticsEvents().contains("paywall_restore_success"))
    }

    @Test func testRestoreSubscriptionsFailure() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        mockService.shouldThrowRestoreError = true
        let mockErrorHandler = MockErrorHandlerForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService, errorHandler: mockErrorHandler)

        // When
        await viewModel.restoreSubscriptions()

        // Then
        #expect(viewModel.purchaseError != nil)
        #expect(!mockErrorHandler.loggedErrors.isEmpty)
        #expect(viewModel.getAnalyticsEvents().contains("paywall_restore_failed"))
    }

    @Test func testPlanSelection() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // When
        viewModel.selectPlan("yearly-plan")

        // Then
        #expect(viewModel.selectedPackage == "yearly-plan")
        #expect(viewModel.getAnalyticsEvents().contains("paywall_plan_selected"))
    }

    @Test func testGetPricingDisplay() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // When & Then
        #expect(viewModel.getPricingDisplay(for: "monthly-plan") == "$4.99/month")
        #expect(viewModel.getPricingDisplay(for: "yearly-plan") == "$49.99/year")
        #expect(viewModel.getPricingDisplay(for: "unknown-plan") == "$0.00")
    }

    @Test func testApplyPromotionalCodeValid() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // When
        await viewModel.applyPromotionalCode("SAVE20")

        // Then
        #expect(viewModel.promotionalCode == "SAVE20")
        #expect(viewModel.isPromotionalCodeValid)
        #expect(viewModel.getAnalyticsEvents().contains(where: { $0.contains("paywall_promo_code_applied") }))
    }

    @Test func testApplyPromotionalCodeInvalid() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // When
        await viewModel.applyPromotionalCode("ABC")

        // Then
        #expect(viewModel.promotionalCode == "ABC")
        #expect(!viewModel.isPromotionalCodeValid)
        #expect(viewModel.getAnalyticsEvents().contains(where: { $0.contains("paywall_promo_code_applied") }))
    }

    @Test func testUIStateLoadingTransition() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // When
        #expect(!viewModel.isLoading)

        // Trigger loading
        let task = Task {
            await viewModel.loadOfferings()
        }
        await Task.yield() // Allow task to start

        // Then
        #expect(viewModel.isLoading)

        await task // Wait for completion
        #expect(!viewModel.isLoading)
    }

    @Test func testUIStatePurchasingTransition() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // When
        #expect(!viewModel.isPurchasing)

        // Trigger purchasing
        let task = Task {
            await viewModel.purchaseSubscription(packageId: "monthly-plan")
        }
        await Task.yield() // Allow task to start

        // Then
        #expect(viewModel.isPurchasing)

        await task // Wait for completion
        #expect(!viewModel.isPurchasing)
    }

    @Test func testLoadPaywallSuccess() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // When
        await viewModel.loadPaywall()

        // Then
        #expect(viewModel.paywallLoaded)
        #expect(mockService.calledMethods.contains("loadPaywall"))
        #expect(viewModel.getAnalyticsEvents().contains("paywall_loaded"))
    }

    @Test func testLoadPaywallFailure() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        mockService.shouldThrowLoadPaywallError = true
        let mockErrorHandler = MockErrorHandlerForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService, errorHandler: mockErrorHandler)

        // When
        await viewModel.loadPaywall()

        // Then
        #expect(!viewModel.paywallLoaded)
        #expect(viewModel.purchaseError != nil)
        #expect(!mockErrorHandler.loggedErrors.isEmpty)
        #expect(viewModel.getAnalyticsEvents().contains("paywall_load_failed"))
    }

    @Test func testAnalyticsTrackingMultipleEvents() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        mockService.isActive = true
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // When
        await viewModel.loadOfferings()
        await viewModel.verifySubscriptionStatus()
        viewModel.selectPlan("monthly-plan")
        await viewModel.purchaseSubscription(packageId: "monthly-plan")

        // Then
        let events = viewModel.getAnalyticsEvents()
        #expect(events.contains("paywall_offerings_loaded"))
        #expect(events.contains("paywall_subscription_verified"))
        #expect(events.contains("paywall_plan_selected"))
        #expect(events.contains("paywall_purchase_success"))
        #expect(events.count >= 4)
    }

    @Test func testErrorHandlingMultipleCategories() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        mockService.shouldThrowOfferingsError = true
        mockService.shouldThrowPurchaseError = true
        let mockErrorHandler = MockErrorHandlerForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService, errorHandler: mockErrorHandler)

        // When
        await viewModel.loadOfferings()

        // Then
        #expect(mockErrorHandler.loggedErrors.first?.category == "Paywall")
        #expect(mockErrorHandler.loggedErrors.first?.error.localizedDescription.contains("RevenueCat"))
    }

    @Test func testNetworkIssuesSimulation() async throws {
        // Given - Simulate network unavailability
        let mockService = MockRevenueCatServiceForPaywall()
        mockService.shouldThrowOfferingsError = true
        mockService.shouldThrowCustomerInfoError = true
        mockService.shouldThrowPurchaseError = true
        mockService.shouldThrowRestoreError = true
        let mockErrorHandler = MockErrorHandlerForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService, errorHandler: mockErrorHandler)

        // When
        await viewModel.loadOfferings()
        await viewModel.verifySubscriptionStatus()
        await viewModel.purchaseSubscription(packageId: "monthly-plan")
        await viewModel.restoreSubscriptions()

        // Then
        let errors = mockErrorHandler.loggedErrors
        #expect(errors.count == 4) // One error per operation
        #expect(errors.allSatisfy { $0.category == "Paywall" })
        #expect(viewModel.getAnalyticsEvents().contains("paywall_offerings_failed"))
        #expect(viewModel.getAnalyticsEvents().contains("paywall_subscription_verification_failed"))
        #expect(viewModel.getAnalyticsEvents().contains("paywall_purchase_failed"))
        #expect(viewModel.getAnalyticsEvents().contains("paywall_restore_failed"))
    }

    // MARK: - IAP Workflow Integration Test

    @Test func testCompleteIAPWorkflowSuccess() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        mockService.offerings = ["monthly-plan", "yearly-plan"]
        mockService.isActive = false // Start unsubscribed
        mockService.purchaseReturnValue = ["status": "completed", "packageId": "yearly-plan"]
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // When - Complete IAP workflow
        await viewModel.loadOfferings() // 1. Load offerings
        viewModel.selectPlan("yearly-plan") // 2. Select plan
        await viewModel.purchaseSubscription(packageId: "yearly-plan") // 3. Purchase
        await viewModel.verifySubscriptionStatus() // 4. Verify status

        // Then - Verify complete successful workflow
        #expect(!viewModel.offerings.isEmpty)
        #expect(viewModel.selectedPackage == "yearly-plan")
        #expect(viewModel.isSubscribed)
        #expect(viewModel.subscriptionStatus == "active")
        #expect(viewModel.purchaseError == nil)
        #expect(mockService.calledMethods.contains("fetchOfferings"))
        #expect(mockService.calledMethods.contains("purchase"))
        #expect(mockService.calledMethods.contains("getCustomerInfo"))
        #expect(mockService.calledMethods.contains("isSubscriptionActive"))
    }

    @Test func testCompleteIAPWorkflowFailure() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        mockService.shouldThrowOfferingsError = true
        let mockErrorHandler = MockErrorHandlerForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService, errorHandler: mockErrorHandler)

        // When - Attempt IAP workflow with failures
        await viewModel.loadOfferings()
        await viewModel.purchaseSubscription(packageId: "yearly-plan")

        // Then - Verify error handling throughout workflow
        #expect(viewModel.offerings.isEmpty)
        #expect(viewModel.purchaseError != nil)
        #expect(!viewModel.isSubscribed)
        #expect(mockErrorHandler.loggedErrors.count > 0)
        // Should still be able to select plan even if loading failed
        viewModel.selectPlan("monthly-plan")
        #expect(viewModel.selectedPackage == "monthly-plan")
    }

    // MARK: - Promotional Code Edge Cases

    @Test func testPromotionalCodeEdgeCases() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // Test empty code
        await viewModel.applyPromotionalCode("")
        #expect(viewModel.promotionalCode.isEmpty)
        #expect(!viewModel.isPromotionalCodeValid)

        // Test short code
        await viewModel.applyPromotionalCode("AB")
        #expect(!viewModel.isPromotionalCodeValid)

        // Test valid code
        await viewModel.applyPromotionalCode("ABCD")
        #expect(viewModel.isPromotionalCodeValid)

        // Test uppercase conversion
        await viewModel.applyPromotionalCode("save2024")
        #expect(viewModel.promotionalCode == "save2024")
        #expect(viewModel.isPromotionalCodeValid)
    }

    // MARK: - Subscription Status Edge Cases

    @Test func testSubscriptionStatusEdgeCases() async throws {
        // Given
        let mockService = MockRevenueCatServiceForPaywall()
        let viewModel = PaywallViewModel(revenueCatService: mockService)

        // Test already subscribed state
        mockService.isActive = true
        await viewModel.verifySubscriptionStatus()
        #expect(viewModel.isSubscribed)
        #expect(viewModel.subscriptionStatus == "active")

        // Test not subscribed state
        mockService.isActive = false
        await viewModel.verifySubscriptionStatus()
        #expect(!viewModel.isSubscribed)
        #expect(viewModel.subscriptionStatus == "expired")

        // Test restoration
        mockService.isActive = true
        await viewModel.restoreSubscriptions()
        #expect(viewModel.subscriptionStatus == "restored")
    }
}