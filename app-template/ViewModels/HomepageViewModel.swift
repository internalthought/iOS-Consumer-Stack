import Foundation
import Combine

/// ViewModel for the Home tab with subscription-aware content
class HomepageViewModel: ObservableObject {
    /// Service for checking subscription status
    private let revenueCatService: RevenueCatServiceProtocol

    /// Whether the user has premium features available
    @Published var premiumFeaturesAvailable: Bool = false

    /// Whether the view is currently loading subscription status
    @Published var isLoading: Bool = false

    /// Initialize with services
    init(revenueCatService: RevenueCatServiceProtocol) {
        self.revenueCatService = revenueCatService
    }

    /// Check current subscription status
    /// - Task: Updates premiumFeaturesAvailable based on subscription status
    @MainActor
    func checkSubscription() async {
        isLoading = true
        let isActive = await revenueCatService.isSubscriptionActive()
        premiumFeaturesAvailable = isActive
        isLoading = false
    }
}