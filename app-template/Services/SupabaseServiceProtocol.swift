import Foundation

protocol SupabaseServiceProtocol {
    func fetchOnboardingScreens(userProperty: String) async throws -> [OnboardingScreenDTO]
    func fetchSurveyQuestions(surveyId: Int) async throws -> [QuestionDTO]
    func saveSurveyResponses(_ responses: [SurveyResponseDTO], for userId: String) async throws

    func linkPurchaser(withID identifier: String) async throws

    func createUser(_ userProfile: UserProfileDTO) async throws -> UserProfileDTO
    func updateUser(userId: String, with userProfile: UserProfileDTO) async throws -> UserProfileDTO
    func getCurrentUser() async throws -> UserProfileDTO?
    func getUserSubscriptionStatus(userId: String) async throws -> Bool
    func syncSubscriptionStateFromClient(isPremium: Bool, subscriptionStatus: String?) async throws

    func deleteCurrentUserAccount() async throws
}