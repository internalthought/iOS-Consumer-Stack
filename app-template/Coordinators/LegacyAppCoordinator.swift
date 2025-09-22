import Foundation
import Combine

@MainActor
final class LegacyAppCoordinator: ObservableObject, LegacyAppCoordinatorProtocol {
    @Published var appState: AppState = .launchLoading
    @Published var configurationError: ConfigurationError?

    let services: ServiceLocator

    init(services: ServiceLocator = .shared) {
        self.services = services
    }

    func handleAppLaunch() async {
        appState = .valueScreens
    }

    func validateConfiguration() {
        switch Configuration.validateConfiguration() {
        case .success:
            configurationError = nil
        case .failure(let error):
            configurationError = error
        }
    }

    func verifySubscriptionOnLaunch() async {
        let isActive = await services.revenueCatService.isSubscriptionActive()
        if isActive {
            await startMainTabs(force: true)
        }
    }

    func startSignIn() {
        appState = .signIn
    }

    func startOnboarding() {
        appState = .onboarding
    }

    func startPaywall() {
        appState = .paywall
    }

    func startMainTabs(force: Bool = false) {
        appState = .mainTabs
    }
}