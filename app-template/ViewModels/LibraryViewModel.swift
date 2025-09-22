import Foundation
import Combine

/// ViewModel for the Library tab with subscription-aware content management
class LibraryViewModel: ObservableObject {
    /// Service for checking subscription status
    private let revenueCatService: RevenueCatServiceProtocol

    /// Whether the user has premium features available
    @Published var premiumFeaturesAvailable: Bool = false

    /// Whether the view is currently loading subscription status
    @Published var isLoading: Bool = false

    /// List of saved items in the library (placeholder content)
    @Published var libraryItems: [LibraryItem] = []

    /// Initialize with services
    /// - Parameter revenueCatService: Service for subscription management
    init(revenueCatService: RevenueCatServiceProtocol) {
        self.revenueCatService = revenueCatService
        // Initialize with placeholder data
        loadPlaceholderData()
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

    /// Add a new item to the library
    /// - Parameter item: The item to add
    func addItem(_ item: LibraryItem) {
        libraryItems.append(item)
    }

    /// Remove an item from the library
    /// - Parameter item: The item to remove
    func removeItem(_ item: LibraryItem) {
        libraryItems.removeAll { $0.id == item.id }
    }

    /// Load placeholder data for demonstration
    private func loadPlaceholderData() {
        libraryItems = [
            LibraryItem(title: "Sample Item 1", description: "This is a placeholder item"),
            LibraryItem(title: "Sample Item 2", description: "Another placeholder item"),
            LibraryItem(title: "Sample Item 3", description: "Yet another placeholder item")
        ]
    }
}

/// Model representing an item in the library
struct LibraryItem: Identifiable, Hashable {
    /// Unique identifier for the item
    let id = UUID()
    /// Title of the item
    let title: String
    /// Description of the item
    let description: String
}