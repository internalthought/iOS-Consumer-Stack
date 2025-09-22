import Foundation
import Testing
@testable import app_template

struct ModelTests {

    @Test func testQuestionEquatable() {
        // Given
        let question1 = Question(id: 1, text: "What?", type: "text", options: nil)
        let question2 = Question(id: 1, text: "What?", type: "text", options: nil)
        let question3 = Question(id: 1, text: "Different", type: "text", options: nil)

        // Then
        #expect(question1 == question2)
        #expect(question1 != question3)
    }

    @Test func testQuestionDecodable() {
        // Given
        let json = """
        {"id": 1, "text": "Rate it", "type": "rating", "options": ["1", "2", "3"]}
        """
        .data(using: .utf8)!

        // When & Then
        let decoded = try? JSONDecoder().decode(Question.self, from: json)
        #expect(decoded != nil)
        #expect(decoded?.id == 1)
        #expect(decoded?.type == "rating")
        #expect(decoded?.options == ["1", "2", "3"])
    }

    @Test func testSurveyResponseEquatable() {
        // Given
        let response1 = SurveyResponse(surveyId: 1, questionId: 1, userId: "user1", response: "Yes")
        let response2 = SurveyResponse(surveyId: 1, questionId: 1, userId: "user1", response: "Yes")
        let response3 = SurveyResponse(surveyId: 1, questionId: 1, userId: "user1", response: "No")

        // Then
        #expect(response1 == response2)
        #expect(response1 != response3)
    }

    @Test func testSurveyResponseEncodable() {
        // Given
        let response = SurveyResponse(surveyId: 1, questionId: 1, userId: "user1", response: "Yes")

        // When
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try? encoder.encode(response)
        let jsonString = String(data: data!, encoding: .utf8)

        // Then
        #expect(jsonString != nil)
        #expect(jsonString?.contains("\"survey_id\":1") == true)
        #expect(jsonString?.contains("\"user_id\":\"user1\"") == true)
        #expect(jsonString?.contains("\"response\":\"Yes\"") == true)
    }

    @Test func testOnboardingScreenEquatable() {
        // Given
        let screen1 = OnboardingScreen(id: 1, title: "Title", description: "Desc", imageUrl: nil, buttonText: "Next", nextId: nil)
        let screen2 = OnboardingScreen(id: 1, title: "Title", description: "Desc", imageUrl: nil, buttonText: "Next", nextId: nil)
        let screen3 = OnboardingScreen(id: 1, title: "Different", description: "Desc", imageUrl: nil, buttonText: "Next", nextId: nil)

        // Then
        #expect(screen1 == screen2)
        #expect(screen1 != screen3)
    }

    @Test func testOnboardingScreenDecodable() {
        // Given
        let json = """
        {"id": 1, "title": "Welcome", "description": "Start", "image_url": "img.jpg", "button_text": "Go", "next_id": 2}
        """
        .data(using: .utf8)!

        // When & Then
        let decoded = try? JSONDecoder().decode(OnboardingScreen.self, from: json)
        #expect(decoded != nil)
        #expect(decoded?.id == 1)
        #expect(decoded?.imageUrl == "img.jpg")
        #expect(decoded?.nextId == 2)
    }
}