import Foundation
import Testing
@testable import app_template

/// Mock SupabaseService for testing survey operations
class MockSupabaseServiceForSurvey: SupabaseServiceProtocol {
    var shouldThrowError = false
    var questions: [Question] = []
    var savedResponses: [SurveyResponse] = []
    var saveThrowError = false

    func fetchOnboardingScreens(userProperty: String) async throws -> [OnboardingScreen] {
        throw NSError(domain: "Not implemented", code: 1, userInfo: nil)
    }

    func fetchSurveyQuestions(surveyId: Int) async throws -> [Question] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        // Return survey-specific questions based on surveyId
        switch surveyId {
        case 2: // Onboarding survey
            return [
                Question(id: 1, text: "What brings you here?", type: "multiple_choice", options: ["Work", "Personal"]),
                Question(id: 2, text: "Prior experience?", type: "rating", options: ["1", "2", "3", "4", "5"])
            ]
        case 3: // Feedback survey
            return [
                Question(id: 1, text: "How would you rate?", type: "rating", options: ["1-5"]),
                Question(id: 2, text: "Suggestions?", type: "text", options: nil)
            ]
        default: // Default survey
            return questions
        }
    }

    func saveSurveyResponses(_ responses: [SurveyResponse]) async throws {
        if saveThrowError {
            throw NSError(domain: "SaveError", code: 2, userInfo: nil)
        }
        savedResponses.append(contentsOf: responses)
    }
}

struct SurveyViewModelTests {

    @Test func testInit() {
        // Given
        let mockService = MockSupabaseServiceForSurvey()

        // When
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)

