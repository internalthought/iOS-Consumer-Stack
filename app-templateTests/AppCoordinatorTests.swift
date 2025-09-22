import Testing
import SwiftUI
@testable import app_template

// Mock Service Locator for testing
class MockServiceLocator: ServiceLocator {
    var supabaseService: SupabaseServiceProtocol
    var authenticationService: AuthenticationServiceProtocol
    var revenueCatService: RevenueCatServiceProtocol
    var errorHandler: ErrorHandlerProtocol

    init(
        supabaseService: SupabaseServiceProtocol = MockSupabaseService(),
        authenticationService: AuthenticationServiceProtocol = MockAuthenticationService(),
        revenueCatService: RevenueCatServiceProtocol = MockRevenueCatService(),
        errorHandler: ErrorHandlerProtocol = MockErrorHandler()
    ) {
        self.supabaseService = supabaseService
        self.authenticationService = authenticationService
        self.revenueCatService = revenueCatService
        self.errorHandler = errorHandler
    }
}

// Mock services for testing
class MockSupabaseService: SupabaseServiceProtocol {
    func saveUserProfile(_ profile: UserProfile) async throws {}
    func getUserProfile(userId: String) async throws -> UserProfile? { nil }
    func saveSurveyResponse(_ response: SurveyResponse) async throws {}
    func getSurveyResponses(userId: String) async throws -> [SurveyResponse] { [] }
}

class MockAuthenticationService: AuthenticationServiceProtocol {
    func signInWithApple() async throws -> String { "mock-user-id" }
    func signOut() async throws {}
    func getCurrentUserId() -> String? { "mock-user-id" }
}

class MockRevenueCatService: RevenueCatServiceProtocol {
    var shouldReturnActiveSubscription = true

    func isSubscriptionActive() async -> Bool {
        shouldReturnActiveSubscription
    }

    func purchaseSubscription() async throws {}
    func restorePurchases() async throws {}
}

class MockErrorHandler: ErrorHandlerProtocol {
    func logError(_ error: Error, category: String) {}
}

struct AppCoordinatorTests {

    @Test func testInitializationWithServices() {
        // Given
        let mockServices = MockServiceLocator()

        // When
        let coordinator = AppCoordinator(services: mockServices)

        // Then
        #expect(coordinator.services.supabaseService is MockSupabaseService)
        #expect(coordinator.services.authenticationService is MockAuthenticationService)
        #expect(coordinator.services.revenueCatService is MockRevenueCatService)
        #expect(coordinator.appState == .onboarding) // Default state
    }

    @Test func testValueScreensToSignInTransition() {
        // Given
        let coordinator = AppCoordinator(services: MockServiceLocator())

        // When
        coordinator.startValueScreens()

        // Then
        #expect(coordinator.appState == .valueScreens)

        // When transitioning to sign in
        coordinator.startSignIn()

        // Then
        #expect(coordinator.appState == .signIn)
    }

    @Test func testSignInToOnboardingTransition() {
        // Given
        let coordinator = AppCoordinator(services: MockServiceLocator())
        coordinator.appState = .signIn

        // When
        coordinator.startOnboarding()

        // Then
        #expect(coordinator.appState == .onboarding)
    }

    @Test func testOnboardingToSurveyTransition() {
        // Given
        let coordinator = AppCoordinator(services: MockServiceLocator())
        coordinator.appState = .onboarding

        // When
        coordinator.startSurvey()

        // Then
        #expect(coordinator.appState == .survey)
    }

    @Test func testSurveyToPaywallTransition() {
        // Given
        let coordinator = AppCoordinator(services: MockServiceLocator())
        coordinator.appState = .survey

        // When
        coordinator.startPaywall()

        // Then
        #expect(coordinator.appState == .paywall)
    }

    @Test func testPaywallToMainTabsTransitionWithActiveSubscription() async throws {
        // Given
        let mockServices = MockServiceLocator()
        (mockServices.revenueCatService as! MockRevenueCatService).shouldReturnActiveSubscription = true
        let coordinator = AppCoordinator(services: mockServices)
        coordinator.appState = .paywall

        // When
        await coordinator.startMainTabs()

        // Then
        #expect(coordinator.appState == .mainTabs)
        #expect(coordinator.isVerifyingSubscription == false)
    }

    @Test func testPaywallToPaywallTransitionWithInactiveSubscription() async throws {
        // Given
        let mockServices = MockServiceLocator()
        (mockServices.revenueCatService as! MockRevenueCatService).shouldReturnActiveSubscription = false
        let coordinator = AppCoordinator(services: mockServices)
        coordinator.appState = .paywall

        // When
        await coordinator.startMainTabs()

        // Then
        #expect(coordinator.appState == .paywall) // Should stay on paywall
        #expect(coordinator.isVerifyingSubscription == false)
    }

    @Test func testErrorHandlingIntegration() {
        // Given
        let coordinator = AppCoordinator(services: MockServiceLocator())
        let testError = NSError(domain: "TestError", code: 1, userInfo: nil)

        // When
        coordinator.handleError(testError)

        // Then
        #expect(coordinator.errorOccurred != nil)
        #expect((coordinator.errorOccurred as? NSError)?.domain == "TestError")
    }

    @Test func testUpgradeFromTabs() {
        // Given
        let coordinator = AppCoordinator(services: MockServiceLocator())
        coordinator.appState = .mainTabs

        // When
        coordinator.upgradeFromTabs()

        // Then
        #expect(coordinator.appState == .paywall)
    }

    @Test func testCompleteNavigationFlow() async throws {
        // Integration test for complete app navigation flow:
        // valueScreens -> signIn -> onboarding -> survey -> paywall -> mainTabs
        // This test follows the user journey and ensures proper state transitions
        // Given
        let mockServices = MockServiceLocator()
        (mockServices.revenueCatService as! MockRevenueCatService).shouldReturnActiveSubscription = true
        let coordinator = AppCoordinator(services: mockServices)

        // When - Start the journey from value screens
        coordinator.startValueScreens()
        #expect(coordinator.appState == .valueScreens)

        // Transition to sign in after value screens completion
        coordinator.startSignIn()
        #expect(coordinator.appState == .signIn)

        // Transition to onboarding after sign in completion
        coordinator.startOnboarding()
        #expect(coordinator.appState == .onboarding)

        // Transition to survey after onboarding completion
        coordinator.startSurvey()
        #expect(coordinator.appState == .survey)

        // Transition to paywall after survey completion
        coordinator.startPaywall()
        #expect(coordinator.appState == .paywall)

        // Transition to main tabs after purchase
        await coordinator.startMainTabs()
        #expect(coordinator.appState == .mainTabs)
    }

    @Test func testSubscriptionVerificationOnLaunch() async throws {
        // Given
        let mockServices = MockServiceLocator()
        (mockServices.revenueCatService as! MockRevenueCatService).shouldReturnActiveSubscription = false
        let coordinator = AppCoordinator(services: mockServices)
        coordinator.appState = .mainTabs

        // When
        await coordinator.verifySubscriptionOnLaunch()

        // Then
        #expect(coordinator.appState == .paywall) // Should redirect to paywall
        #expect(coordinator.isVerifyingSubscription == false)
    }
}