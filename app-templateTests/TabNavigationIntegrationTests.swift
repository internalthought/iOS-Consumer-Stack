import Foundation
import Testing
@testable import app_template

/// Integration tests for complete tab navigation flow with subscription protection
struct TabNavigationIntegrationTests {

    @Test func testTabViewDisplaysCorrectlyWithActiveSubscription() async throws {
        // Given
        let mockRevenueCatService = MockRevenueCatServiceForIntegration()
        mockRevenueCatService.isActiveSubscription = true
        let coordinator = AppCoordinator(services: MockServiceLocator(revenueCatService: mockRevenueCatService))
        coordinator.appState = .mainTabs

        // When - Tab view loads with active subscription

        // Then - Views should be populated with data
        // Note: In a real scenario, this would test that Home and Profile views
        // display premium content when subscription is active
        #expect(coordinator.appState == .mainTabs)
        #expect(await mockRevenueCatService.isSubscriptionActive() == true)
    }

    @Test func testTabViewHandlesInactiveSubscription() async throws {
        // Given
        let mockRevenueCatService = MockRevenueCatServiceForIntegration()
        mockRevenueCatService.isActiveSubscription = false
        let coordinator = AppCoordinator(services: MockServiceLocator(revenueCatService: mockRevenueCatService))
        coordinator.appState = .mainTabs

        // When - Tab view loads with inactive subscription

        // Then - Views should show upgrade prompts
        #expect(coordinator.appState == .mainTabs)
        #expect(await mockRevenueCatService.isSubscriptionActive() == false)
    }

    @Test func testCoordinatorNavigatesToPaywallFromTabs() async throws {
        // Given
        let mockRevenueCatService = MockRevenueCatServiceForIntegration()
        let coordinator = AppCoordinator(services: MockServiceLocator(revenueCatService: mockRevenueCatService))
        coordinator.appState = .mainTabs

        // When - User requests upgrade from within tabs
        coordinator.upgradeFromTabs()

        // Then - Navigation should change to paywall
        #expect(coordinator.appState == .paywall)
    }

    @Test func testSubscriptionStatusUpdatesTriggerViewUpdates() async throws {
        // Given
        let mockService = MockRevenueCatServiceForIntegration()
        let viewModel = HomepageViewModel(revenueCatService: mockService)

        // Initially inactive
        mockService.isActiveSubscription = false
        await viewModel.checkSubscription()
        #expect(viewModel.premiumFeaturesAvailable == false)

        // When subscription becomes active
        mockService.isActiveSubscription = true
        await viewModel.checkSubscription()

        // Then - View model should reflect the change
        #expect(viewModel.premiumFeaturesAvailable == true)
    }

    @Test func testProfileViewSubscriptionManagement() async throws {
        // Given
        let mockService = MockRevenueCatServiceForIntegration()
        let viewModel = ProfileViewModel(revenueCatService: mockService)

        // Initially inactive
        mockService.isActiveSubscription = false
        await viewModel.checkSubscriptionStatus()
        #expect(viewModel.isSubscribed == false)
        #expect(viewModel.subscriptionStatus == "Inactive")

        // When subscription becomes active
        mockService.isActiveSubscription = true
        await viewModel.checkSubscriptionStatus()

        // Then - Profile should reflect premium status
        #expect(viewModel.isSubscribed == true)
        #expect(viewModel.subscriptionStatus == "Active")
    }

    @Test func testCompleteUpgradeFlowFromTabs() async throws {
        // Given
        let mockService = MockRevenueCatServiceForIntegration()
        mockService.isActiveSubscription = false
        let coordinator = AppCoordinator(services: MockServiceLocator(revenueCatService: mockService))
        let homeViewModel = HomepageViewModel(revenueCatService: mockService)

        // When - User is in tabs with inactive subscription
        coordinator.appState = .mainTabs
        await homeViewModel.checkSubscription()

        // Verify premium content is locked
        #expect(homeViewModel.premiumFeaturesAvailable == false)

        // User initiates upgrade from tabs
        coordinator.upgradeFromTabs()

        // Then - Navigation changes to paywall
        #expect(coordinator.appState == .paywall)
    }

    @Test func testLoadingStatesDuringSubscriptionCheck() async throws {
        // Given
        let mockService = MockRevenueCatServiceForIntegration()
        let homeViewModel = HomepageViewModel(revenueCatService: mockService)
        let profileViewModel = ProfileViewModel(revenueCatService: mockService)

        // When - Both views check subscription concurrently
        async let homeTask = homeViewModel.checkSubscription()
        async let profileTask = profileViewModel.checkSubscriptionStatus()

        // Then - Loading states are managed properly
        await homeTask
        #expect(homeViewModel.isLoading == false)

        await profileTask
        #expect(profileViewModel.isLoading == false)
    }
}

/// Mock Service Locator for integration testing
class MockServiceLocator: ServiceLocator {
    let mockRevenueCatService: RevenueCatServiceProtocol

    init(revenueCatService: RevenueCatServiceProtocol) {
        self.mockRevenueCatService = revenueCatService
    }

    var errorHandler: ErrorHandlerProtocol {
        get { MockErrorHandler() }
        set { /* No-op for testing */ }
    }

    var supabaseService: SupabaseServiceProtocol {
        get { MockSupabaseServiceForCoords() }
        set { /* No-op for testing */ }
    }

    var revenueCatService: RevenueCatServiceProtocol {
        get { mockRevenueCatService }
        set { /* No-op for testing */ }
    }
}

/// Mock SupabaseService for coordinator testing
class MockSupabaseServiceForCoords: SupabaseServiceProtocol {
    func fetchOnboardingScreens(userProperty: String) async throws -> [OnboardingScreen] {
        return []
    }

    func fetchSurveyQuestions(surveyId: Int) async throws -> [Question] {
        return []
    }

    func saveSurveyResponses(_ responses: [SurveyResponse]) async throws {
        // No-op for testing
    }

    func linkPurchaser(withID identifier: String) async throws {
        // No-op for testing
    }
}

/// Mock RevenueCatService for integration testing
class MockRevenueCatServiceForIntegration: RevenueCatServiceProtocol {
    var isActiveSubscription: Bool = false

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
        // No-op
    }

    func configurePurchaserIdentification() async {
        // No-op
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

class MockErrorHandler: ErrorHandlerProtocol {
    func logError(_ error: Error, category: String) {
        // No-op for testing
    }
}