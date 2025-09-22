import SwiftUI
import RevenueCat

/// SwiftUI View for displaying the paywall with subscription options
struct PaywallView: View {
    @ObservedObject var viewModel: PaywallViewModel
    var onPurchase: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack {
            Text(String(localized: "paywall.title"))
                .font(.largeTitle)
                .padding()

            if viewModel.isLoading {
                ProgressView(String(localized: "paywall.loading"))
            } else if viewModel.offerings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cart.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text(String(localized: "paywall.empty_state.title"))
                        .font(.headline)
                    Text(String(localized: "paywall.empty_state.subtitle"))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    Button {
                        Task {
                            await viewModel.loadOfferings()
                        }
                    } label: {
                        Text(String(localized: "generic.retry"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 8)
            } else {
                ScrollView {
                    ForEach(viewModel.offerings, id: \.identifier) { package in
                        PlanCard(package: package,
                                isSelected: viewModel.selectedPackage == package,
                                pricing: viewModel.getPricingDisplay(for: package))
                            .onTapGesture {
                                viewModel.selectPlan(package)
                            }
                    }
                }
            }

            if viewModel.isSubscribed {
                Text(String(localized: "paywall.subscription_active_prefix") + " \(viewModel.subscriptionStatus ?? "Unknown")")
                    .foregroundColor(.green)
                    .padding()
            } else {
                VStack {
                    HStack {
                        TextField(String(localized: "paywall.promo.placeholder"), text: $viewModel.promotionalCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(String(localized: "paywall.promo.apply")) {
                            Task {
                                await viewModel.applyPromotionalCode(viewModel.promotionalCode)
                            }
                        }
                        .disabled(viewModel.promotionalCode.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
                    }
                    .padding()

                    if viewModel.isPromotionalCodeValid {
                        Text(String(localized: "paywall.promo.applied"))
                            .foregroundColor(.green)
                    }

                    if let selected = viewModel.selectedPackage {
                        Button(action: {
                            Task {
                                await viewModel.purchaseSubscription(package: selected)
                                if viewModel.isSubscribed {
                                    onPurchase()
                                }
                            }
                        }) {
                            if viewModel.isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text(String(localized: "paywall.subscribe_cta"))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                        .disabled(viewModel.isPurchasing)
                        .accessibilityIdentifier("PaywallSubscribeButton")
                    }

                    Button(String(localized: "paywall.restore")) {
                        Task {
                            await viewModel.restoreSubscriptions()
                            if viewModel.isSubscribed {
                                onPurchase()
                            }
                        }
                    }
                    .padding(.top)
                }
            }

            if let error = viewModel.purchaseError {
                Text(String(localized: "generic.error_prefix") + " \(error.localizedDescription)")
                    .foregroundColor(.red)
                    .padding()
            }

            HStack(spacing: 16) {
                Button(String(localized: "legal.terms")) {
                    if let url = URL(string: Configuration.termsOfServiceURL) {
                        openURL(url)
                    }
                }
                .foregroundColor(.secondary)

                Button(String(localized: "legal.privacy")) {
                    if let url = URL(string: Configuration.privacyPolicyURL) {
                        openURL(url)
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .onAppear {
            Task {
                await viewModel.loadOfferings()
                await viewModel.verifySubscriptionStatus()
            }
        }
        .onChange(of: viewModel.isSubscribed) { isSubscribed in
            if isSubscribed {
                onPurchase()
            }
        }
    }
}

/// Card view for subscription plan
struct PlanCard: View {
    let package: Package
    let isSelected: Bool
    let pricing: String

    private var displayTitle: String {
        let title = package.storeProduct.localizedTitle
        return title.isEmpty ? package.identifier.replacingOccurrences(of: "-", with: " ").capitalized : title
    }

    var body: some View {
        VStack {
            Text(displayTitle)
                .font(.headline)
            Text(pricing)
                .font(.title)
                .foregroundColor(.green)

            if isSelected {
                Text(String(localized: "paywall.plan.selected"))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.gray, lineWidth: isSelected ? 2 : 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}