import SwiftUI

/// View for displaying value proposition screens with smooth navigation
/// Uses TabView for horizontal swiping and provides skip/next/previous controls
struct ValueScreensView: View {
    /// ViewModel for managing value screens state and navigation logic
    @StateObject var viewModel: ValueScreensViewModel

    /// Callback when user completes or skips value screens
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Main content with TabView for smooth screen transitions
            let screens = viewModel.valueScreens
            if !screens.isEmpty {
                VStack(spacing: 0) {
                    // Skip button at top right
                    HStack {
                        Spacer()
                        Button(action: {
                            if viewModel.skipToEnd() {
                            } else {
                                onComplete()
                            }
                        }) {
                            Text(String(localized: "generic.skip"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .accessibilityIdentifier("ValueScreensSkipButton")
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 16)

                    // TabView for smooth horizontal screen transitions
                    TabView(selection: $viewModel.currentIndex) {
                        ForEach(0..<screens.count, id: \.self) { index in
                            ValueScreenContentView(screen: screens[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .accessibilityIdentifier("ValueScreensTabView")

                    // Bottom navigation controls
                    VStack(spacing: 16) {
                        // Progress indicator
                        ProgressView(value: viewModel.progress())
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding(.horizontal, 32)
                            .accessibilityIdentifier("ValueScreensProgressIndicator")

                        // Navigation buttons
                        HStack(spacing: 20) {
                            // Previous button
                            Button(action: {
                                viewModel.previousScreen()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(viewModel.hasPrevious() ? .blue : .gray.opacity(0.5))
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(viewModel.hasPrevious() ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                    )
                            }
                            .disabled(!viewModel.hasPrevious())
                            .accessibilityIdentifier("ValueScreensPreviousButton")

                            // Next/Complete button
                            Button(action: {
                                if viewModel.nextScreen() {
                                } else {
                                    onComplete()
                                }
                            }) {
                                if viewModel.hasNext() {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .background(Circle().fill(Color.blue))
                                } else {
                                    Text(String(localized: "valuescreens.get_started"))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 120, height: 50)
                                        .background(Capsule().fill(Color.blue))
                                }
                            }
                            .accessibilityIdentifier("ValueScreensNextButton")
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                    }
                    .background(Color(.systemBackground))
                }
            } else if viewModel.isLoading {
                // Loading state
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(String(localized: "valuescreens.loading"))
                        .foregroundColor(.secondary)
                }
                .accessibilityIdentifier("ValueScreensLoadingView")
            } else if let error = viewModel.error {
                // Error state
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text(String(localized: "valuescreens.error.title"))
                        .font(.title)
                        .foregroundColor(.primary)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    HStack(spacing: 20) {
                        Button(action: {
                            viewModel.reset()
                        }) {
                            Text(String(localized: "generic.retry"))
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            onComplete()
                        }) {
                            Text(String(localized: "generic.skip"))
                                .font(.title3)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .accessibilityIdentifier("ValueScreensErrorView")
            } else {
                // Fallback state
                VStack(spacing: 20) {
                    Text(String(localized: "valuescreens.fallback.title"))
                        .font(.largeTitle)
                        .padding()
                    Text(String(localized: "valuescreens.fallback.subtitle"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button(action: {
                        onComplete()
                    }) {
                        Text(String(localized: "generic.continue"))
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .accessibilityIdentifier("ValueScreensFallbackView")
            }
        }
    }
}

/// Individual screen content view
/// Displays title, description, and image for a single value screen
private struct ValueScreenContentView: View {
    /// The value screen data to display
    let screen: ValueScreen

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Screen image
            Image(systemName: "star.fill") // Placeholder - would use screen.imageName
                .font(.system(size: 100))
                .foregroundColor(.blue)
                .accessibilityIdentifier("ValueScreenImage")

            // Screen title
            Text(screen.title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .accessibilityIdentifier("ValueScreenTitle")

            // Screen description
            Text(screen.description)
                .font(.system(size: 17))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .lineSpacing(4)
                .accessibilityIdentifier("ValueScreenDescription")

            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
    }
}

#Preview {
    ValueScreensView(
        viewModel: ValueScreensViewModel(),
        onComplete: {}
    )
}