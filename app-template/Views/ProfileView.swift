import SwiftUI
import SwiftData
import RevenueCat
import RevenueCatUI

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel
    @EnvironmentObject private var coordinator: AppCoordinator

    @State private var showDeleteConfirm = false
    @State private var showDeletionError = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    Text("Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

                    if viewModel.isLoading {
                        ProgressView("Loading profile...")
                    } else {
                        ScrollView {
                            VStack(spacing: 24) {
                                // User info section
                                VStack(spacing: 16) {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Text(viewModel.userName.prefix(1).uppercased())
                                                .font(.title)
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                        )

                                    VStack(spacing: 4) {
                                        Text(viewModel.userName)
                                            .font(.title2)
                                            .fontWeight(.semibold)

                                        Text("Premium User")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical)

                                // Subscription status section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Subscription Status")
                                        .font(.headline)
                                        .padding(.horizontal)

                                    HStack {
                                        Image(systemName: viewModel.isSubscribed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(viewModel.isSubscribed ? .green : .red)
                                            .font(.title2)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(viewModel.isSubscribed ? "Premium Active" : "Free Plan")
                                                .font(.body)
                                                .fontWeight(.medium)

                                            if !viewModel.isSubscribed {
                                                Text("Upgrade for premium features")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }

                                        Spacer()

                                        if viewModel.isSubscribed {
                                            Image(systemName: "crown.fill")
                                                .foregroundColor(.yellow)
                                                .font(.title3)
                                        }
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }

                                // Settings section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Settings")
                                        .font(.headline)
                                        .padding(.horizontal)

                                    VStack(spacing: 0) {
                                        SettingsRow(
                                            icon: "bell.fill",
                                            title: "Notifications",
                                            isOn: .constant(true)
                                        )

                                        Divider().padding(.horizontal)

                                        SettingsRow(
                                            icon: "shield.fill",
                                            title: "Privacy",
                                            isOn: .constant(false)
                                        )

                                        Divider().padding(.horizontal)

                                        SettingsRow(
                                            icon: "questionmark.circle.fill",
                                            title: "Help & Support",
                                            isOn: .constant(false)
                                        )
                                    }
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }

                                // Subscription management section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Account Management")
                                        .font(.headline)
                                        .padding(.horizontal)

                                    VStack(spacing: 0) {
                                        if viewModel.isSubscribed {
                                            Button(action: {
                                                // TODO: Navigate to manage subscription
                                            }) {
                                                HStack {
                                                    Image(systemName: "creditcard.fill")
                                                        .foregroundColor(.blue)
                                                        .font(.title3)
                                                        .frame(width: 24, height: 24)

                                                    Text("Manage Subscription")
                                                        .foregroundColor(.primary)
                                                        .font(.body)

                                                    Spacer()

                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(.secondary)
                                                        .font(.caption)
                                                }
                                                .padding()
                                            }

                                            Divider().padding(.horizontal)

                                            Button(action: {
                                                // TODO: Restore purchases
                                                Task {
                                                    await viewModel.upgradeToPremium()
                                                }
                                            }) {
                                                HStack {
                                                    Image(systemName: "arrow.clockwise.circle.fill")
                                                        .foregroundColor(.green)
                                                        .font(.title3)
                                                        .frame(width: 24, height: 24)

                                                    Text("Restore Purchase")
                                                        .foregroundColor(.primary)
                                                        .font(.body)

                                                    Spacer()

                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(.secondary)
                                                        .font(.caption)
                                                }
                                                .padding()
                                            }
                                        } else {
                                            Button(action: {
                                                coordinator.startPaywall()
                                            }) {
                                                HStack {
                                                    Image(systemName: "crown.fill")
                                                        .foregroundColor(.yellow)
                                                        .font(.title3)
                                                        .frame(width: 24, height: 24)

                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text("Upgrade to Premium")
                                                            .foregroundColor(.primary)
                                                            .font(.body)

                                                        Text("Unlock advanced features")
                                                            .foregroundColor(.secondary)
                                                            .font(.caption)
                                                    }

                                                    Spacer()

                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(.secondary)
                                                        .font(.caption)
                                                }
                                                .padding()
                                            }
                                        }

                                        Divider().padding(.horizontal)

                                        Button(role: .destructive) {
                                            showDeleteConfirm = true
                                        } label: {
                                            HStack {
                                                Image(systemName: "trash.fill")
                                                    .foregroundColor(.red)
                                                    .font(.title3)
                                                    .frame(width: 24, height: 24)

                                                Text("Delete Account")
                                                    .foregroundColor(.red)
                                                    .font(.body)

                                                Spacer()

                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.secondary)
                                                    .font(.caption)
                                            }
                                            .padding()
                                        }
                                    }
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }

                                Spacer(minLength: 40)
                            }
                            .padding(.vertical)
                        }
                    }

                    Spacer()
                }

                if viewModel.isDeleting {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Deleting account...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                }
            }
        }
        .onChange(of: viewModel.deletionError) { _, newValue in
            if newValue != nil {
                showDeletionError = true
            }
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteAccount() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete your account and data. This action cannot be undone.")
        }
        .alert("Error", isPresented: $showDeletionError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.deletionError ?? "Unknown error")
        }
        .onAppear {
            Task {
                await viewModel.checkSubscriptionStatus()
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var isOn: Binding<Bool>? = nil

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24, height: 24)

            Text(title)
                .foregroundColor(.primary)
                .font(.body)

            Spacer()

            if let isOn = isOn {
                Toggle("", isOn: isOn)
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding()
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel(revenueCatService: MockRevenueCatServiceForProfile()))
}

/// Mock service for preview
class MockRevenueCatServiceForProfile: RevenueCatServiceProtocol {
    var isActive = true

    func fetchOfferings() async throws -> Offerings {
        throw NSError(domain: "Preview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented in preview mock"])
    }

    func purchase(package: Package) async throws -> CustomerInfo {
        throw NSError(domain: "Preview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented in preview mock"])
    }

    func getCustomerInfo() async throws -> CustomerInfo {
        throw NSError(domain: "Preview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented in preview mock"])
    }

    func restorePurchases() async throws -> CustomerInfo {
        throw NSError(domain: "Preview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented in preview mock"])
    }

    func isSubscriptionActive() async -> Bool {
        return isActive
    }

    func linkPurchaser(with identifier: String) async throws { }

    func configurePurchaserIdentification() async { }

    func loadPaywall() async throws -> PaywallViewController {
        throw NSError(domain: "Preview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented in preview mock"])
    }

    func renderPaywall(for locale: Locale) async throws -> PaywallViewController {
        throw NSError(domain: "Preview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented in preview mock"])
    }

    func getOptimizedPaywall() async throws -> PaywallViewController {
        throw NSError(domain: "Preview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented in preview mock"])
    }

    func loadPaywallWithFallback() async -> PaywallViewController? {
        return nil
    }

    func syncSubscriptionStatus() async throws -> Bool {
        return isActive
    }
}