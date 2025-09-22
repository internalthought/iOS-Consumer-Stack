import Foundation
import SwiftData

/// Model representing a survey question
@Model
final class Question: Identifiable, Equatable, Decodable, Encodable {
    var id: Int
    var text: String
    var type: String // e.g., "multiple_choice", "text", "rating"
    var options: [String]? // For multiple choice

    enum CodingKeys: String, CodingKey {
        case id, text, type, options
    }

    init(id: Int, text: String, type: String, options: [String]? = nil) {
        self.id = id
        self.text = text
        self.type = type
        self.options = options
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.text = try container.decode(String.self, forKey: .text)
        self.type = try container.decode(String.self, forKey: .type)
        self.options = try container.decodeIfPresent([String].self, forKey: .options)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(options, forKey: .options)
    }
}