import Foundation
import Testing
@testable import app_template

/// Mock SupabaseService for testing
class MockSupabaseService: SupabaseServiceProtocol {
    var screens: [OnboardingScreen] = []
    var shouldThrowError = false

    func fetchOnboardingScreens(userProperty: String) async throws -> [OnboardingScreen] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        return screens
    }

    func fetchSurveyQuestions(surveyId: Int) async throws -> [Question] {
        return []
    }

    func saveSurveyResponses(_ responses: [SurveyResponse]) async throws {
        // Do nothing
    }
}

struct OnboardingViewModelTests {

    @Test func testInit() {
        // Given
        let mockService = MockSupabaseService()

        // When
        let viewModel = OnboardingViewModel(service: mockService)

        // Then
        #expect(viewModel.screens.wrappedValue.isEmpty)
        #expect(viewModel.currentIndex.wrappedValue == 0)
        #expect(!viewModel.isLoading.wrappedValue)
    }

    @Test func testLoadScreensSuccess() async throws {
        // Given
        let mockService = MockSupabaseService()
        let expectedScreens = [
            OnboardingScreen(id: 1, title: "Welcome", description: "Let's get started", imageUrl: nil, buttonText: "Next", nextId: 2),
            OnboardingScreen(id: 2, title: "Features", description: "Explore features", imageUrl: nil, buttonText: "Continue", nextId: nil)
        ]
        mockService.screens = expectedScreens
        let viewModel = OnboardingViewModel(service: mockService)

        // When
        await viewModel.loadScreens(userProperty: "beginner")

        // Then
        #expect(viewModel.screens.wrappedValue == expectedScreens)
        #expect(viewModel.currentIndex.wrappedValue == 0)
        #expect(!viewModel.isLoading.wrappedValue)
        #expect(viewModel.error.wrappedValue == nil)
    }

    @Test func testLoadScreensFailure() async throws {
        // Given
        let mockService = MockSupabaseService()
        mockService.shouldThrowError = true
        let viewModel = OnboardingViewModel(service: mockService)

        // When
        await viewModel.loadScreens(userProperty: "beginner")

        // Then
        #expect(viewModel.screens.wrappedValue.isEmpty)
        #expect(!viewModel.isLoading.wrappedValue)
        #expect(viewModel.error.wrappedValue != nil)
    }

    @Test func testNextScreen() async throws {
        // Given
        let mockService = MockSupabaseService()
        let screens = [
            OnboardingScreen(id: 1, title: "Screen 1", description: "", imageUrl: nil, buttonText: "Next", nextId: 2),
            OnboardingScreen(id: 2, title: "Screen 2", description: "", imageUrl: nil, buttonText: "Done", nextId: nil)
        ]
        mockService.screens = screens
        let viewModel = OnboardingViewModel(service: mockService)
        await viewModel.loadScreens(userProperty: "beginner")

        // When & Then can move
        let canMove1 = viewModel.nextScreen()
        #expect(canMove1)
        #expect(viewModel.currentIndex.wrappedValue == 1)

        // Cannot move further
        let canMove2 = viewModel.nextScreen()
        #expect(!canMove2)
        #expect(viewModel.currentIndex.wrappedValue == 1)
    }

    @Test func testCurrentScreen() async throws {
        // Given
        let mockService = MockSupabaseService()
        let screens = [OnboardingScreen(id: 1, title: "Current", description: "", imageUrl: nil, buttonText: "Next", nextId: nil)]
        mockService.screens = screens
        let viewModel = OnboardingViewModel(service: mockService)
        await viewModel.loadScreens(userProperty: "beginner")

        // When
        let current = viewModel.currentScreen()

        // Then
        #expect(current == screens[0])
    }
}