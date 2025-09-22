import Foundation
import Combine

/// ViewModel for the Profile tab with subscription management
class ProfileViewModel: ObservableObject {
    /// Service for managing subscription operations
    private let revenueCatService: RevenueCatServiceProtocol

    private let supabaseService: SupabaseServiceProtocol
    private let authService: AuthenticationServiceProtocol

    /// Whether the view is currently loading
    @Published var isLoading: Bool = false

    /// Whether the user has active subscription
    @Published var isSubscribed: Bool = false

    /// String representation of subscription status
    @Published var subscriptionStatus: String = ""

    /// User's display name
    @Published var userName: String = "User"

    @Published var isDeleting: Bool = false
    @Published var deletionError: String?
    @Published var deletionCompleted: Bool = false

    /// Initialize with services
    init(
        revenueCatService: RevenueCatServiceProtocol = ServiceLocator.shared.revenueCatService,
        supabaseService: SupabaseServiceProtocol = ServiceLocator.shared.supabaseService,
        authService: AuthenticationServiceProtocol = ServiceLocator.shared.authenticationService
    ) {
        self.revenueCatService = revenueCatService
        self.supabaseService = supabaseService
        self.authService = authService
    }

    /// Check current subscription status
    /// - Task: Updates subscription status and related properties
    @MainActor
    func checkSubscriptionStatus() async {
        isLoading = true
        let isActive = await revenueCatService.isSubscriptionActive()
        isSubscribed = isActive
        subscriptionStatus = isActive ? "Active" : "Inactive"
        isLoading = false
    }

    /// Initiate upgrade to premium
    /// - Task: Handle the upgrade process (navigational or direct purchase)
    @MainActor
    func upgradeToPremium() async {
        // ... existing code ...
    }

    @MainActor
    func deleteAccount() async {
        isDeleting = true
        deletionError = nil
        do {
            try await supabaseService.deleteCurrentUserAccount()
            try await authService.signOut()
            deletionCompleted = true
        } catch {
            deletionError = error.localizedDescription
        }
        isDeleting = false
    }
}