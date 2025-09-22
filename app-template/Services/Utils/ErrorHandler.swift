import Foundation
import OSLog
import Combine

protocol ErrorHandlerProtocol {
    init(serviceLocator: ServiceLocator)

    func logError(_ error: Error, category: String)
}

struct UserVisibleError: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
}

class ErrorHandler: ObservableObject, ErrorHandlerProtocol {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "app-template"

    private let networkLogger = Logger(subsystem: subsystem, category: "Network")
    private let databaseLogger = Logger(subsystem: subsystem, category: "Database")
    private let iapLogger = Logger(subsystem: subsystem, category: "IAP")
    private let authLogger = Logger(subsystem: subsystem, category: "Auth")
    private let paywallLogger = Logger(subsystem: subsystem, category: "Paywall")
    private let navigationLogger = Logger(subsystem: subsystem, category: "Navigation")
    private let generalLogger = Logger(subsystem: subsystem, category: "General")

    private let serviceLocator: ServiceLocator

    @Published var userVisibleError: UserVisibleError?

    required init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
    }

    func logError(_ error: Error, category: String = "General") {
        let logger = loggerFor(category: category)
        logger.error("Error occurred (\(category, privacy: .public)): \(error.localizedDescription, privacy: .public)")
    }

    func recover(from error: Error, attempt: Int) async throws -> Bool {
        return attempt < 3
    }

    func userFriendlyMessage(for error: Error) -> String {
        return error.localizedDescription
    }

    func handleErrorPublisher<T>(_ publisher: AnyPublisher<T, Error>) -> AnyPublisher<T, Never> {
        return publisher.catch { error -> AnyPublisher<T, Never> in
            let category = self.categorizeError(error)
            self.logError(error, category: category)

            if category == "Network" || category == "IAP" || category == "Auth" {
                self.presentUserError(title: "Something went wrong", message: self.userFriendlyMessage(for: error))
            }

            return Empty().eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }

    func presentUserError(title: String, message: String) {
        DispatchQueue.main.async {
            self.userVisibleError = UserVisibleError(title: title, message: message)
        }
    }

    private func categorizeError(_ error: Error) -> String {
        let description = error.localizedDescription.lowercased()
        if description.contains("network") || description.contains("connection") || description.contains("internet") {
            return "Network"
        } else if description.contains("database") || description.contains("supabase") || description.contains("db") {
            return "Database"
        } else if description.contains("iap") || description.contains("purchase") || description.contains("subscription") || description.contains("revenuecat") {
            return "IAP"
        } else if description.contains("auth") || description.contains("signin") || description.contains("login") {
            return "Auth"
        } else if description.contains("paywall") {
            return "Paywall"
        } else if description.contains("navigate") || description.contains("coordinator") {
            return "Navigation"
        }
        return "General"
    }

    private func loggerFor(category: String) -> Logger {
        switch category {
        case "Network":
            return networkLogger
        case "Database", "Db":
            return databaseLogger
        case "IAP":
            return iapLogger
        case "Auth":
            return authLogger
        case "Paywall":
            return paywallLogger
        case "Navigation":
            return navigationLogger
        default:
            return generalLogger
        }
    }
}