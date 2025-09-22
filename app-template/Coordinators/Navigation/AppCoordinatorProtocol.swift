import Foundation
import SwiftUI

@MainActor
protocol AppCoordinatorProtocol {
    var navigationPath: NavigationPath { get }
    var appState: AppState { get set }
    var services: ServiceLocator { get }

    func startOnboarding()
    func startSurvey()
    func startPaywall()
    func startMainTabs() async
    func handleError(_ error: Error)
}