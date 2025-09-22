import SwiftUI

struct ConfigurationErrorView: View {
    let error: ConfigurationError
    let isProduction: Bool
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Configuration Issue")
                .font(.title2)
                .bold()
            Text(error.localizedDescription)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding()
    }
}