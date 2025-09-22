import Foundation

struct OnboardingScreenDTO: Codable, Equatable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let imageUrl: String?
    let buttonText: String
    let nextId: Int?

    enum CodingKeys: String, CodingKey {
        case id, title
        case description = "description"
        case imageUrl = "image_url"
        case buttonText = "button_text"
        case nextId = "next_id"
    }
}