import SwiftUI

/// The app's three main screens.
enum AppTab: String, CaseIterable, Identifiable {
    case thisWeek = "This Week"
    case browse = "Browse"
    case saved = "Saved"

    var id: Self { self }

    /// The outline icon, which fills in while the tab is selected.
    var symbol: String {
        switch self {
        case .thisWeek: "calendar"
        case .browse: "book"
        case .saved: "heart"
        }
    }
}

/// The small raised bar that floats at the bottom of every main screen.
struct FloatingTabBar: View {
    /// The room to leave for the bar, including the small gap above it.
    static let height: CGFloat = 66

    @Binding var selection: AppTab
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                button(for: tab)
            }
        }
        .padding(.horizontal, 6)
        .raised(in: Capsule())
        // Wider at the largest text sizes, so the labels keep their room.
        .padding(.horizontal, typeSize.isAccessibilitySize ? 12 : 56)
        .padding(.top, 8)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .sensoryFeedback(.selection, trigger: selection)
        // UI tests find the bar's position through this name.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Tab bar")
    }

    private func button(for tab: AppTab) -> some View {
        let isSelected = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .symbolVariant(isSelected ? .fill : .none)
                    .font(.system(size: 18, weight: .light))
                    .frame(height: 22)
                Text(tab.rawValue)
                    .font(.caption2.weight(isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? AnyShapeStyle(.brand) : AnyShapeStyle(.secondaryText))
            .frame(maxWidth: .infinity, minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
        .accessibilityIdentifier("Tab \(tab.rawValue)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selection = AppTab.thisWeek
    FloatingTabBar(selection: $selection)
        .padding(.vertical)
        .background(Color.appBackground)
}
