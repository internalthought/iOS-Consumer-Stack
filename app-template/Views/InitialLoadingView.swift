import SwiftUI

struct InitialLoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .accessibilityIdentifier("InitialLoadingLogo")

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
                    .accessibilityIdentifier("InitialLoadingSpinner")

                Text("Loading...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}