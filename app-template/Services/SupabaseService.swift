import Foundation
import Supabase
import OSLog
import os

struct OnboardingScreensParams: Encodable {
    let userProperty: String

    enum CodingKeys: String, CodingKey {
        case userProperty = "user_property"
    }
}

struct SurveyQuestionsParams: Encodable {
    let surveyId: Int

    enum CodingKeys: String, CodingKey {
        case surveyId = "survey_id"
    }
}

struct CreateUserParams: Encodable {
    let userId: String?
    let email: String?
    let displayName: String?
    let signupTime: String?
    let uniqueId: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case displayName = "display_name"
        case signupTime = "signup_time"
        case uniqueId = "unique_id"
    }
}

struct UpdateUserParams: Encodable {
    let userId: String
    let email: String?
    let displayName: String?
    let signupTime: String?
    let uniqueId: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case displayName = "display_name"
        case signupTime = "signup_time"
        case uniqueId = "unique_id"
    }
}

enum SupabaseServiceError: LocalizedError {
    case missingUserId

    var errorDescription: String? {
        switch self {
        case .missingUserId:
            return "User identifier is required to perform this operation."
        }
    }
}

/// Implementation of SupabaseServiceProtocol using Supabase client
class SupabaseService: SupabaseServiceProtocol {
    private let client: SupabaseClient
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app-template", category: "Database")
    private let signposter = OSSignposter(subsystem: Bundle.main.bundleIdentifier ?? "app-template", category: "Supabase")

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchOnboardingScreens(userProperty: String) async throws -> [OnboardingScreenDTO] {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("fetchOnboardingScreens", id: id)
        do {
            let response: [OnboardingScreenDTO] = try await client.functions.invoke(
                "get-onboarding-screens",
                options: FunctionInvokeOptions(
                    method: .get,
                    query: [
                        URLQueryItem(name: "userProperty", value: userProperty)
                    ]
                )
            )
            signposter.endInterval("fetchOnboardingScreens", state)
            return response
        } catch {
            signposter.endInterval("fetchOnboardingScreens", state)
            logger.error("fetchOnboardingScreens failed: \(error.localizedDescription, privacy: .public)")
            return getMockOnboardingScreens()
        }
    }

