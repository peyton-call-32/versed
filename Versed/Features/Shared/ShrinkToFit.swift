import SwiftUI

/// Shows `content` at the reader's text size when it fits on the page. When it doesn't
/// (a long verse at the largest accessibility sizes), steps the text size down only as far as
/// needed, so every page still fits on one screen without scrolling.
struct ShrinkToFit<Content: View>: View {
    @ViewBuilder let content: Content

    /// Text sizes to try after the reader's own, largest first.
    private static var smallerSizes: [DynamicTypeSize] {
        [.accessibility4, .accessibility3, .accessibility2, .accessibility1, .xxxLarge, .xLarge, .large, .small]
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ForEach(Self.smallerSizes, id: \.self) { size in
                content.dynamicTypeSize(...size)
            }
            // Last resort for the very longest verses.
            content
                .dynamicTypeSize(...DynamicTypeSize.xSmall)
                .minimumScaleFactor(0.5)
        }
    }
}
