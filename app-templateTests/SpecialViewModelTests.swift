import Foundation
import Testing
@testable import app_template

/// Mock RevenueCat service for testing SpecialViewModel
class MockRevenueCatServiceForSpecial: RevenueCatServiceProtocol {
    var shouldReturnActive = false
    var shouldThrowError = false

    func isSubscriptionActive() async -> Bool {
        if shouldThrowError {
            return false
        }
        return shouldReturnActive
    }

    func purchaseSubscription() async throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
    }

    func restorePurchases() async throws {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
    }

    func getSubscriptionStatus() async -> SubscriptionStatus {
        return shouldReturnActive ? .active : .inactive
    }
}

struct SpecialViewModelTests {

    @Test func testInit() {
        // Given
        let mockService = MockRevenueCatServiceForSpecial()

        // When
        let viewModel = SpecialViewModel(revenueCatService: mockService)

        // Then
        #expect(!viewModel.premiumFeaturesAvailable)
        #expect(!viewModel.isLoading)
        #expect(viewModel.specialFeatures.count == 4) // All features loaded initially
    }

    @Test func testCheckSubscriptionActive() async throws {
        // Given
        let mockService = MockRevenueCatServiceForSpecial()
        mockService.shouldReturnActive = true
        let viewModel = SpecialViewModel(revenueCatService: mockService)

        // When
        await viewModel.checkSubscription()

        // Then
        #expect(viewModel.premiumFeaturesAvailable)
        #expect(!viewModel.isLoading)
        #expect(viewModel.specialFeatures.count == 4) // All features should be available
        #expect(viewModel.specialFeatures.contains(where: { $0.isPremium })) // Should include premium features
    }

    @Test func testCheckSubscriptionInactive() async throws {
        // Given
        let mockService = MockRevenueCatServiceForSpecial()
        mockService.shouldReturnActive = false
        let viewModel = SpecialViewModel(revenueCatService: mockService)

        // When
        await viewModel.checkSubscription()

        // Then
        #expect(!viewModel.premiumFeaturesAvailable)
        #expect(!viewModel.isLoading)
        #expect(viewModel.specialFeatures.count == 1) // Only non-premium features should remain
        #expect(!viewModel.specialFeatures.contains(where: { $0.isPremium })) // Should not include premium features
    }

    @Test func testCheckSubscriptionError() async throws {
        // Given
        let mockService = MockRevenueCatServiceForSpecial()
        mockService.shouldThrowError = true
        let viewModel = SpecialViewModel(revenueCatService: mockService)

        // When
        await viewModel.checkSubscription()

        // Then
        #expect(!viewModel.premiumFeaturesAvailable)
        #expect(!viewModel.isLoading)
        #expect(viewModel.specialFeatures.count == 1) // Should filter to non-premium on error
        #expect(!viewModel.specialFeatures.contains(where: { $0.isPremium }))
    }

    @Test func testPerformSpecialAction() {
        // Given
        let mockService = MockRevenueCatServiceForSpecial()
        let viewModel = SpecialViewModel(revenueCatService: mockService)
        let feature = viewModel.specialFeatures.first!

        // When
        viewModel.performSpecialAction(for: feature)

        // Then
        // This is a placeholder method, so we just verify it doesn't crash
        #expect(true) // Method executed without error
    }

    @Test func testSpecialFeaturesInitialization() {
        // Given
        let mockService = MockRevenueCatServiceForSpecial()
        let viewModel = SpecialViewModel(revenueCatService: mockService)

        // Then
        #expect(viewModel.specialFeatures.count == 4)

        // Check specific features
        let premiumFeatures = viewModel.specialFeatures.filter { $0.isPremium }
        let freeFeatures = viewModel.specialFeatures.filter { !$0.isPremium }

        #expect(premiumFeatures.count == 3) // Premium Features, Exclusive Content, VIP Support
        #expect(freeFeatures.count == 1) // Special Offers

        // Check specific feature properties
        let premiumFeature = viewModel.specialFeatures.first { $0.title == "Premium Features" }
        #expect(premiumFeature?.isPremium == true)
        #expect(premiumFeature?.iconName == "star.fill")

        let freeFeature = viewModel.specialFeatures.first { $0.title == "Special Offers" }
        #expect(freeFeature?.isPremium == false)
        #expect(freeFeature?.iconName == "tag.fill")
    }

    @Test func testLoadingStateDuringSubscriptionCheck() async throws {
        // Given
        let mockService = MockRevenueCatServiceForSpecial()
        mockService.shouldReturnActive = true
        let viewModel = SpecialViewModel(revenueCatService: mockService)

        // When - Check that loading is set during async operation
        let checkTask = Task {
            await viewModel.checkSubscription()
        }

        // Give a moment for the task to start
        try await Task.sleep(nanoseconds: 100_000) // 0.1ms

        // Then - Loading should be true during operation
        #expect(viewModel.isLoading)

        // Wait for completion
        await checkTask.value
        #expect(!viewModel.isLoading)
    }
}