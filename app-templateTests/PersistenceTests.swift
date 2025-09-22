import Foundation
import Testing
import SwiftData
@testable import app_template

@Suite
struct PersistenceTests {

    // Helper to create in-memory ModelContainer for testing SwiftData models
    private func makeModelContainer() throws -> ModelContainer {
        let schema = Schema([
            SurveyResponse.self,
            Question.self,
            OnboardingScreen.self,
            UserProfile.self,
            Item.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test
    func testSurveyResponsePersistence_in_SwiftData() throws {
        // Given: Create a ModelContainer
        let container = try makeModelContainer()
        let context = ModelContext(container)

        // When: Try to insert a SurveyResponse
        let response = SurveyResponse(surveyId: 1, questionId: 1, userId: "testUser", response: "Yes")

        context.insert(response)

        // Then: Verify it was inserted and can be fetched
        try context.save()

        let descriptor = FetchDescriptor<SurveyResponse>()
        let results = try context.fetch(descriptor)

        #expect(results.count == 1)
        #expect(results[0].surveyId == 1)
        #expect(results[0].response == "Yes")
    }

    @Test
    func testSurveyResponseUpdates_in_SwiftData() throws {
        // Given: Insert a response
        let container = try makeModelContainer()
        let context = ModelContext(container)
        let response = SurveyResponse(surveyId: 1, questionId: 1, userId: "testUser", response: "Yes")
        context.insert(response)
        try context.save()

        // When: Update the response
        response.response = "No"

        // Then: Verify update persists
        try context.save()

        let descriptor = FetchDescriptor<SurveyResponse>()
        let results = try context.fetch(descriptor)

        #expect(results.count == 1)
        #expect(results[0].response == "No")
    }

    @Test
    func testSurveyResponseDeletion_from_SwiftData() throws {
        // Given: Insert a response
        let container = try makeModelContainer()
        let context = ModelContext(container)
        let response = SurveyResponse(surveyId: 1, questionId: 1, userId: "testUser", response: "Yes")
        context.insert(response)
        try context.save()

        // When: Delete the response
        context.delete(response)

        // Then: Verify it's gone
        try context.save()

        let descriptor = FetchDescriptor<SurveyResponse>()
        let results = try context.fetch(descriptor)

        #expect(results.isEmpty)
    }

    @Test
    func testSurveyResponseFilterByUserId() throws {
        // Given: Insert multiple responses for different users
        let container = try makeModelContainer()
        let context = ModelContext(container)
        let response1 = SurveyResponse(surveyId: 1, questionId: 1, userId: "user1", response: "Yes")
        let response2 = SurveyResponse(surveyId: 1, questionId: 2, userId: "user2", response: "No")
        let response3 = SurveyResponse(surveyId: 1, questionId: 1, userId: "user1", response: "Maybe")

        context.insert(response1)
        context.insert(response2)
        context.insert(response3)
        try context.save()

        // When: Fetch responses for user1
        let descriptor = FetchDescriptor<SurveyResponse>(
            predicate: #Predicate<SurveyResponse> { $0.userId == "user1" }
        )
        let results = try context.fetch(descriptor)

        // Then: Only user1's responses are returned
        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.userId == "user1" })
    }

    @Test
    func testQuestionPersistence_in_SwiftData() throws {
        // Given
        let container = try makeModelContainer()
        let context = ModelContext(container)

        // When
        let question = Question(id: 1, text: "What is your favorite color?", type: "multiple_choice", options: ["Red", "Blue", "Green"])

        context.insert(question)

        // Then
        try context.save()

        let descriptor = FetchDescriptor<Question>()
        let results = try context.fetch(descriptor)

        #expect(results.count == 1)
        #expect(results[0].id == 1)
        #expect(results[0].text == "What is your favorite color?")
        #expect(results[0].type == "multiple_choice")
        #expect(results[0].options == ["Red", "Blue", "Green"])
    }

    @Test
    func testQuestionMultipleChoiceWithOptions() throws {
        // Given
        let container = try makeModelContainer()
        let context = ModelContext(container)

        // When
        let question1 = Question(id: 1, text: "Q1", type: "text")
        let question2 = Question(id: 2, text: "Q2", type: "multiple_choice", options: ["Yes", "No"])

        context.insert(question1)
        context.insert(question2)
        try context.save()

        // Then
        let descriptor = FetchDescriptor<Question>()
        let results = try context.fetch(descriptor)

        #expect(results.count == 2)
        #expect(results.filter { $0.id == 1 }.first?.options == nil)
        #expect(results.filter { $0.id == 2 }.first?.options?.count == 2)
    }

    @Test
    func testOnboardingScreenPersistence_in_SwiftData() throws {
        // Given
        let container = try makeModelContainer()
        let context = ModelContext(container)

        // When
        let screen = OnboardingScreen(id: 1, title: "Welcome", description: "Get started", imageUrl: "img.jpg", buttonText: "Start", nextId: 2)

        context.insert(screen)

        // Then
        try context.save()

        let descriptor = FetchDescriptor<OnboardingScreen>()
        let results = try context.fetch(descriptor)

        #expect(results.count == 1)
        #expect(results[0].id == 1)
        #expect(results[0].title == "Welcome")
        #expect(results[0].description == "Get started")
        #expect(results[0].nextId == 2)
    }

    @Test
    func testUserProfilePersistence_in_SwiftData() throws {
        // Given
        let container = try makeModelContainer()
        let context = ModelContext(container)

        // When
        let profile = UserProfile(userId: "user123", email: "user@example.com", displayName: "John Doe", isPremium: false)

        context.insert(profile)

        // Then
        try context.save()

        let descriptor = FetchDescriptor<UserProfile>()
        let results = try context.fetch(descriptor)

        #expect(results.count == 1)
        #expect(results[0].userId == "user123")
        #expect(results[0].email == "user@example.com")
        #expect(results[0].isPremium == false)
    }
}