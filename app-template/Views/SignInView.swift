import SwiftUI
import AuthenticationServices
import UIKit

/// View for displaying Apple Sign-In interface with proper styling and error handling
struct SignInView: View {

    // MARK: - Properties

    /// ViewModel for managing sign-in state and business logic
    @StateObject var viewModel: SignInViewModel

    /// Callback executed when sign-in completes successfully
    let onSuccess: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background color for better visual hierarchy
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 32) {
                Spacer()

                // App logo or branding area
                VStack(spacing: 16) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 80))
                        .foregroundColor(.primary)
                        .accessibilityIdentifier("SignInAppLogo")

                    Text("Welcome")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                        .accessibilityIdentifier("SignInWelcomeTitle")

                    Text("Sign in with your Apple ID to continue")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .accessibilityIdentifier("SignInSubtitle")
                }

                Spacer()

                // Sign-in button and error handling area
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .accessibilityIdentifier("SignInLoadingIndicator")

                            Text("Signing you in...")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .accessibilityIdentifier("SignInLoadingText")
                        }
                    }
                    else if let error = viewModel.error {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                                .accessibilityIdentifier("SignInErrorIcon")

                            Text("Sign-In Failed")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .accessibilityIdentifier("SignInErrorTitle")

                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .accessibilityIdentifier("SignInErrorMessage")

                            Button(action: {
                                viewModel.clearError()
                            }) {
                                Text("Try Again")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .accessibilityIdentifier("SignInRetryButton")
                        }
                    }
                    else {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            Task {
                                await viewModel.handleAuthorizationResult(result)
                            }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(8)
                        .padding(.horizontal, 32)
                        .accessibilityIdentifier("SignInAppleButton")
                    }

                    // Terms and privacy notice
                    VStack(spacing: 8) {
                        Text("By signing in, you agree to our")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Button(action: {
                                // Open terms of service
                                if let url = URL(string: Configuration.termsOfServiceURL) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Terms of Service")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .underline()
                            }

                            Text("and")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Button(action: {
                                // Open privacy policy
                                if let url = URL(string: Configuration.privacyPolicyURL) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Privacy Policy")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .accessibilityIdentifier("SignInTermsNotice")
                }

                Spacer()
            }
            .padding(.vertical, 32)
        }
        .onAppear {
            // Clear any previous error state when view appears
            viewModel.clearError()
        }
    }

}

// MARK: - Preview

#Preview {
    // Create mock dependencies for preview
    let mockAuthService = MockAuthenticationService()
    let mockCoordinator = AppCoordinator(services: ServiceLocator.shared)

    let viewModel = SignInViewModel(
        authenticationService: mockAuthService,
        coordinator: mockCoordinator
    )

    SignInView(viewModel: viewModel, onSuccess: {})
}

// MARK: - Mock Service for Preview

/// Mock authentication service for SwiftUI previews
private class MockAuthenticationService: AuthenticationServiceProtocol {
    func signInWithApple(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding) async throws -> UserCredential {
        // Simulate successful sign-in for preview
        return UserCredential(
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
        return nil
    }

    func isUserSignedIn() async -> Bool {
        return false
    }

    func refreshCredentials() async throws {
        // Mock implementation
    }

    func handleAuthorization(authorization: ASAuthorization, error: Error?) async throws -> UserCredential {
        throw AuthenticationError.signInFailed(reason: "Mock error")
    }

    func validateCredentials() async -> Bool {
        return false
    }

    func getUserIdentifier() async -> String? {
        return nil
    }

    func waitForRestoredSession(maxWait: TimeInterval) async -> Bool {
        return false
    }

    func hasLocalAppleCredential() -> Bool {
        return false
    }
}