import Foundation
import AuthenticationServices
import Security
import os
import Supabase
import CryptoKit

/// Implementation of AuthenticationServiceProtocol using Apple's AuthenticationServices framework
class AuthenticationService: NSObject, AuthenticationServiceProtocol, ASAuthorizationControllerDelegate {

    private let serviceLocator: ServiceLocator
    private let errorHandler: ErrorHandlerProtocol

    // Storage keys for UserDefaults
    private let userIdentifierKey = "apple_user_identifier"
    private let credentialKey = "apple_user_credential"

    private let supabaseClient: SupabaseClient

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        self.errorHandler = serviceLocator.errorHandler
        self.supabaseClient = serviceLocator.supabaseClient
        super.init()
    }

    private let signposter = OSSignposter(subsystem: Bundle.main.bundleIdentifier ?? "app-template", category: "Auth")

    private var currentNonce: String?

    // MARK: - Public API

    func signInWithApple(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding) async throws -> UserCredential {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let request = try createAppleIDRequest()
                let controller = ASAuthorizationController(authorizationRequests: [request])

                controller.delegate = self
                controller.presentationContextProvider = presentationContextProvider

                self.pendingContinuation = continuation

                let id = self.signposter.makeSignpostID()
                _ = self.signposter.beginInterval("signInWithApple.performRequests", id: id)

                controller.performRequests()
            } catch {
                continuation.resume(throwing: AuthenticationError.signInFailed(reason: error.localizedDescription))
            }
        }
    }

    func signOut() async throws {
        do {
            try await supabaseClient.auth.signOut()
        } catch {
            errorHandler.logError(error, category: "Auth")
        }

        // Clear stored credentials
        UserDefaults.standard.removeObject(forKey: userIdentifierKey)
        UserDefaults.standard.removeObject(forKey: credentialKey)

        clearKeychainCredentials()
    }

    func getCurrentUser() async -> UserCredential? {
        guard let storedData = UserDefaults.standard.data(forKey: credentialKey),
              let credential = try? JSONDecoder().decode(UserCredential.self, from: storedData) else {
            return nil
        }

        guard credential.isValid else {
            return nil
        }

        return credential
    }

    func isUserSignedIn() async -> Bool {
        if let _ = try? await supabaseClient.auth.user() {
            return true
        }
        return false
    }

    func refreshCredentials() async throws {
        do {
            _ = try await supabaseClient.auth.user()
        } catch {
            throw AuthenticationError.credentialsExpired
        }
    }

    func handleAuthorization(authorization: ASAuthorization, error: Error?) async throws -> UserCredential {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("handleAuthorization", id: id)

        if let error = error {
            signposter.endInterval("handleAuthorization", state)
            throw AuthenticationError.authorizationFailed(reason: error.localizedDescription)
        }

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            signposter.endInterval("handleAuthorization", state)
            throw AuthenticationError.authorizationFailed(reason: "Invalid credential type")
        }

        let credential = UserCredential(
            userIdentifier: appleIDCredential.user,
            fullName: appleIDCredential.fullName,
            email: appleIDCredential.email,
            identityToken: appleIDCredential.identityToken,
            authorizationCode: appleIDCredential.authorizationCode,
            realUserStatus: appleIDCredential.realUserStatus,
            createdAt: Date()
        )

        do {
            try storeCredential(credential)

            if let tokenData = appleIDCredential.identityToken,
               let idToken = String(data: tokenData, encoding: .utf8) {
                do {
                    let nonce = self.currentNonce
                    self.currentNonce = nil

                    try await supabaseClient.auth.signInWithIdToken(
                        credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
                    )

                    if let authUser = try? await supabaseClient.auth.user() {
                        await withTaskGroup(of: Void.self) { group in
                            group.addTask {
                                try? await self.serviceLocator.revenueCatService.linkPurchaser(with: "\(authUser.id)")
                            }
                        }
                    }
                } catch {
                    errorHandler.logError(error, category: "Auth")
                }
            } else {
                errorHandler.logError(AuthenticationError.invalidIdentityToken, category: "Auth")
            }

            signposter.endInterval("handleAuthorization", state)
            return credential
        } catch {
            signposter.endInterval("handleAuthorization", state)
            throw error
        }
    }

    func validateCredentials() async -> Bool {
        guard let credential = await getCurrentUser() else {
            return false
        }
        return credential.isValid
    }

    func getUserIdentifier() async -> String? {
        if let authUser = try? await supabaseClient.auth.user() {
            return "\(authUser.id)"
        }
        // Fallback to Apple identifier if Supabase session not present
        return await getCurrentUser()?.userIdentifier
    }

    func waitForRestoredSession(maxWait: TimeInterval = 2.0) async -> Bool {
        let end = Date().addingTimeInterval(maxWait)
        if let _ = try? await supabaseClient.auth.user() {
            return true
        }
        while Date() < end {
            if let _ = try? await supabaseClient.auth.user() {
                return true
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        return false
    }

    func hasLocalAppleCredential() -> Bool {
        return UserDefaults.standard.data(forKey: credentialKey) != nil
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            do {
                let credential = try await handleAuthorization(authorization: authorization, error: nil)
                resumeContinuation(with: .success(credential))
            } catch {
                resumeContinuation(with: .failure(error))
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError: AuthenticationError
        if let authorizationError = error as? ASAuthorizationError {
            switch authorizationError.code {
            case .canceled:
                authError = .signInCancelled
            case .failed:
                authError = .signInFailed(reason: "Apple authorization failed")
            case .invalidResponse:
                authError = .authorizationFailed(reason: "Invalid response from Apple")
            case .notHandled:
                authError = .authorizationFailed(reason: "Authorization not handled")
            case .unknown:
                authError = .authorizationFailed(reason: "Unknown authorization error")
            @unknown default:
                authError = .authorizationFailed(reason: "Unknown authorization error")
            }
        } else {
            authError = .authorizationFailed(reason: error.localizedDescription)
        }

        resumeContinuation(with: .failure(authError))
    }

    // MARK: - Private Methods

    private func createAppleIDRequest() throws -> ASAuthorizationAppleIDRequest {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()

        // Configure request
        request.requestedScopes = [.fullName, .email]

        let rawNonce = randomNonceString()
        self.currentNonce = rawNonce
        request.nonce = sha256(rawNonce)

        return request
    }

    private func storeCredential(_ credential: UserCredential) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(credential)

        UserDefaults.standard.set(data, forKey: credentialKey)
        UserDefaults.standard.set(credential.userIdentifier, forKey: userIdentifierKey)
    }

    private func clearKeychainCredentials() {
        // Clear any additional credentials stored in Keychain
        // This is a placeholder for Keychain operations if needed
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.app-template.apple-auth"
        ]

        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Continuation Management

    private var pendingContinuation: CheckedContinuation<UserCredential, Error>?

    private func resumeContinuation(with result: Result<UserCredential, Error>) {
        guard let continuation = pendingContinuation else { return }
        pendingContinuation = nil

        switch result {
        case .success(let credential):
            continuation.resume(returning: credential)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - UserCredential Codable Extension

extension UserCredential: Codable {
    enum CodingKeys: String, CodingKey {
        case userIdentifier, fullName, email, identityToken, authorizationCode, realUserStatus, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        userIdentifier = try container.decode(String.self, forKey: .userIdentifier)
        fullName = try container.decodeIfPresent(PersonNameComponents.self, forKey: .fullName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        identityToken = try container.decodeIfPresent(Data.self, forKey: .identityToken)
        authorizationCode = try container.decodeIfPresent(Data.self, forKey: .authorizationCode)
        let realUserStatusRaw = try container.decode(Int.self, forKey: .realUserStatus)
        realUserStatus = ASUserDetectionStatus(rawValue: realUserStatusRaw) ?? .unknown
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(userIdentifier, forKey: .userIdentifier)
        try container.encodeIfPresent(fullName, forKey: .fullName)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(identityToken, forKey: .identityToken)
        try container.encodeIfPresent(authorizationCode, forKey: .authorizationCode)
        try container.encode(realUserStatus.rawValue, forKey: .realUserStatus)
        try container.encode(createdAt, forKey: .createdAt)
    }
}