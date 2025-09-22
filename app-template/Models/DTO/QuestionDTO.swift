import Foundation

struct QuestionDTO: Codable, Equatable, Identifiable {
    let id: Int
    let text: String
    let type: String
    let options: [String]?
}