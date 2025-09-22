import Foundation
import SwiftData

/// Model representing user preferences and profile data
@Model
final class UserProfile: Identifiable, Equatable, Decodable, Encodable {
    var id = UUID()
    var userId: String?
    var email: String?
    var displayName: String?
    var isPremium: Bool = false
    var notificationsEnabled: Bool = true
    var surveyProgress: [Int: String]? // surveyId: current step or state
    var lastSurveyDate: Date?
    var appLaunchCount: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    /// Timestamp when the user signed up for tracking purposes
    var signupTime: Date?

    /// Unique identifier for user identification across systems
    var uniqueId: String?

    enum CodingKeys: String, CodingKey {
        case id, userId, email, displayName, isPremium, notificationsEnabled
        case surveyProgress, lastSurveyDate, appLaunchCount, createdAt, updatedAt
        case signupTime, uniqueId
    }

    init(userId: String?, email: String?, displayName: String?, isPremium: Bool = false) {
        self.userId = userId
        self.email = email
        self.displayName = displayName
        self.isPremium = isPremium
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        self.isPremium = try container.decode(Bool.self, forKey: .isPremium)
        self.notificationsEnabled = try container.decode(Bool.self, forKey: .notificationsEnabled)
        self.surveyProgress = try container.decodeIfPresent([Int: String].self, forKey: .surveyProgress)
        self.lastSurveyDate = try container.decodeIfPresent(Date.self, forKey: .lastSurveyDate)
        self.appLaunchCount = try container.decode(Int.self, forKey: .appLaunchCount)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.signupTime = try container.decodeIfPresent(Date.self, forKey: .signupTime)
        self.uniqueId = try container.decodeIfPresent(String.self, forKey: .uniqueId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encode(isPremium, forKey: .isPremium)
        try container.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try container.encodeIfPresent(surveyProgress, forKey: .surveyProgress)
        try container.encodeIfPresent(lastSurveyDate, forKey: .lastSurveyDate)
        try container.encode(appLaunchCount, forKey: .appLaunchCount)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(signupTime, forKey: .signupTime)
        try container.encodeIfPresent(uniqueId, forKey: .uniqueId)
    }
}