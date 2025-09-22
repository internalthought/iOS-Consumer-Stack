import Foundation
import SwiftData

/// Service for managing local persistence using SwiftData
final class LocalStorageService {

    // MARK: - Properties

    private let container: ModelContainer

    private var context: ModelContext {
        ModelContext(container)
    }

    // MARK: - Initialization

    init(container: ModelContainer) {
        self.container = container
    }

    // MARK: - SurveyResponse Operations

    func saveResponse(_ response: SurveyResponse) throws {
        context.insert(response)
        try context.save()
    }

    func fetchResponses(for userId: String? = nil) throws -> [SurveyResponse] {
        if let userId = userId {
            let descriptor = FetchDescriptor<SurveyResponse>(
                predicate: #Predicate<SurveyResponse> { $0.userId == userId }
            )
            return try context.fetch(descriptor)
        } else {
            let descriptor = FetchDescriptor<SurveyResponse>()
            return try context.fetch(descriptor)
        }
    }

    func deleteResponse(_ response: SurveyResponse) throws {
        context.delete(response)
        try context.save()
    }

    func updateResponse(_ response: SurveyResponse) throws {
        // Since response is updated in place, just save
        try context.save()
    }

    // MARK: - Question Operations

    func saveQuestion(_ question: Question) throws {
        context.insert(question)
        try context.save()
    }

    func fetchQuestion(id: Int) throws -> Question? {
        let descriptor = FetchDescriptor<Question>(
            predicate: #Predicate<Question> { $0.id == id }
        )
        let results = try context.fetch(descriptor)
        return results.first
    }

    func fetchAllQuestions() throws -> [Question] {
        let descriptor = FetchDescriptor<Question>()
        return try context.fetch(descriptor)
    }

    func deleteQuestion(_ question: Question) throws {
        context.delete(question)
        try context.save()
    }

    // MARK: - OnboardingScreen Operations

    func saveOnboardingScreen(_ screen: OnboardingScreen) throws {
        context.insert(screen)
        try context.save()
    }

    func fetchOnboardingScreen(id: Int) throws -> OnboardingScreen? {
        let descriptor = FetchDescriptor<OnboardingScreen>(
            predicate: #Predicate<OnboardingScreen> { $0.id == id }
        )
        let results = try context.fetch(descriptor)
        return results.first
    }

    func fetchAllOnboardingScreens() throws -> [OnboardingScreen] {
        let descriptor = FetchDescriptor<OnboardingScreen>()
        return try context.fetch(descriptor)
    }

    func deleteOnboardingScreen(_ screen: OnboardingScreen) throws {
        context.delete(screen)
        try context.save()
    }

    // MARK: - UserProfile Operations

    func saveUserProfile(_ profile: UserProfile) throws {
        context.insert(profile)
        try context.save()
    }

    func fetchUserProfile(userId: String?) throws -> UserProfile? {
        if let userId = userId {
            let descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate<UserProfile> { $0.userId == userId }
            )
            let results = try context.fetch(descriptor)
            return results.first
        } else {
            let descriptor = FetchDescriptor<UserProfile>()
            let results = try context.fetch(descriptor)
            return results.first  // Assuming single profile, or most recent
        }
    }

    func fetchAllUserProfiles() throws -> [UserProfile] {
        let descriptor = FetchDescriptor<UserProfile>()
        return try context.fetch(descriptor)
    }

    func deleteUserProfile(_ profile: UserProfile) throws {
        context.delete(profile)
        try context.save()
    }

    func updateUserProfile(_ profile: UserProfile) throws {
        try context.save()
    }

    // MARK: - Bulk Operations

    func saveSurveyResponses(_ responses: [SurveyResponse]) throws {
        for response in responses {
            context.insert(response)
        }
        try context.save()
    }

    func saveQuestions(_ questions: [Question]) throws {
        for question in questions {
            context.insert(question)
        }
        try context.save()
    }

    func saveOnboardingScreens(_ screens: [OnboardingScreen]) throws {
        for screen in screens {
            context.insert(screen)
        }
        try context.save()
    }

    // MARK: - Clear Operations

    func clearAllData(for entity: Any.Type) throws {
        if entity == SurveyResponse.self {
            let descriptor = FetchDescriptor<SurveyResponse>()
            let items = try context.fetch(descriptor)
            for item in items {
                context.delete(item)
            }
        } else if entity == Question.self {
            let descriptor = FetchDescriptor<Question>()
            let items = try context.fetch(descriptor)
            for item in items {
                context.delete(item)
            }
        } else if entity == OnboardingScreen.self {
            let descriptor = FetchDescriptor<OnboardingScreen>()
            let items = try context.fetch(descriptor)
            for item in items {
                context.delete(item)
            }
        } else if entity == UserProfile.self {
            let descriptor = FetchDescriptor<UserProfile>()
            let items = try context.fetch(descriptor)
            for item in items {
                context.delete(item)
            }
        }
        try context.save()
    }

    func clearAllData() throws {
        try clearAllData(for: SurveyResponse.self)
        try clearAllData(for: Question.self)
        try clearAllData(for: OnboardingScreen.self)
        try clearAllData(for: UserProfile.self)
    }
}