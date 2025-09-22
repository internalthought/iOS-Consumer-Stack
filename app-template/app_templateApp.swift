import SwiftUI

@main
struct AppTemplateApp: App {
    @StateObject private var coordinator = AppCoordinator(services: .shared)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
        }
    }
}