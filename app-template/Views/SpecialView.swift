import SwiftUI

struct SpecialView: View {
    @StateObject var viewModel: SpecialViewModel
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Special")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                if viewModel.isLoading {
                    ProgressView("Checking subscription...")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Special features section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Exclusive Special Features")
                                    .font(.title2)
                                    .padding(.horizontal)
                            }

                            // Display special features based on subscription status
                            if viewModel.premiumFeaturesAvailable {
                                // Show all special features for premium users
                                VStack(spacing: 16) {
                                    ForEach(viewModel.specialFeatures) { feature in
                                        SpecialFeatureCard(feature: feature)
                                            .onTapGesture {
                                                viewModel.performSpecialAction(for: feature)
                                            }
                                    }
                                }
                                .transition(.opacity)
                            } else {
                                // Show limited features for free users with upgrade prompt
                                ZStack {
                                    VStack(spacing: 16) {
                                        Text("Special Features")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.gray)

                                        VStack(spacing: 12) {
                                            ForEach(viewModel.specialFeatures) { feature in
                                                if feature.isPremium {
                                                    BlurredSpecialFeatureCard(feature: feature)
                                                } else {
                                                    SpecialFeatureCard(feature: feature)
                                                        .onTapGesture {
                                                            viewModel.performSpecialAction(for: feature)
                                                        }
                                                }
                                            }
                                        }
                                    }

                                    // Overlay with upgrade prompt for premium features
                                    VStack {
                                        Spacer()
                                        VStack(spacing: 16) {
                                            Text("Upgrade to Premium")
                                                .font(.headline)
                                                .foregroundColor(.white)

                                            Text("Unlock exclusive special features, premium content, and VIP support")
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

struct SpecialFeatureCard: View {
    let feature: SpecialFeature

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.iconName)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if feature.isPremium {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct BlurredSpecialFeatureCard: View {
    let feature: SpecialFeature

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.iconName)
                .font(.title)
                .foregroundColor(.gray)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
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