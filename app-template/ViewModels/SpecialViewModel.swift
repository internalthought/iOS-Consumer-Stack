import Foundation
import Combine

/// ViewModel for the Special tab with subscription-aware content and special features management
class SpecialViewModel: ObservableObject {
    /// Service for checking subscription status
    private let revenueCatService: RevenueCatServiceProtocol

    /// Whether the user has premium features available
    @Published var premiumFeaturesAvailable: Bool = false

    /// Whether the view is currently loading subscription status
    @Published var isLoading: Bool = false

    /// List of special features available to the user
    @Published var specialFeatures: [SpecialFeature] = []

    /// Initialize with services
    /// - Parameter revenueCatService: Service for subscription management
    init(revenueCatService: RevenueCatServiceProtocol) {
        self.revenueCatService = revenueCatService
        setupSpecialFeatures()
    }

    /// Set up placeholder special features for demonstration
    /// This method initializes the special features list with extensible structure
    private func setupSpecialFeatures() {
        specialFeatures = [
            SpecialFeature(
                title: "Premium Features",
                description: "Access advanced tools and exclusive content",
                iconName: "star.fill",
                isPremium: true
            ),
            SpecialFeature(
                title: "Special Offers",
                description: "Limited-time discounts and promotions",
                iconName: "tag.fill",
                isPremium: false
            ),
            SpecialFeature(
                title: "Exclusive Content",
                description: "Premium articles and tutorials",
                iconName: "book.fill",
                isPremium: true
            ),
            SpecialFeature(
                title: "VIP Support",
                description: "Priority customer assistance",
                iconName: "person.fill.questionmark",
                isPremium: true
            )
        ]
    }

    /// Check current subscription status and update available features
    /// - Task: Updates premiumFeaturesAvailable and filters special features based on subscription status
    @MainActor
    func checkSubscription() async {
        isLoading = true
        let isActive = await revenueCatService.isSubscriptionActive()
        premiumFeaturesAvailable = isActive
        if !isActive {
            specialFeatures = specialFeatures.filter { !$0.isPremium }
        }
        isLoading = false
    }

    /// Placeholder method for future special feature actions
    /// - Parameter feature: The special feature to interact with
    func performSpecialAction(for feature: SpecialFeature) {
        // TODO: Implement specific actions for each special feature
    }
}

/// Struct representing a special feature with extensible properties
struct SpecialFeature: Identifiable {
    /// Unique identifier for the feature
    let id = UUID()

    /// Display title of the special feature
    let title: String

    /// Description of what the feature provides
    let description: String

    /// System icon name for visual representation
    let iconName: String

    /// Whether this feature requires premium subscription
    let isPremium: Bool
}