import SwiftUI
import SwiftData

struct HomepageView: View {
    @StateObject var viewModel: HomepageViewModel
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                    .accessibilityIdentifier("HomeDashboardTitle")

                if viewModel.isLoading {
                    ProgressView("Checking subscription...")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Welcome section (always visible)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Welcome to Premium App!")
                                    .font(.title2)
                                    .padding(.horizontal)
                            }

                            // Premium content section
                            if viewModel.premiumFeaturesAvailable {
                                // Show premium content
                                VStack(spacing: 16) {
                                    PremiumFeatureCard(
                                        title: "Advanced Analytics",
                                        description: "Get detailed insights and reports",
                                        iconName: "chart.bar.fill"
                                    )

                                    PremiumFeatureCard(
                                        title: "Cloud Sync",
                                        description: "Keep your data safe and accessible everywhere",
                                        iconName: "icloud.and.arrow.up.fill"
                                    )

                                    PremiumFeatureCard(
                                        title: "Priority Support",
                                        description: "Get help faster with premium support",
                                        iconName: "person.fill.questionmark"
                                    )
                                }
                                .transition(.opacity)
                            } else {
                                // Show locked premium content
                                ZStack {
                                    VStack(spacing: 16) {
                                        Text("Premium Features")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.gray)

                                        VStack(spacing: 12) {
                                            BlurredPremiumFeatureCard(
                                                title: "Advanced Analytics",
                                                iconName: "chart.bar.fill"
                                            )

                                            BlurredPremiumFeatureCard(
                                                title: "Cloud Sync",
                                                iconName: "icloud.and.arrow.up.fill"
                                            )

                                            BlurredPremiumFeatureCard(
                                                title: "Priority Support",
                                                iconName: "person.fill.questionmark"
                                            )
                                        }
                                    }

                                    // Overlay with upgrade prompt
                                    VStack {
                                        Spacer()
                                        VStack(spacing: 16) {
                                            Text("Upgrade to Premium")
                                                .font(.headline)
                                                .foregroundColor(.white)

                                            Text("Unlock advanced analytics, cloud sync, and priority support")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.9))
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal)

                                            Button(action: {
                                                coordinator.startPaywall()
                                            }) {
                                                Text("Upgrade Now")
                                                    .fontWeight(.semibold)
                                                    .padding(.horizontal, 24)
                                                    .padding(.vertical, 12)
                                                    .background(Color.blue)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(8)
                                            }
                                        }
                                        .padding()
                                        .background(Color.black.opacity(0.8))
                                        .cornerRadius(16)
                                        .padding(.horizontal)
                                        Spacer()
                                    }
                                }
                                .transition(.opacity)
                            }
                        }
                        .padding(.vertical)
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            Task {
                await viewModel.checkSubscription()
            }
        }
    }
}

struct PremiumFeatureCard: View {
    let title: String
    let description: String
    let iconName: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct BlurredPremiumFeatureCard: View {
    let title: String
    let iconName: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title)
                .foregroundColor(.gray)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("Upgrade to unlock")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.7))
            }

            Spacer()

            Image(systemName: "lock.fill")
                .foregroundColor(.gray)
                .font(.title3)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
        .blur(radius: 1)
        .brightness(-0.1)
    }
}