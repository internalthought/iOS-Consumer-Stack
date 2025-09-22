import Foundation
import OSLog

final class AnalyticsService: AnalyticsServiceProtocol {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app-template", category: "Analytics")

    func logEvent(_ name: String, properties: [String: Any] = [:]) {
        let props = properties.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        logger.info("Analytics event: \(name, privacy: .public) props: \(props, privacy: .public)")
    }
}