    func fetchSurveyQuestions(surveyId: Int) async throws -> [QuestionDTO] {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("fetchSurveyQuestions", id: id)
        do {
            let response: [QuestionDTO] = try await client.functions.invoke(
                "get-survey-questions",
                options: FunctionInvokeOptions(
                    method: .get,
                    query: [
                        URLQueryItem(name: "surveyId", value: String(surveyId))
                    ]
                )
            )
            signposter.endInterval("fetchSurveyQuestions", state)
            return response
        } catch {
            signposter.endInterval("fetchSurveyQuestions", state)
            logger.error("fetchSurveyQuestions failed: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    private func getMockOnboardingScreens() -> [OnboardingScreenDTO] {
        return [
            OnboardingScreenDTO(
                id: 1,
                title: "Welcome to the App",
                description: "Get started with your personalized experience. We'll guide you through the key features.",
                imageUrl: nil,
                buttonText: "Get Started",
                nextId: 2
            ),
            OnboardingScreenDTO(
                id: 2,
                title: "Explore Features",
                description: "Discover powerful tools designed to help you achieve your goals efficiently.",
                imageUrl: nil,
                buttonText: "Continue",
                nextId: 3
            ),
            OnboardingScreenDTO(
                id: 3,
                title: "Ready to Begin",
                description: "You're all set! Start using the app and enjoy your experience.",
                imageUrl: nil,
                buttonText: "Let's Go",
                nextId: nil
            )
        ]
    }

    func saveSurveyResponses(_ responses: [SurveyResponseDTO], for userId: String) async throws {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("saveSurveyResponses", id: id)
        guard !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.error("saveSurveyResponses called with empty userId")
            signposter.endInterval("saveSurveyResponses", state)
            throw SupabaseServiceError.missingUserId
        }

        struct SurveyResponsePayload: Encodable {
            var survey_id: Int
            var question_id: Int
            var user_id: String?
            var response_value: String
            var response_metadata: [String: String]?
            var submitted_at: String
        }

        let validUUID = UUID(uuidString: userId) != nil

        let payloads = responses.map {
            SurveyResponsePayload(
                survey_id: $0.surveyId,
                question_id: $0.questionId,
                user_id: validUUID ? userId : nil,
                response_value: $0.response,
                response_metadata: validUUID ? nil : ["client_user_identifier": userId],
                submitted_at: $0.createdAt.ISO8601Format()
            )
        }

        do {
            try await client
                .from("survey_responses")
                .insert(payloads)
                .execute()
            signposter.endInterval("saveSurveyResponses", state)
        } catch {
            signposter.endInterval("saveSurveyResponses", state)
            logger.error("saveSurveyResponses failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private struct SyncSubscriptionPayload: Encodable {
        let is_premium: Bool
        let subscription_status: String?
    }

    func linkPurchaser(withID identifier: String) async throws {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("linkPurchaser.authSync", id: id)
        defer { signposter.endInterval("linkPurchaser.authSync", state) }

        logger.info("Invoking auth-sync (linkPurchaser) without payload for user linking")
        do {
            struct AuthSyncResponse: Decodable {
                struct User: Decodable {
                    let id: String
                    let email: String?
                    let is_premium: Bool?
                    let subscription_status: String?
                }
                let user: User?
            }

            let response: AuthSyncResponse = try await client.functions.invoke(
                "auth-sync",
                options: FunctionInvokeOptions(method: .post)
            )
            if let user = response.user {
                logger.info("auth-sync link result: id=\(user.id, privacy: .private) is_premium=\(user.is_premium ?? false, privacy: .public) status=\(user.subscription_status ?? "nil", privacy: .public)")
            } else {
                logger.warning("auth-sync link result: user is nil")
            }
        } catch {
            logger.error("auth-sync link failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func createUser(_ userProfile: UserProfileDTO) async throws -> UserProfileDTO {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("createUser", id: id)
        do {
            let parameters = CreateUserParams(
                userId: userProfile.userId,
                email: userProfile.email,
                displayName: userProfile.displayName,
                signupTime: userProfile.signupTime?.ISO8601Format(),
                uniqueId: userProfile.uniqueId
            )

            let functionName = "create-user"
            let response: UserProfileDTO = try await client.functions.invoke(
                functionName,
                options: FunctionInvokeOptions(body: parameters)
            )
            signposter.endInterval("createUser", state)
            return response
        } catch {
            signposter.endInterval("createUser", state)
            logger.error("createUser failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func updateUser(userId: String, with userProfile: UserProfileDTO) async throws -> UserProfileDTO {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("updateUser", id: id)
        do {
            let parameters = UpdateUserParams(
                userId: userId,
                email: userProfile.email,
                displayName: userProfile.displayName,
                signupTime: userProfile.signupTime?.ISO8601Format(),
                uniqueId: userProfile.uniqueId
            )

            let functionName = "update-user"
            let response: UserProfileDTO = try await client.functions.invoke(
                functionName,
                options: FunctionInvokeOptions(body: parameters)
            )
            signposter.endInterval("updateUser", state)
            return response
        } catch {
            signposter.endInterval("updateUser", state)
            logger.error("updateUser failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func getCurrentUser() async throws -> UserProfileDTO? {
        do {
            let authUser = try? await client.auth.user()
            guard let authUser else {
                return nil
            }

            // Existing DB lookup (legacy 'users' table) retained for compatibility
            let userIdString = "\(authUser.id)"
            let rows: [UserProfileDTO] = (try? await client
                .from("users")
                .select("*")
                .eq("user_id", value: authUser.id)
                .limit(1)
                .execute()
                .value) ?? []

            if let existing = rows.first {
                return existing
            }

            // Fallback: return minimal profile from Supabase Auth
            return UserProfileDTO(
                id: nil,
                userId: userIdString,
                email: authUser.email,
                displayName: nil,
                isPremium: nil,
                notificationsEnabled: nil,
                surveyProgress: nil,
                lastSurveyDate: nil,
                appLaunchCount: nil,
                createdAt: nil,
                updatedAt: nil,
                signupTime: nil,
                uniqueId: nil
            )
        } catch {
            logger.error("getCurrentUser failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func getUserSubscriptionStatus(userId: String) async throws -> Bool {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("getUserSubscriptionStatus", id: id)
        struct PremiumRow: Decodable {
            let isPremium: Bool?

            enum CodingKeys: String, CodingKey {
                case isPremium = "is_premium"
            }
        }

        struct ProfileRow: Decodable {
            let subscriptionStatus: String?

            enum CodingKeys: String, CodingKey {
                case subscriptionStatus = "subscription_status"
            }
        }

        do {
            // Prefer new user_profiles.is_premium
            let rows: [PremiumRow] = try await client
                .from("user_profiles")
                .select("is_premium")
                .eq("id", value: userId)
                .limit(1)
                .execute()
                .value

            if let value = rows.first?.isPremium {
                signposter.endInterval("getUserSubscriptionStatus", state)
                return value
            }
        } catch {
            // Ignore and try fallback
        }

        do {
            // Fallback: 'user_profiles.subscription_status' text (e.g., 'premium', 'free', 'active')
            let rows: [ProfileRow] = try await client
                .from("user_profiles")
                .select("subscription_status")
                .eq("id", value: userId)
                .limit(1)
                .execute()
                .value

            let status = rows.first?.subscriptionStatus?.lowercased()
            signposter.endInterval("getUserSubscriptionStatus", state)
            return status == "active" || status == "premium" || status == "subscribed"
        } catch {
            signposter.endInterval("getUserSubscriptionStatus", state)
            logger.error("getUserSubscriptionStatus failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func syncSubscriptionStateFromClient(isPremium: Bool, subscriptionStatus: String?) async throws {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("syncSubscriptionStateFromClient", id: id)
        defer { signposter.endInterval("syncSubscriptionStateFromClient", state) }

        do {
            let payload = SyncSubscriptionPayload(is_premium: isPremium, subscription_status: subscriptionStatus)
            logger.info("auth-sync push: is_premium=\(isPremium, privacy: .public) subscription_status=\(subscriptionStatus ?? "nil", privacy: .public)")
            struct AuthSyncResponse: Decodable {
                struct User: Decodable {
                    let id: String
                    let email: String?
                    let is_premium: Bool?
                    let subscription_status: String?
                }
                let user: User?
            }
            let response: AuthSyncResponse = try await client.functions.invoke(
                "auth-sync",
                options: FunctionInvokeOptions(method: .post, body: payload)
            )
            if let user = response.user {
                logger.info("auth-sync push result: id=\(user.id, privacy: .private) is_premium=\(user.is_premium ?? false, privacy: .public) status=\(user.subscription_status ?? "nil", privacy: .public)")
            } else {
                logger.warning("auth-sync push result: user is nil")
            }
        } catch {
            logger.error("syncSubscriptionStateFromClient failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func deleteCurrentUserAccount() async throws {
        let id = signposter.makeSignpostID()
        let state = signposter.beginInterval("deleteCurrentUserAccount", id: id)
        defer { signposter.endInterval("deleteCurrentUserAccount", state) }

        struct Request: Encodable { let action: String }
        struct Response: Decodable { let success: Bool; let message: String? }

        do {
            let response: Response = try await client.functions.invoke(
                "user-profile",
                options: FunctionInvokeOptions(
                    method: .post,
                    body: Request(action: "delete_account")
                )
            )
            if response.success == false {
                throw NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: response.message ?? "Failed to delete account"])
            }
            logger.info("deleteCurrentUserAccount succeeded")
        } catch {
            logger.error("deleteCurrentUserAccount failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}