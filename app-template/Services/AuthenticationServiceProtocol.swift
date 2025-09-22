import Foundation
import AuthenticationServices

/// Protocol defining authentication service interface for Apple Sign-In integration
protocol AuthenticationServiceProtocol {

    /// Initiate Apple Sign-In process
    /// - Parameter presentationContextProvider: The presentation context provider for ASAuthorizationController
    /// - Returns: User credential information after successful authentication
    /// - Throws: AuthenticationError if sign-in fails
    func signInWithApple(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding) async throws -> UserCredential

    /// Sign out the current user and clear stored credentials
    /// - Throws: AuthenticationError if sign-out fails
    func signOut() async throws

    /// Get current authenticated user information
    /// - Returns: Current user credential if authenticated, nil otherwise
    func getCurrentUser() async -> UserCredential?

    /// Check if user is currently signed in
    /// - Returns: True if user has valid authentication, false otherwise
    func isUserSignedIn() async -> Bool

    /// Refresh user credentials if they are expired
    /// - Throws: AuthenticationError if refresh fails
    func refreshCredentials() async throws

    /// Handle Apple authorization results from ASAuthorizationController
    /// - Parameters:
    ///   - authorization: The authorization result from Apple
    ///   - error: Any error that occurred during authorization
    /// - Returns: User credential information after processing authorization
    /// - Throws: AuthenticationError if authorization processing fails
    func handleAuthorization(authorization: ASAuthorization, error: Error?) async throws -> UserCredential

    /// Validate stored credentials and check if they are still valid
    /// - Returns: True if credentials are valid and not expired
    func validateCredentials() async -> Bool

    /// Get user identifier from stored credentials
    /// - Returns: User identifier string if available
    func getUserIdentifier() async -> String?

    /// Polls for a short period to allow the SDK to restore a persisted session.
    /// - Parameter maxWait: Maximum time to wait for session restoration
    /// - Returns: True if a session is found during the wait window
    func waitForRestoredSession(maxWait: TimeInterval) async -> Bool

    func hasLocalAppleCredential() -> Bool
}

/// User credential structure for authentication results
struct UserCredential {
    /// Unique user identifier from Apple
    let userIdentifier: String

    /// User's full name from Apple ID
    let fullName: PersonNameComponents?

    /// User's email address from Apple ID
    let email: String?

    /// Identity token for server verification
    let identityToken: Data?

    /// Authorization code for server exchange
    let authorizationCode: Data?

    /// Real user status indicator
    let realUserStatus: ASUserDetectionStatus

    /// Timestamp when credential was created
    let createdAt: Date

    /// Whether the credential is currently valid
    var isValid: Bool {
        // Credentials are considered valid for 24 hours
        return Date().timeIntervalSince(createdAt) < 86400
    }
}

/// Custom authentication error types
enum AuthenticationError: LocalizedError {
    case signInCancelled
    case signInFailed(reason: String)
    case invalidCredentials
    case credentialsExpired
    case networkError
    case authorizationFailed(reason: String)
    case userNotFound
    case invalidAuthorizationCode
    case invalidIdentityToken

    var errorDescription: String? {
        switch self {
        case .signInCancelled:
            return "User cancelled the sign-in process"
        case .signInFailed(let reason):
            return "Sign-in failed: \(reason)"
        case .invalidCredentials:
            return "Invalid or corrupted credentials"
        case .credentialsExpired:
            return "User credentials have expired"
        case .networkError:
            return "Network error during authentication"
        case .authorizationFailed(let reason):
            return "Authorization failed: \(reason)"
        case .userNotFound:
            return "User not found in authentication system"
        case .invalidAuthorizationCode:
            return "Invalid authorization code received"
        case .invalidIdentityToken:
            return "Invalid identity token received"
        }
    }
}