import Foundation
import SwiftUI
import os

/// Coordinator for managing app navigation flow with MVVM-C pattern
@MainActor
class AppCoordinator: ObservableObject, AppCoordinatorProtocol {
    let navigationPath = NavigationPath()
    @Published var appState: AppState = .launchLoading
    @Published var isVerifyingSubscription = false
    @Published var hasCompletedInitialGate = false
    var errorOccurred: Error?
    let services: ServiceLocator

    @Published var configurationError: ConfigurationError? = nil

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app-template", category: "Navigation")

    private let minLaunchDisplayDuration: TimeInterval = 0.7
    private let restoreWaitWithCredential: TimeInterval = 1.2
    private let restoreWaitNoCredential: TimeInterval = 0.15

    init(services: ServiceLocator = .shared) {
        self.services = services
    }

    func startValueScreens() {
        appState = .valueScreens
    }

    func startSignIn() {
        appState = .signIn
    }

    func startOnboarding() {
        appState = .onboarding
    }

    func startSurvey() {
        appState = .survey
    }

    func startPaywall() {
        appState = .paywall
    }

    /// Attempt to start main tabs with subscription verification
    /// Checks subscription status before allowing access to main app
    func startMainTabs(force: Bool = false) async {
        isVerifyingSubscription = true
        logger.info("startMainTabs called. force=\(force, privacy: .public)")

        if force {
            appState = .mainTabs
            isVerifyingSubscription = false
            logger.info("startMainTabs: forcing mainTabs without verification")
            return
        }

        let isSubscribed: Bool
        do {
            isSubscribed = try await services.revenueCatService.syncSubscriptionStatus()
            logger.info("startMainTabs: syncSubscriptionStatus result=\(isSubscribed, privacy: .public)")
        } catch {
            services.errorHandler.logError(error, category: "Navigation")
            logger.error("startMainTabs: syncSubscriptionStatus error \(error.localizedDescription, privacy: .public) - falling back to isSubscriptionActive()")
            isSubscribed = await services.revenueCatService.isSubscriptionActive()
            logger.info("startMainTabs: fallback isSubscriptionActive=\(isSubscribed, privacy: .public)")
        }

        if isSubscribed {
            appState = .mainTabs
            logger.info("startMainTabs: gating allowed -> mainTabs")
        } else {
            await routeToPaywallIfNeeded()
        }

        isVerifyingSubscription = false
    }

    func startMainTabs() async {
        await startMainTabs(force: false)
    }

    /// Verify subscription status on app launch or resume
    /// Useful for handling subscription changes while app is in background
    @MainActor
    func verifySubscriptionOnLaunch() async {
        // Avoid interfering during initial gate
        if appState == .launchLoading || !hasCompletedInitialGate {
            return
        }

        isVerifyingSubscription = true
        logger.info("verifySubscriptionOnLaunch called")

        let isSubscribed: Bool
        do {
            isSubscribed = try await services.revenueCatService.syncSubscriptionStatus()
            logger.info("verifySubscriptionOnLaunch: syncSubscriptionStatus result=\(isSubscribed, privacy: .public)")
        } catch {
            services.errorHandler.logError(error, category: "Navigation")
            logger.error("verifySubscriptionOnLaunch: syncSubscriptionStatus error \(error.localizedDescription, privacy: .public) - fallback to isSubscriptionActive()")
            isSubscribed = await services.revenueCatService.isSubscriptionActive()
            logger.info("verifySubscriptionOnLaunch: fallback isSubscriptionActive=\(isSubscribed, privacy: .public)")
        }

        if appState == .mainTabs && !isSubscribed {
            appState = .paywall
            logger.warning("verifySubscriptionOnLaunch: detected expired sub while in mainTabs -> redirecting to paywall")
            services.errorHandler.logError(
                NSError(domain: "AppCoordinator",
                       code: 2,
                       userInfo: [NSLocalizedDescriptionKey: "Subscription expired while app was in background"]),
                category: "Navigation"
            )
        } else if appState == .paywall && isSubscribed {
            appState = .mainTabs
            logger.info("verifySubscriptionOnLaunch: user subscribed but on paywall -> redirecting to mainTabs")
        }

        isVerifyingSubscription = false
    }

    /// Navigate to paywall for upgrade from within main tabs
    /// Useful for subscription upgrades from Home or Profile tabs
    func upgradeFromTabs() {
        appState = .paywall
    }

    func handleError(_ error: Error) {
        self.errorOccurred = error
    }

    func validateConfiguration() {
        switch Configuration.validateConfiguration() {
        case .success:
            configurationError = nil
        case .failure(let error):
            configurationError = error
        }
    }

    /// Handles app launch routing:
    /// - If signed in: skip value screens/sign-in/onboarding and gate to paywall/mainTabs based on subscription
    /// - If not signed in: start value screens
    func handleAppLaunch() async {
        if hasCompletedInitialGate {
            logger.info("handleAppLaunch: already completed; skipping")
            return
        }

        hasCompletedInitialGate = false
        appState = .launchLoading
        validateConfiguration()
        logger.info("handleAppLaunch: starting launch gate")

        let startTime = CACurrentMediaTime()

        // Optimistically check if the user likely signed in before (local Apple credential present)
        let hadLocalCredential = services.authenticationService.hasLocalAppleCredential()
        logger.info("handleAppLaunch: hasLocalAppleCredential=\(hadLocalCredential, privacy: .public)")

        let waitTime: TimeInterval = hadLocalCredential ? restoreWaitWithCredential : restoreWaitNoCredential
        let restored: Bool = hadLocalCredential
            ? await services.authenticationService.waitForRestoredSession(maxWait: waitTime)
            : false
        logger.info("handleAppLaunch: session restored within \(waitTime, privacy: .public)s = \(restored, privacy: .public)")

        var nextState: AppState = .valueScreens

        if restored {
            isVerifyingSubscription = true
            let isSubscribed: Bool
            do {
                isSubscribed = try await services.revenueCatService.syncSubscriptionStatus()
                logger.info("handleAppLaunch: syncSubscriptionStatus result=\(isSubscribed, privacy: .public)")
            } catch {
                services.errorHandler.logError(error, category: "Navigation")
                logger.error("handleAppLaunch: syncSubscriptionStatus error \(error.localizedDescription, privacy: .public) - falling back to isSubscriptionActive()")
                isSubscribed = await services.revenueCatService.isSubscriptionActive()
                logger.info("handleAppLaunch: fallback isSubscriptionActive=\(isSubscribed, privacy: .public)")
            }
            nextState = isSubscribed ? .mainTabs : .paywall
            isVerifyingSubscription = false
        } else {
            nextState = .valueScreens
        }

        // Enforce minimum display duration of the loading screen to avoid blink/flicker
        let elapsed = CACurrentMediaTime() - startTime
        let remaining = max(0, minLaunchDisplayDuration - elapsed)
        if remaining > 0 {
            do {
                try await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            } catch {
                // Ignore sleep cancellation
            }
        }

        appState = nextState
        hasCompletedInitialGate = true
        logger.info("handleAppLaunch: completed -> appState=\(String(describing: nextState), privacy: .public)")
    }

    /// Defensive routing to paywall that re-checks entitlement and auto-bounces to mainTabs if already subscribed
    func routeToPaywallIfNeeded() async {
        let active = await services.revenueCatService.isSubscriptionActive()
        if active {
            appState = .mainTabs
            logger.info("routeToPaywallIfNeeded: user already subscribed -> mainTabs")
        } else {
            appState = .paywall
            logger.info("routeToPaywallIfNeeded: user not subscribed -> paywall")
        }
    }
}