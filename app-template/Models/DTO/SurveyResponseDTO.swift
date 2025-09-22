import Foundation

struct SurveyResponseDTO: Codable, Equatable {
    let surveyId: Int
    let questionId: Int
    let userId: String?
    let response: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case surveyId = "survey_id"
        case questionId = "question_id"
        case userId = "user_id"
        case response
        case createdAt = "created_at"
    }

    init(surveyId: Int, questionId: Int, userId: String?, response: String, createdAt: Date = Date()) {
        self.surveyId = surveyId
        self.questionId = questionId
        self.userId = userId
        self.response = response
        self.createdAt = createdAt
    }
}