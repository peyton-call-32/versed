import SwiftUI
import UIKit

/// The buttons in a screen's top bar: plain ink on the page, with none of the glass that newer
/// iOS versions put behind them.
struct PlainToolbarItem<Content: View>: ToolbarContent {
    let placement: ToolbarItemPlacement
    @ViewBuilder let content: Content

    var body: some ToolbarContent {
        if #available(iOS 26, *) {
            ToolbarItem(placement: placement) { content }
                .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: placement) { content }
        }
    }
}

/// "Done", at the top right of every sheet.
struct DoneToolbarItem: ToolbarContent {
    var title = "Done"
    let action: () -> Void

    var body: some ToolbarContent {
        PlainToolbarItem(placement: .topBarTrailing) {
            Button(title, action: action)
                .buttonStyle(.plainWord)
                .padding(.trailing, Hardcover.margin - 16)
        }
    }
}

/// The back arrow, in plain ink. Cream while on a navy chapter opening.
private struct BackArrow: View {
    var color: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            GlyphView(.chevronBack, size: 18, lineWidth: 1.2)
                .foregroundStyle(color)
                // iOS sets toolbar items 16 points in. This lines the arrow up with the page's margin.
                .padding(.leading, Hardcover.margin - 16)
                .frame(width: 44, height: 44, alignment: .leading)
                .contentShape(Rectangle())
                .animation(.easeInOut(duration: 0.2), value: color)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}

extension View {
    /// Swaps iOS's glass back button for the plain one. Swiping from the edge still goes back
    /// (see the `UINavigationController` extension below).
    func versedBackButton(color: Color = .brand) -> some View {
        navigationBarBackButtonHidden(true)
            .toolbar {
                PlainToolbarItem(placement: .topBarLeading) {
                    BackArrow(color: color)
                }
            }
    }
}

// iOS turns off swipe-to-go-back when a screen replaces the back button. This keeps it on
// for every screen but the first.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
