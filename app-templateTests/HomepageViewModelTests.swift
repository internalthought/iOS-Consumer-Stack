import Foundation
import Testing
@testable import app_template

/// Mock RevenueCatService for testing subscription logic
class MockRevenueCatService: RevenueCatServiceProtocol {
    var isActiveSubscription = false

    func fetchOfferings() async throws -> Any {
        return [:]
    }

    func purchase(package: Any) async throws -> Any {
        return [:]
    }

    func getCustomerInfo() async throws -> Any {
        return [:]
    }

    func restorePurchases() async throws -> Any {
        return [:]
    }

    func isSubscriptionActive() async -> Bool {
        return isActiveSubscription
    }

    func linkPurchaser(with identifier: String) async throws {
        // Mock implementation
    }

    func configurePurchaserIdentification() async {
        // Mock implementation
    }

    func loadPaywall() async -> Any {
        return [:]
    }

    func renderPaywall(for locale: Locale) async -> Any {
        return [:]
    }

    func getOptimizedPaywall() async -> Any {
        return [:]
    }

    func loadPaywallWithFallback() async -> Any {
        return [:]
    }
}

struct HomepageViewModelTests {

    @Test func testInit() {
        // Given
        let mockRevenueCatService = MockRevenueCatService()

        // When
        let viewModel = HomepageViewModel(revenueCatService: mockRevenueCatService)

        // Then
        #expect(viewModel.isLoading == false)
        #expect(viewModel.premiumFeaturesAvailable == false)
    }

    @Test func testCheckSubscriptionActive() async {
        // Given
        let mockRevenueCatService = MockRevenueCatService()
        mockRevenueCatService.isActiveSubscription = true
        let viewModel = HomepageViewModel(revenueCatService: mockRevenueCatService)

        // When
        await viewModel.checkSubscription()

        // Then
        #expect(viewModel.premiumFeaturesAvailable == true)
        #expect(viewModel.isLoading == false)
    }

    @Test func testCheckSubscriptionInactive() async {
        // Given
        let mockRevenueCatService = MockRevenueCatService()
        mockRevenueCatService.isActiveSubscription = false
        let viewModel = HomepageViewModel(revenueCatService: mockRevenueCatService)

        // When
        await viewModel.checkSubscription()

        // Then
        #expect(viewModel.premiumFeaturesAvailable == false)
        #expect(viewModel.isLoading == false)
    }

    @Test func testLoadingStateDuringSubscriptionCheck() async {
        // Given
        let mockRevenueCatService = MockRevenueCatService()
        mockRevenueCatService.isActiveSubscription = false
        let viewModel = HomepageViewModel(revenueCatService: mockRevenueCatService)

        // When - simulate concurrent access
        async let task1 = viewModel.checkSubscription()

        // Then - should set loading during operation
        #expect(viewModel.isLoading == true)

        await task1
        #expect(viewModel.isLoading == false)
    }
}