import Foundation
import SwiftData

/// Model representing a survey response
@Model
final class SurveyResponse: Equatable, Decodable, Encodable {
    var surveyId: Int
    var questionId: Int
    var userId: String?
    var response: String
    var createdAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case surveyId, questionId, userId, response, createdAt
    }

    init(surveyId: Int, questionId: Int, userId: String?, response: String, createdAt: Date = Date()) {
        self.surveyId = surveyId
        self.questionId = questionId
        self.userId = userId
        self.response = response
        self.createdAt = createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.surveyId = try container.decode(Int.self, forKey: .surveyId)
        self.questionId = try container.decode(Int.self, forKey: .questionId)
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
        self.response = try container.decode(String.self, forKey: .response)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(surveyId, forKey: .surveyId)
        try container.encode(questionId, forKey: .questionId)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encode(response, forKey: .response)
        try container.encode(createdAt, forKey: .createdAt)
    }

    // Manually implement Equatable since SwiftData @Model classes can't automatically conform
    static func == (lhs: SurveyResponse, rhs: SurveyResponse) -> Bool {
        return lhs.surveyId == rhs.surveyId &&
                lhs.questionId == rhs.questionId &&
                lhs.userId == rhs.userId &&
                lhs.response == rhs.response &&
                lhs.createdAt == rhs.createdAt
    }
}