import Foundation

let fileURL = URL(fileURLWithPath: "./TASKLIST.json")

guard let data = try? Data(contentsOf: fileURL) else {
    // Failed to load TASKLIST.json
    exit(1)
}

func isValidTaskListStructure(_ data: Data) -> (Bool, String?) {
    do {
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        guard let phases = json["phases"] as? [[String: Any]], !phases.isEmpty else {
            return (false, "Missing or invalid 'phases' array")
        }
        for (index, phaseDict) in phases.enumerated() {
            guard let name = phaseDict["name"] as? String, let tasks = phaseDict["tasks"] as? [[String: Any]] else {
                return (false, "Phase \(index) missing name or tasks")
            }
            for taskIndex in tasks.indices {
                let task = tasks[taskIndex]
                let requiredFields = ["id", "description", "dependencies", "tools", "verificationSteps", "prerequisites", "sequentialLinks", "status"]
                for field in requiredFields {
                    if task[field] == nil {
                        return (false, "Task \(taskIndex) in phase \(index) missing field: \(field)")
                    }
                }
                // Check array types
                if !(task["dependencies"] is [String]) || !(task["tools"] is [String]) || !(task["verificationSteps"] is [String]) || !(task["prerequisites"] is [String]) || !(task["sequentialLinks"] is [String]) {
                    return (false, "Task \(taskIndex) in phase \(index) has invalid array field")
                }
                // Check status is string
                if !(task["status"] is String) {
                    return (false, "Task \(taskIndex) in phase \(index) has invalid status")
                }
            }
        }
        return (true, nil)
    } catch let error {
        return (false, "Invalid JSON: \(error.localizedDescription)")
    }
}

let (isValid, issue) = isValidTaskListStructure(data)

if isValid {
    // TASKLIST.json has correct structure with required task fields present
    exit(0)
} else {
    // Invalid TASKLIST.json: \(issue ?? "Unknown error")
    exit(1)
}