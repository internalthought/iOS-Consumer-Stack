import Foundation

protocol AnalyticsServiceProtocol {
    func logEvent(_ name: String, properties: [String: Any])
}