import Foundation

/// Enum representing the current state/flow of the application
public enum AppState {
    case launchLoading
    case valueScreens
    case signIn
    case onboarding
    case survey
    case paywall
    case mainTabs
}