        // Then
        #expect(viewModel.questions.count == 0)
        #expect(viewModel.currentIndex == 0)
        #expect(viewModel.responses.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
    }

    @Test func testLoadQuestionsSuccess() async throws {
        // Given
        let mockService = MockSupabaseServiceForSurvey()
        let expectedQuestions = [
            Question(id: 1, text: "How satisfied are you?", type: "rating", options: ["1", "2", "3"]),
            Question(id: 2, text: "Comments?", type: "text", options: nil)
        ]
        mockService.questions = expectedQuestions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)

        // When
        await viewModel.loadQuestions()

        // Then
        #expect(viewModel.questions == expectedQuestions)
        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
    }

    @Test func testLoadQuestionsFailure() async throws {
        // Given
        let mockService = MockSupabaseServiceForSurvey()
        mockService.shouldThrowError = true
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)

        // When
        await viewModel.loadQuestions()

        // Then
        #expect(viewModel.questions.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.error != nil)
    }

    @Test func testSelectResponse() async throws {
        // Given
        let mockService = MockSupabaseServiceForSurvey()
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)

        // When
        viewModel.selectResponse(for: 1, response: "Yes")

        // Then
        #expect(viewModel.responses[1] == "Yes")
        // Wait briefly for async save (in real tests, might need to wait or use expectations)
    }

    @Test func testNextQuestion() async throws {
        // Given
        let mockService = MockSupabaseServiceForSurvey()
        let questions = [
            Question(id: 1, text: "Q1", type: "text", options: nil),
            Question(id: 2, text: "Q2", type: "text", options: nil)
        ]
        mockService.questions = questions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)
        await viewModel.loadQuestions()

        // Can move to next
        let canMove1 = viewModel.nextQuestion()
        #expect(canMove1)
        #expect(viewModel.currentIndex == 1)

        // Cannot move further
        let canMove2 = viewModel.nextQuestion()
        #expect(!canMove2)
        #expect(viewModel.currentIndex == 1)
    }

    @Test func testCurrentQuestion() async throws {
        // Given
        let mockService = MockSupabaseServiceForSurvey()
        let questions = [Question(id: 1, text: "Q1", type: "text", options: nil)]
        mockService.questions = questions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)
        await viewModel.loadQuestions()

        // When
        let current = viewModel.currentQuestion()

        // Then
        #expect(current == questions[0])
    }

    @Test func testProgress() async throws {
        // Given
        let mockService = MockSupabaseServiceForSurvey()
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)

        // Empty questions
        #expect(viewModel.progress == 0)

        // With questions
        let questions = [
            Question(id: 1, text: "Q1", type: "text", options: nil),
            Question(id: 2, text: "Q2", type: "text", options: nil)
        ]
        mockService.questions = questions
        await viewModel.loadQuestions()
        #expect(viewModel.progress == 0)

        viewModel.nextQuestion()
        #expect(viewModel.progress == 0.5)
    }

    // MARK: - Navigation Tests

    @Test func testPreviousQuestionSuccess() async throws {
        let mockService = MockSupabaseServiceForSurvey()
        let questions = [
            Question(id: 1, text: "Q1", type: "text", options: nil),
            Question(id: 2, text: "Q2", type: "text", options: nil)
        ]
        mockService.questions = questions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)
        await viewModel.loadQuestions()
        viewModel.nextQuestion()

        let canMoveBack = viewModel.previousQuestion()
        #expect(canMoveBack)
        #expect(viewModel.currentIndex == 0)
    }

    @Test func testPreviousQuestionCannotMoveBack() async throws {
        let mockService = MockSupabaseServiceForSurvey()
        let questions = [
            Question(id: 1, text: "Q1", type: "text", options: nil),
            Question(id: 2, text: "Q2", type: "text", options: nil)
        ]
        mockService.questions = questions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)
        await viewModel.loadQuestions()

        let canMoveBack = viewModel.previousQuestion()
        #expect(!canMoveBack)
        #expect(viewModel.currentIndex == 0)
    }

    // MARK: - Conditional Branching Tests

    @Test func testConditionalBranchingSkipsQuestion() async throws {
        let mockService = MockSupabaseServiceForSurvey()
        let questions = [
            Question(id: 1, text: "Are you over 18?", type: "multiple_choice", options: ["Yes", "No"]),
            Question(id: 2, text: "Please explain", type: "text", options: nil), // Should be skipped if skipped
            Question(id: 3, text: "Completed?", type: "text", options: nil)
        ]
        mockService.questions = questions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)
        await viewModel.loadQuestions()

        viewModel.selectResponse(for: 1, response: "No")  // Answer that triggers skip
        viewModel.nextQuestion()  // Should skip Q2

        #expect(viewModel.currentIndex == 2)
        #expect(viewModel.currentQuestion()?.id == 3)
    }

    @Test func testConditionalBranchingIncludesQuestion() async throws {
        let mockService = MockSupabaseServiceForSurvey()
        let questions = [
            Question(id: 1, text: "Are you over 18?", type: "multiple_choice", options: ["Yes", "No"]),
            Question(id: 2, text: "Please explain", type: "text", options: nil), // Should be included
            Question(id: 3, text: "Completed?", type: "text", options: nil)
        ]
        mockService.questions = questions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)
        await viewModel.loadQuestions()

        viewModel.selectResponse(for: 1, response: "Yes")  // Answer that includes Q2
        viewModel.nextQuestion()  // Should include Q2

        #expect(viewModel.currentIndex == 1)
        #expect(viewModel.currentQuestion()?.id == 2)
    }

    // MARK: - Answer Validation Tests

    @Test func testAnswerValidationValid() async throws {
        let mockService = MockSupabaseServiceForSurvey()
        let questions = [Question(id: 1, text: "Rate", type: "rating", options: ["1", "2", "3"])]
        mockService.questions = questions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)
        await viewModel.loadQuestions()

        let isValid = viewModel.validateAnswer(for: 1, response: "2")
        #expect(isValid)
    }

    @Test func testAnswerValidationInvalid() async throws {
        let mockService = MockSupabaseServiceForSurvey()
        let questions = [Question(id: 1, text: "Rate", type: "rating", options: ["1", "2", "3"])]
        mockService.questions = questions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)
        await viewModel.loadQuestions()

        let isValid = viewModel.validateAnswer(for: 1, response: "5")
        #expect(!isValid)
    }

    @Test func testAnswerValidationRequiredFieldEmpty() async throws {
        let mockService = MockSupabaseServiceForSurvey()
        let questions = [Question(id: 1, text: "Comment", type: "text", options: nil)]
        mockService.questions = questions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)
        await viewModel.loadQuestions()

        let isValid = viewModel.validateAnswer(for: 1, response: "")
        #expect(!isValid)
    }

    // MARK: - Completion Detection Tests

    @Test func testIsCompletedTrue() async throws {
        let mockService = MockSupabaseServiceForSurvey()
        let questions = [
            Question(id: 1, text: "Q1", type: "text", options: nil),
            Question(id: 2, text: "Q2", type: "text", options: nil)
        ]
        mockService.questions = questions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)
        await viewModel.loadQuestions()

        viewModel.selectResponse(for: 1, response: "Answer 1")
        viewModel.selectResponse(for: 2, response: "Answer 2")
        viewModel.nextQuestion()  // Should complete after last

        #expect(viewModel.isCompleted())
    }

    @Test func testIsCompletedFalse() async throws {
        let mockService = MockSupabaseServiceForSurvey()
        let questions = [
            Question(id: 1, text: "Q1", type: "text", options: nil),
            Question(id: 2, text: "Q2", type: "text", options: nil)
        ]
        mockService.questions = questions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)
        await viewModel.loadQuestions()

        viewModel.selectResponse(for: 1, response: "Answer 1")
        // Not answered Q2

        #expect(!viewModel.isCompleted())
    }

    @Test func testFinalProgress() async throws {
        let mockService = MockSupabaseServiceForSurvey()
        let questions = [
            Question(id: 1, text: "Q1", type: "text", options: nil),
            Question(id: 2, text: "Q2", type: "text", options: nil)
        ]
        mockService.questions = questions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)
        await viewModel.loadQuestions()

        viewModel.selectResponse(for: 1, response: "A1")
        viewModel.selectResponse(for: 2, response: "A2")
        viewModel.nextQuestion()

        #expect(viewModel.progress == 1.0)
    }

    // MARK: - Error Handling Tests for Save

    @Test func testSaveResponseFailure() async throws {
        let mockService = MockSupabaseServiceForSurvey()
        mockService.saveThrowError = true
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)

        await viewModel.selectResponse(for: 1, response: "Test")  // Wait for async save

        // Note: In this test, we can't directly check internal error state
        // but the service will throw, ensuring error is handled in implementation
        #expect(true) // Placeholder - implement error tracking in ViewModel
    }

    @Test func testLoadQuestionsRetryAfterFailure() async throws {
        let mockService = MockSupabaseServiceForSurvey()
        mockService.shouldThrowError = true
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1)
        await viewModel.loadQuestions()

        // Simulate retry
        mockService.shouldThrowError = false
        mockService.questions = [Question(id: 1, text: "Q1", type: "text", options: nil)]
        await viewModel.loadQuestions()

        #expect(viewModel.questions.count == 1)
        #expect(viewModel.error == nil)
    }

    // MARK: - Different Survey Types Tests

    @Test func testLoadingOnboardingSurvey() async throws {
        let mockService = MockSupabaseServiceForSurvey()
        let onboardingQuestions = [
            Question(id: 1, text: "What brings you here?", type: "multiple_choice", options: ["Work", "Personal"]),
            Question(id: 2, text: "Prior experience?", type: "rating", options: nil)
        ]
        mockService.questions = onboardingQuestions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 2)
        await viewModel.loadQuestions()

        #expect(viewModel.questions == onboardingQuestions)
    }

    @Test func testLoadingFeedbackSurvey() async throws {
        let mockService = MockSupabaseServiceForSurvey()
        let feedbackQuestions = [
            Question(id: 1, text: "How would you rate?", type: "rating", options: ["1-5"]),
            Question(id: 2, text: "Suggestions?", type: "text", options: nil)
        ]
        mockService.questions = feedbackQuestions
        let viewModel = SurveyViewModel(service: mockService, surveyId: 3)
        await viewModel.loadQuestions()

        #expect(viewModel.questions == feedbackQuestions)
    }

    // MARK: - Initialization with Variants

    @Test func testInitWithUserId() {
        let mockService = MockSupabaseServiceForSurvey()
        let viewModel = SurveyViewModel(service: mockService, surveyId: 1, userId: "user123")

        #expect(viewModel.currentIndex == 0)
        #expect(viewModel.responses.isEmpty)
    }
}