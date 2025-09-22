import Foundation

@MainActor
protocol LegacyAppCoordinatorProtocol: AnyObject {
    var appState: AppState { get set }
    var services: ServiceLocator { get }
    var configurationError: ConfigurationError? { get set }

    func handleAppLaunch() async
    func validateConfiguration()
    func verifySubscriptionOnLaunch() async

    func startSignIn()
    func startOnboarding()
    func startPaywall()
    func startMainTabs(force: Bool)
}