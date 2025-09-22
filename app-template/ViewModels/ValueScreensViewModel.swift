import Foundation
import Combine

/// Model representing a value proposition screen
struct ValueScreen {
    /// The title of the value screen
    let title: String
    /// The description text explaining the value
    let description: String
    /// The name of the image asset to display
    let imageName: String
}

/// ViewModel for managing value proposition screens and navigation logic
/// Handles the display and progression through value screens in the onboarding flow
class ValueScreensViewModel: ObservableObject {
    /// Array of value screens to display
    let valueScreens: [ValueScreen] = [
        ValueScreen(
            title: "Welcome to Our App",
            description: "Discover amazing features that will transform your experience.",
            imageName: "welcome_image"
        ),
        ValueScreen(
            title: "Personalized Experience",
            description: "Get tailored recommendations based on your preferences.",
            imageName: "personalized_image"
        ),
        ValueScreen(
            title: "Seamless Integration",
            description: "Connect with your favorite services effortlessly.",
            imageName: "integration_image"
        ),
        ValueScreen(
            title: "Get Started Today",
            description: "Join thousands of satisfied users and unlock your potential.",
            imageName: "get_started_image"
        )
    ]

    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    /// Total number of value screens
    var totalScreens: Int {
        return valueScreens.count
    }

    /// Computed property to get the current value screen
    /// - Returns: The current ValueScreen or nil if index is out of bounds
    func currentScreen() -> ValueScreen? {
        guard currentIndex >= 0 && currentIndex < valueScreens.count else {
            error = "Invalid screen index: \(currentIndex)"
            return nil
        }
        return valueScreens[currentIndex]
    }

    /// Advances to the next value screen
    /// - Returns: True if successfully moved to next screen, false if at the end
    func nextScreen() -> Bool {
        guard currentIndex < valueScreens.count - 1 else {
            return false
        }
        currentIndex += 1
        return true
    }

    /// Goes back to the previous value screen
    /// - Returns: True if successfully moved to previous screen, false if at the beginning
    func previousScreen() -> Bool {
        guard currentIndex > 0 else {
            return false
        }
        currentIndex -= 1
        return true
    }

    /// Skips to the last value screen
    /// - Returns: True if successfully skipped, false if already at the end
    func skipToEnd() -> Bool {
        guard currentIndex < valueScreens.count - 1 else {
            return false
        }
        currentIndex = valueScreens.count - 1
        return true
    }

    /// Checks if there is a next screen available
    /// - Returns: True if there are more screens after the current one
    func hasNext() -> Bool {
        return currentIndex < valueScreens.count - 1
    }

    /// Checks if there is a previous screen available
    /// - Returns: True if there are screens before the current one
    func hasPrevious() -> Bool {
        return currentIndex > 0
    }

    /// Resets the view model to the first screen
    func reset() {
        currentIndex = 0
        error = nil
        isLoading = false
    }

    /// Gets the progress as a fraction (0.0 to 1.0)
    /// - Returns: Current progress through the screens
    func progress() -> Double {
        guard totalScreens > 0 else { return 0.0 }
        return Double(currentIndex + 1) / Double(totalScreens)
    }
}