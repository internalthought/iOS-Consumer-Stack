import Foundation
import Combine

/// ViewModel for survey feature managing questions and responses
@MainActor
class SurveyViewModel: ObservableObject {
    @Published var questions: [QuestionDTO] = []
    @Published var currentIndex: Int = 0
    @Published var responses: [Int: String] = [:]
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var isCompleted = false

    private let service: SupabaseServiceProtocol
    private let surveyId: Int
    private var userId: String?
    private let authService: AuthenticationServiceProtocol

    private var pendingResponses: [SurveyResponseDTO] = []

    init(service: SupabaseServiceProtocol, authService: AuthenticationServiceProtocol = ServiceLocator.shared.authenticationService, surveyId: Int, userId: String? = nil) {
        self.service = service
        self.authService = authService
        self.surveyId = surveyId
        self.userId = userId
    }

    func loadQuestions() async {
        isLoading = true
        error = nil
        do {
            let loadedQuestions = try await service.fetchSurveyQuestions(surveyId: surveyId)
            questions = loadedQuestions
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func selectResponse(for questionId: Int, response: String) {
        responses[questionId] = response
        Task {
            await saveResponse(questionId: questionId, response: response)
        }

        let totalQuestions = questions.count
        if responses.count == totalQuestions {
            isCompleted = true
        }
    }

    private func saveResponse(questionId: Int, response: String) async {
        let dto = SurveyResponseDTO(
            surveyId: surveyId,
            questionId: questionId,
            userId: userId,
            response: response
        )

        if let uid = userId, !uid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                try await service.saveSurveyResponses([dto], for: uid)
            } catch {
                self.error = error.localizedDescription
            }
            return
        }

        if let fetched = await authService.getUserIdentifier(), !fetched.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.userId = fetched
            let payload = SurveyResponseDTO(
                surveyId: surveyId,
                questionId: questionId,
                userId: fetched,
                response: response
            )
            do {
                try await service.saveSurveyResponses([payload], for: fetched)
            } catch {
                self.error = error.localizedDescription
            }
        } else {
            pendingResponses.append(dto)
        }
    }

    func attachUserAndFlushIfPossible() async {
        if userId == nil || userId?.isEmpty == true {
            if let fetched = await authService.getUserIdentifier(), !fetched.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                userId = fetched
            }
        }
        if let uid = userId, !uid.isEmpty {
            await flushPendingResponses(with: uid)
        }
    }

    func flushPendingResponses(with userId: String) async {
        let payloads = pendingResponses.map {
            SurveyResponseDTO(
                surveyId: $0.surveyId,
                questionId: $0.questionId,
                userId: userId,
                response: $0.response,
                createdAt: $0.createdAt
            )
        }
        guard !payloads.isEmpty else { return }
        do {
            try await service.saveSurveyResponses(payloads, for: userId)
            pendingResponses.removeAll()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func nextQuestion() -> Bool {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
            return true
        }
        return false
    }

    func currentQuestion() -> QuestionDTO? {
        return questions.count > currentIndex ? questions[currentIndex] : nil
    }

    func hasNext() -> Bool {
        return currentIndex < questions.count - 1
    }

    var progress: Double {
        if questions.isEmpty { return 0 }
        return Double(currentIndex + 1) / Double(questions.count)
    }
}