import Foundation
import Testing
import AuthenticationServices
@testable import app_template

/// Mock authentication service for testing
class MockAuthenticationService: AuthenticationServiceProtocol {
    var shouldThrowError = false
    var mockCredential: UserCredential?

    func signInWithApple(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding) async throws -> UserCredential {
        if shouldThrowError {
            throw AuthenticationError.signInFailed(reason: "Mock error")
        }
        return mockCredential ?? UserCredential(
            userIdentifier: "mock_user_id",
            fullName: nil,
            email: nil,
            identityToken: nil,
            authorizationCode: nil,
            realUserStatus: .unknown,
            createdAt: Date()
        )
    }

    func signOut() async throws {
        // Mock implementation
    }

    func getCurrentUser() async -> UserCredential? {
        return mockCredential
    }

    func isUserSignedIn() async -> Bool {
        return mockCredential != nil
    }

    func refreshCredentials() async throws {
        // Mock implementation
    }

    func handleAuthorization(authorization: ASAuthorization, error: Error?) async throws -> UserCredential {
        throw AuthenticationError.signInFailed(reason: "Mock error")
    }

    func validateCredentials() async -> Bool {
        return true
    }

    func getUserIdentifier() async -> String? {
        return mockCredential?.userIdentifier
    }
}

/// Mock app coordinator for testing
class MockAppCoordinator: AppCoordinator {
    var onboardingStarted = false

    override func startOnboarding() {
        onboardingStarted = true
    }
}

/// Mock presentation context provider for testing
class MockPresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIWindow()
    }
}

struct SignInViewModelTests {

    @Test func testInit() {
        // Given
        let mockAuthService = MockAuthenticationService()
        let mockCoordinator = MockAppCoordinator()

        // When
        let viewModel = SignInViewModel(authenticationService: mockAuthService, coordinator: mockCoordinator)

        // Then
        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
    }

    @Test func testSignInSuccess() async throws {
        // Given
        let mockAuthService = MockAuthenticationService()
        let mockCoordinator = MockAppCoordinator()
        let viewModel = SignInViewModel(authenticationService: mockAuthService, coordinator: mockCoordinator)
        let mockProvider = MockPresentationContextProvider()

        // When
        await viewModel.signIn(presentationContextProvider: mockProvider)

        // Then
        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
        #expect(mockCoordinator.onboardingStarted)
    }

    @Test func testSignInFailure() async throws {
        // Given
        let mockAuthService = MockAuthenticationService()
        mockAuthService.shouldThrowError = true
        let mockCoordinator = MockAppCoordinator()
        let viewModel = SignInViewModel(authenticationService: mockAuthService, coordinator: mockCoordinator)
        let mockProvider = MockPresentationContextProvider()

        // When
        await viewModel.signIn(presentationContextProvider: mockProvider)

        // Then
        #expect(!viewModel.isLoading)
        #expect(viewModel.error != nil)
        #expect(!mockCoordinator.onboardingStarted)
    }

    @Test func testSignInCancelled() async throws {
        // Given
        let mockAuthService = MockAuthenticationService()
        mockAuthService.shouldThrowError = true
        // Simulate cancelled error
        let mockCoordinator = MockAppCoordinator()
        let viewModel = SignInViewModel(authenticationService: mockAuthService, coordinator: mockCoordinator)
        let mockProvider = MockPresentationContextProvider()

        // When
        await viewModel.signIn(presentationContextProvider: mockProvider)

        // Then
        #expect(!viewModel.isLoading)
        #expect(viewModel.error != nil)
        #expect(!mockCoordinator.onboardingStarted)
    }

    @Test func testClearError() {
        // Given
        let mockAuthService = MockAuthenticationService()
        let mockCoordinator = MockAppCoordinator()
        let viewModel = SignInViewModel(authenticationService: mockAuthService, coordinator: mockCoordinator)
        viewModel.error = "Test error"

        // When
        viewModel.clearError()

        // Then
        #expect(viewModel.error == nil)
    }

    @Test func testLoadingPublisher() {
        // Given
        let mockAuthService = MockAuthenticationService()
        let mockCoordinator = MockAppCoordinator()
        let viewModel = SignInViewModel(authenticationService: mockAuthService, coordinator: mockCoordinator)

        // When
        let publisher = viewModel.loadingPublisher()

        // Then
        #expect(publisher != nil)
    }

    @Test func testErrorPublisher() {
        // Given
        let mockAuthService = MockAuthenticationService()
        let mockCoordinator = MockAppCoordinator()
        let viewModel = SignInViewModel(authenticationService: mockAuthService, coordinator: mockCoordinator)

        // When
        let publisher = viewModel.errorPublisher()

        // Then
        #expect(publisher != nil)
    }
}