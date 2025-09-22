import Foundation
import SwiftData

/// Model representing an onboarding screen loaded from Supabase
@Model
final class OnboardingScreen: Identifiable, Decodable, Encodable {
    var id: Int
    var title: String
    var descriptionText: String
    var description: String {
        get { descriptionText }
        set { descriptionText = newValue }
    }
    var imageUrl: String?
    var buttonText: String
    var nextId: Int?

    enum CodingKeys: String, CodingKey {
        case id, title
        case descriptionText = "description"
        case imageUrl = "image_url"
        case buttonText = "button_text"
        case nextId = "next_id"
    }

    init(id: Int, title: String, description: String, imageUrl: String?, buttonText: String, nextId: Int?) {
        self.id = id
        self.title = title
        self.descriptionText = description
        self.imageUrl = imageUrl
        self.buttonText = buttonText
        self.nextId = nextId
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.descriptionText = try container.decode(String.self, forKey: .descriptionText)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.buttonText = try container.decode(String.self, forKey: .buttonText)
        self.nextId = try container.decodeIfPresent(Int.self, forKey: .nextId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(descriptionText, forKey: .descriptionText)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(buttonText, forKey: .buttonText)
        try container.encodeIfPresent(nextId, forKey: .nextId)
    }
}

extension OnboardingScreen: Equatable {
    static func == (lhs: OnboardingScreen, rhs: OnboardingScreen) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.descriptionText == rhs.descriptionText &&
               lhs.imageUrl == rhs.imageUrl &&
               lhs.buttonText == rhs.buttonText &&
               lhs.nextId == rhs.nextId
    }
}