import SwiftUI

struct LibraryView: View {
    @StateObject var viewModel: LibraryViewModel
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Library")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                if viewModel.isLoading {
                    ProgressView("Checking subscription...")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Library items section
                            if viewModel.premiumFeaturesAvailable {
                                // Show full library with add/remove functionality
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your Saved Items")
                                        .font(.title2)
                                        .padding(.horizontal)

                                    ForEach(viewModel.libraryItems) { item in
                                        LibraryItemView(item: item, canEdit: true)
                                            .contextMenu {
                                                Button(action: {
                                                    viewModel.removeItem(item)
                                                }) {
                                                    Label("Remove", systemImage: "trash")
                                                }
                                            }
                                    }

                                    // Add new item button
                                    Button(action: {
                                        let newItem = LibraryItem(title: "New Item", description: "Added item")
                                        viewModel.addItem(newItem)
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Item")
                                        }
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                    }
                                }
                            } else {
                                // Show limited library with upgrade prompt
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your Saved Items (Limited)")
                                        .font(.title2)
                                        .padding(.horizontal)

                                    ForEach(viewModel.libraryItems.prefix(2)) { item in
                                        LibraryItemView(item: item, canEdit: false)
                                    }

                                    // Upgrade prompt
                                    VStack(spacing: 16) {
                                        Text("Upgrade to Premium")
                                            .font(.headline)
                                            .foregroundColor(.white)

                                        Text("Unlock full library management and unlimited items")
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
                                }
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

struct LibraryItemView: View {
    let item: LibraryItem
    let canEdit: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "doc.fill")
                .font(.title)
                .foregroundColor(canEdit ? .blue : .gray)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(canEdit ? .primary : .gray)
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if canEdit {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}