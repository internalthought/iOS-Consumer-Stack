import Foundation
import AuthenticationServices
import Combine

/// ViewModel for managing Apple Sign-In authentication flow and navigation
@MainActor
class SignInViewModel: ObservableObject {

    // MARK: - Observable State Properties

    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    // MARK: - Dependencies

    /// Service for handling authentication operations
    private let authenticationService: AuthenticationServiceProtocol

    /// Coordinator for managing app navigation flow
    private let coordinator: AppCoordinatorProtocol

    // MARK: - Initialization

    /// Initialize the SignInViewModel with required dependencies
    /// - Parameters:
    ///   - authenticationService: The authentication service to use for sign-in
    ///   - coordinator: The app coordinator for navigation management
    init(authenticationService: AuthenticationServiceProtocol, coordinator: AppCoordinatorProtocol) {
        self.authenticationService = authenticationService
        self.coordinator = coordinator
    }

    // MARK: - Public Methods

    /// Initiates the Apple Sign-In process
    /// - Parameter presentationContextProvider: The presentation context provider for ASAuthorizationController
    func signIn(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding) async {
        isLoading = true
        error = nil

        do {
            let credential = try await authenticationService.signInWithApple(presentationContextProvider: presentationContextProvider)
            _ = credential
            await coordinator.startOnboarding()
        } catch let authError as AuthenticationError {
            switch authError {
            case .signInCancelled:
                break
            default:
                error = authError.localizedDescription
            }
        } catch {
            self.error = "An unexpected error occurred. Please try again."
        }

        isLoading = false
    }

    func handleAuthorizationResult(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        error = nil

        switch result {
        case .success(let authorization):
            do {
                _ = try await authenticationService.handleAuthorization(authorization: authorization, error: nil)
                await coordinator.startOnboarding()
            } catch let authError as AuthenticationError {
                switch authError {
                case .signInCancelled:
                    break
                default:
                    error = authError.localizedDescription
                }
            } catch {
                self.error = "An unexpected error occurred. Please try again."
            }

        case .failure(let err):
            if let authorizationError = err as? ASAuthorizationError, authorizationError.code == .canceled {
            } else {
                error = err.localizedDescription
            }
        }

        isLoading = false
    }

    func clearError() {
        error = nil
    }

    func loadingPublisher() -> AnyPublisher<Bool, Never> {
        $isLoading.eraseToAnyPublisher()
    }

    func errorPublisher() -> AnyPublisher<String?, Never> {
        $error.eraseToAnyPublisher()
    }
}