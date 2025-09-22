import Foundation
import Supabase

/// ServiceLocator for dependency injection of services
public class ServiceLocator {
    public static let shared = ServiceLocator()

    let supabaseClient: SupabaseClient

    let supabaseService: SupabaseServiceProtocol
    lazy var errorHandler: ErrorHandler = ErrorHandler(serviceLocator: self)
    lazy var revenueCatService: RevenueCatServiceProtocol = RevenueCatService(serviceLocator: self)
    lazy var authenticationService: AuthenticationServiceProtocol = AuthenticationService(serviceLocator: self)
    lazy var analyticsService: AnalyticsServiceProtocol = AnalyticsService()

    public init() {
        guard let supabaseURL = URL(string: Configuration.supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }
        self.supabaseClient = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: Configuration.supabaseAnonKey
        )
        self.supabaseService = SupabaseService(client: self.supabaseClient)
    }

    func onboardingViewModel() async -> OnboardingViewModel {
        return await OnboardingViewModel(supabaseService: supabaseService, authService: authenticationService)
    }

    func signInViewModel(coordinator: AppCoordinatorProtocol) async -> SignInViewModel {
        return await SignInViewModel(authenticationService: authenticationService, coordinator: coordinator)
    }
}