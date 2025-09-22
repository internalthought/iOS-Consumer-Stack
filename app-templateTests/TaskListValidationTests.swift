import XCTest
@testable import app_template

class TaskListValidationTests: XCTestCase {

    func testTaskListJSONStructure() {
        let url = URL(fileURLWithPath: #file)
            .deletingLastPathComponent() // app-templateTests
            .deletingLastPathComponent() // app-template
            .deletingLastPathComponent() // workspace
            .appendingPathComponent("TASKLIST.json")
        let data = try! Data(contentsOf: url)

        XCTAssertTrue(isValidTaskListStructure(data), "TASKLIST.json must have valid structure with required task fields")
    }

    // Helper function that will be implemented to validate the structure
    private func isValidTaskListStructure(_ data: Data) -> Bool {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            guard let phases = json["phases"] as? [[String: Any]], !phases.isEmpty else { return false }
            for phase in phases {
                guard let name = phase["name"] as? String, let tasks = phase["tasks"] as? [[String: Any]] else { return false }
                for task in tasks {
                    let requiredFields = ["id", "description", "dependencies", "tools", "verificationSteps", "prerequisites", "sequentialLinks", "status"]
                    for field in requiredFields {
                        if task[field] == nil { return false }
                    }
                    // Ensure arrays are present and valid
                    if !(task["dependencies"] is [String]) || !(task["tools"] is [String]) || !(task["verificationSteps"] is [String]) || !(task["prerequisites"] is [String]) || !(task["sequentialLinks"] is [String]) {
                        return false
                    }
                    // status should be string
                    if !(task["status"] is String) {
                        return false
                    }
                }
            }
            return true
        } catch {
            return false
        }
    }
}