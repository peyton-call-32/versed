import SwiftUI

/// The app's top-level screen. Placeholder until the feed is built.
struct RootView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Versed")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
            Text("One verse at a time.")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    RootView()
}
