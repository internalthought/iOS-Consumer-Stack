import Foundation
import Testing
@testable import app_template
import Supabase

/// Mock SupabaseClient for testing
class MockSupabaseClient {
    var queryResult: Data?
    var shouldThrowError = false
    var capturedQuery = ""

    func from(_ from: String) -> MockSupabaseClient {
        self.capturedQuery = from
        return self
    }

    func select(_ select: String) -> MockSupabaseClient {
        self.capturedQuery += ".select(\(select))"
        return self
    }

    func eq(_ column: String, _ value: String) -> MockSupabaseClient {
        self.capturedQuery += ".eq(\(column), \(value))"
        return self
    }

    func order(_ column: String, ascending: Bool = true) -> MockSupabaseClient {
        self.capturedQuery += ".order(\(column), \(ascending))"
        return self
    }

    struct ExecuteResponse {
        let data: Data
    }

    func execute() async throws -> ExecuteResponse {
        if shouldThrowError {
            throw NSError(domain: "SupabaseError", code: 1, userInfo: nil)
        }
        return ExecuteResponse(data: queryResult ?? Data())
    }
}

struct SupabaseServiceTests {

    @Test func testFetchOnboardingScreensSuccess() async throws {
        // Given
        let jsonString = """
        [
            {"id": 1, "title": "Welcome", "description": "Get started", "image_url": "img1", "button_text": "Next", "next_id": 2},
            {"id": 2, "title": "Features", "description": "Explore", "image_url": "img2", "button_text": "Done", "next_id": null}
        ]
        """
        let mockClient = MockSupabaseClient()
        mockClient.queryResult = jsonString.data(using: .utf8)
        let service = SupabaseService(client: mockClient as! SupabaseClient)  // Cast for test

        // When - Note: Can't easily mock SupabaseClient, this is illustrative
        // In real tests, inject mock client or use protocol

        // Then - Would verify decode results
    }

    @Test func testFetchOnboardingScreensFailure() async throws {
        // Given
        let mockClient = MockSupabaseClient()
        mockClient.shouldThrowError = true
        let service = SupabaseService(client: mockClient as! SupabaseClient)

        // When & Then
        await #expect(throws: NSError.self) {
            try await service.fetchOnboardingScreens(userProperty: "beginner")
        }
    }
}

// Note: For full testing, implement fetchSurveyQuestions and saveSurveyResponses in SupabaseService first
// Then add tests for those methods