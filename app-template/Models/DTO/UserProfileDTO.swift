import Foundation

struct UserProfileDTO: Codable, Equatable, Identifiable {
    let id: UUID?
    let userId: String?
    let email: String?
    let displayName: String?
    let isPremium: Bool?
    let notificationsEnabled: Bool?
    let surveyProgress: [Int: String]?
    let lastSurveyDate: Date?
    let appLaunchCount: Int?
    let createdAt: Date?
    let updatedAt: Date?
    let signupTime: Date?
    let uniqueId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case email
        case displayName = "display_name"
        case isPremium = "is_premium"
        case notificationsEnabled = "notifications_enabled"
        case surveyProgress = "survey_progress"
        case lastSurveyDate = "last_survey_date"
        case appLaunchCount = "app_launch_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case signupTime = "signup_time"
        case uniqueId = "unique_id"
    }
}