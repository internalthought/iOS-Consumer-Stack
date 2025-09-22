import Foundation
import Testing
@testable import app_template

/// Mock RevenueCat service for testing
class MockRevenueCatService: RevenueCatServiceProtocol {
    var shouldReturnActive = false
    var shouldThrowError = false

    func isSubscriptionActive() async -> Bool {
        if shouldThrowError {
            // Note: This would throw in real implementation, but for simplicity we'll return false
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

struct LibraryViewModelTests {

    @Test func testInit() {
        // Given
        let mockService = MockRevenueCatService()

        // When
        let viewModel = LibraryViewModel(revenueCatService: mockService)

        // Then
        #expect(!viewModel.premiumFeaturesAvailable)
        #expect(!viewModel.isLoading)
        #expect(viewModel.libraryItems.count == 3) // Placeholder data
    }

    @Test func testCheckSubscriptionActive() async throws {
        // Given
        let mockService = MockRevenueCatService()
        mockService.shouldReturnActive = true
        let viewModel = LibraryViewModel(revenueCatService: mockService)

        // When
        await viewModel.checkSubscription()

        // Then
        #expect(viewModel.premiumFeaturesAvailable)
        #expect(!viewModel.isLoading)
    }

    @Test func testCheckSubscriptionInactive() async throws {
        // Given
        let mockService = MockRevenueCatService()
        mockService.shouldReturnActive = false
        let viewModel = LibraryViewModel(revenueCatService: mockService)

        // When
        await viewModel.checkSubscription()

        // Then
        #expect(!viewModel.premiumFeaturesAvailable)
        #expect(!viewModel.isLoading)
    }

    @Test func testCheckSubscriptionError() async throws {
        // Given
        let mockService = MockRevenueCatService()
        mockService.shouldThrowError = true
        let viewModel = LibraryViewModel(revenueCatService: mockService)

        // When
        await viewModel.checkSubscription()

        // Then
        #expect(!viewModel.premiumFeaturesAvailable) // Should default to false on error
        #expect(!viewModel.isLoading)
    }

    @Test func testAddItem() {
        // Given
        let mockService = MockRevenueCatService()
        let viewModel = LibraryViewModel(revenueCatService: mockService)
        let initialCount = viewModel.libraryItems.count
        let newItem = LibraryItem(title: "New Test Item", description: "Test description")

        // When
        viewModel.addItem(newItem)

        // Then
        #expect(viewModel.libraryItems.count == initialCount + 1)
        #expect(viewModel.libraryItems.last?.title == "New Test Item")
    }

    @Test func testRemoveItem() {
        // Given
        let mockService = MockRevenueCatService()
        let viewModel = LibraryViewModel(revenueCatService: mockService)
        let itemToRemove = viewModel.libraryItems.first!
        let initialCount = viewModel.libraryItems.count

        // When
        viewModel.removeItem(itemToRemove)

        // Then
        #expect(viewModel.libraryItems.count == initialCount - 1)
        #expect(!viewModel.libraryItems.contains(where: { $0.id == itemToRemove.id }))
    }

    @Test func testRemoveNonExistentItem() {
        // Given
        let mockService = MockRevenueCatService()
        let viewModel = LibraryViewModel(revenueCatService: mockService)
        let nonExistentItem = LibraryItem(title: "Non-existent", description: "Not in list")
        let initialCount = viewModel.libraryItems.count

        // When
        viewModel.removeItem(nonExistentItem)

        // Then
        #expect(viewModel.libraryItems.count == initialCount) // Should remain unchanged
    }

    @Test func testLoadingStateDuringSubscriptionCheck() async throws {
        // Given
        let mockService = MockRevenueCatService()
        mockService.shouldReturnActive = true
        let viewModel = LibraryViewModel(revenueCatService: mockService)

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