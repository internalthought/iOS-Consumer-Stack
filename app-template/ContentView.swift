import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @ObservedObject private var errorHandler = ServiceLocator.shared.errorHandler
    @Environment(\.scenePhase) private var scenePhase
    @State private var didRunLaunch = false

    var body: some View {
        ZStack {
            switch coordinator.appState {
            case .launchLoading:
                InitialLoadingView()

            case .valueScreens:
                ValueScreensView(
                    viewModel: ValueScreensViewModel(),
                    onComplete: {
                        coordinator.startSignIn()
                    }
                )

            case .signIn:
                SignInView(
                    viewModel: SignInViewModel(
                        authenticationService: coordinator.services.authenticationService,
                        coordinator: coordinator
                    ),
                    onSuccess: {
                        // Navigation handled in SignInViewModel
                    }
                )

            case .onboarding:
                OnboardingView(
                    viewModel: OnboardingViewModel(
                        supabaseService: coordinator.services.supabaseService,
                        authService: coordinator.services.authenticationService
                    ),
                    onComplete: {
                        coordinator.startPaywall()
                    }
                )

            case .survey:
                EmptyView()
                    .onAppear {
                        coordinator.startPaywall()
                    }

            case .paywall:
                PaywallView(
                    viewModel: PaywallViewModel(
                        revenueCatService: coordinator.services.revenueCatService,
                        onPurchase: {
                            Task { await coordinator.startMainTabs(force: true) }
                        }
                    ),
                    onPurchase: {
                        Task { await coordinator.startMainTabs(force: true) }
                    }
                )

            case .mainTabs:
                TabView {
                    HomepageView(
                        viewModel: HomepageViewModel(revenueCatService: coordinator.services.revenueCatService)
                    )
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    LibraryView(
                        viewModel: LibraryViewModel(revenueCatService: coordinator.services.revenueCatService)
                    )
                    .tabItem {
                        Label("Library", systemImage: "books.vertical")
                    }
                    SpecialView(
                        viewModel: SpecialViewModel(revenueCatService: coordinator.services.revenueCatService)
                    )
                    .tabItem {
                        Label("Special", systemImage: "star")
                    }
                    ProfileView(
                        viewModel: ProfileViewModel(revenueCatService: coordinator.services.revenueCatService)
                    )
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                }
            }

            if let banner = errorHandler.userVisibleError {
                VStack {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(banner.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(banner.message)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(3)
                        }
                        Spacer()
                        Button {
                            errorHandler.userVisibleError = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(radius: 6)
                    .padding(.horizontal)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: banner.id)
                .accessibilityIdentifier("GlobalErrorBanner")
            }

            if let configError = coordinator.configurationError {
                ConfigurationErrorView(
                    error: configError,
                    isProduction: Configuration.isProductionEnvironment,
                    onRetry: {
                        coordinator.validateConfiguration()
                    }
                )
                .ignoresSafeArea()
                .transition(.opacity)
                .accessibilityIdentifier("ConfigurationErrorView")
            }
        }
        // Disable implicit animations during initial gate to prevent visual flicker when leaving loading state
        .animation(nil, value: coordinator.appState)
        .task {
            coordinator.validateConfiguration()
            if !didRunLaunch {
                didRunLaunch = true
                await coordinator.handleAppLaunch()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active, coordinator.hasCompletedInitialGate {
                Task { @MainActor in
                    await coordinator.verifySubscriptionOnLaunch()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppCoordinator())
}