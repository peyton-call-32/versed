import SwiftUI

/// The app's four main screens.
enum AppTab: String, CaseIterable, Identifiable {
    case today = "Today"
    case library = "Library"
    case saved = "Saved"
    case settings = "Settings"

    var id: Self { self }

    /// The icon, which fills in while the tab is selected.
    var glyph: Glyph {
        switch self {
        case .today: .ribbon
        case .library: .books
        case .saved: .heart
        case .settings: .sliders
        }
    }
}

private extension Spring {
    /// A soft settle for an icon coming back up after a tap.
    static let versedSettle = Spring(duration: 0.3, bounce: 0.3)
}

/// The band at the foot of every main screen: a solid strip of the same paper, laid over the page
/// so it casts a faint shadow upward. A small swelled rule under the open tab slides across when the
/// tab changes. On a navy chapter opening it turns navy too, with no shadow, so it's part of the page.
struct VersedTabBar: View {
    /// The band's height, above the phone's own bottom edge.
    static let height: CGFloat = 56

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
            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    button(for: tab)
                }
            }
            .padding(.horizontal, 8)
            .frame(minHeight: Self.height)
        }
        .animation(reduceMotion ? nil : .versed, value: selection)
        .background {
            ZStack {
                if isOnCover {
                    ClothSurface().ignoresSafeArea(edges: .bottom)
                } else {
                    PaperSurface()
                        .paperEdgeShadow(rise: -1)
                }
            }
        }
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
                GlyphView(tab.glyph, size: 21, lineWidth: 1, fill: isSelected ? 1 : 0)
                    .keyframeAnimator(initialValue: 1.0, trigger: bounces[tab, default: 0]) { icon, scale in
                        icon.scaleEffect(scale)
                    } keyframes: { _ in
                        SpringKeyframe(0.86, duration: 0.09)
                        SpringKeyframe(1, duration: 0.3, spring: .versedSettle)
                    }
                    .frame(height: 24)
                Text(tab.rawValue)
                    .font(.versedVerse(size: 12, relativeTo: .caption))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? ink : quietInk)
            .frame(maxWidth: .infinity, minHeight: Self.height)
            .overlay(alignment: .bottom) {
                if isSelected {
                    SwelledRuleShape()
                        .fill(ink)
                        .frame(width: 30, height: 2)
                        .matchedGeometryEffect(id: "open tab", in: marker)
                        .padding(.bottom, 1)
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
    @Previewable @State var selection = AppTab.today
    VersedTabBar(selection: $selection)
        .background(Color.appBackground)
}
