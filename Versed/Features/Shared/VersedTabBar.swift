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

/// The band at the foot of every main screen, set flat across the page under a ruled line.
/// A short line above the open tab slides across when the tab changes. On a navy chapter
/// opening it turns navy too, so it's part of the page.
struct VersedTabBar: View {
    /// The band's height, above the phone's own bottom edge.
    static let height: CGFloat = 54

    @Binding var selection: AppTab
    var isOnCover = false
    /// Called when the reader taps the tab that's already open.
    var onReselect: (AppTab) -> Void = { _ in }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Counts taps per tab, to give each one a small bounce.
    @State private var bounces: [AppTab: Int] = [:]
    @Namespace private var marker

    private var ink: Color { isOnCover ? .onCover : .brand }
    private var quietInk: Color { isOnCover ? .onCover : .secondaryText }

    var body: some View {
        VStack(spacing: 0) {
            Rule(color: isOnCover ? Color.onCover.opacity(0.3) : .hairline)
            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    button(for: tab)
                }
            }
            .padding(.horizontal, 28)
            .frame(minHeight: Self.height)
        }
        .animation(reduceMotion ? nil : .versed, value: selection)
        .background((isOnCover ? Color.cover : Color.appBackground).ignoresSafeArea(edges: .bottom))
        // The whole band takes touches, so a tap in its corners can't reach a list row underneath.
        .contentShape(Rectangle())
        .onTapGesture {}
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .sensoryFeedback(.selection, trigger: selection)
        // UI tests find the bar's position through this name.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Tab bar")
    }

    private func button(for tab: AppTab) -> some View {
        let isSelected = selection == tab
        return Button {
            if !reduceMotion { bounces[tab, default: 0] += 1 }
            if isSelected {
                onReselect(tab)
            } else {
                selection = tab
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.symbol)
                    .symbolVariant(isSelected ? .fill : .none)
                    .font(.system(size: 17, weight: .light))
                    .symbolEffect(.bounce, value: bounces[tab, default: 0])
                    .frame(height: 22)
                Text(tab.rawValue)
                    .font(.versedVerse(size: 12, relativeTo: .caption))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? ink : quietInk)
            .frame(maxWidth: .infinity, minHeight: Self.height)
            .overlay(alignment: .top) {
                if isSelected {
                    Rectangle()
                        .fill(ink)
                        .frame(width: 28, height: 1.5)
                        .matchedGeometryEffect(id: "open tab", in: marker)
                }
            }
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
    VersedTabBar(selection: $selection)
        .background(Color.appBackground)
}
