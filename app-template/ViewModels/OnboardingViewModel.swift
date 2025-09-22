import Foundation
import SwiftData
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var questions: [QuestionDTO] = []
    @Published var currentIndex: Int = 0
    @Published var answers: [Int: String] = [:]
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let supabaseService: SupabaseServiceProtocol
    private let authService: AuthenticationServiceProtocol

    init(supabaseService: SupabaseServiceProtocol, authService: AuthenticationServiceProtocol) {
        self.supabaseService = supabaseService
        self.authService = authService
    }

    func fetchQuestions() async {
        isLoading = true
        error = nil
        do {
            questions = try await supabaseService.fetchSurveyQuestions(surveyId: 1)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func nextQuestion() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
        }
    }

    func answerCurrentQuestion(with answer: String) {
        let currentQuestion = questions[currentIndex]
        answers[currentQuestion.id] = answer
    }
    
    func submitSurvey() async {
        guard let userId = await authService.getUserIdentifier() else {
            self.error = "User not authenticated."
            return
        }

        let surveyId = 1

        let responses: [SurveyResponseDTO] = answers.map {
            SurveyResponseDTO(
                surveyId: surveyId,
                questionId: $0.key,
                userId: userId,
                response: $0.value
            )
        }

        do {
            try await supabaseService.saveSurveyResponses(responses, for: userId)
        } catch {
            self.error = error.localizedDescription
        }
    }
}