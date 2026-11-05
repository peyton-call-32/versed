import SwiftUI

/// The page that opens each chapter, made like a hardcover: solid navy with a thin double frame,
/// "CHAPTER", a large number, a line that draws itself as the page settles, and the book's name.
///
/// The frame stops short of the bands at the top and bottom of the page, so the controls that
/// come and go there never cross it. The page moves as one solid piece, like a real page.
struct ChapterTitleCard: View {
    let title: ChapterTitle
    /// Whether this page is the one on screen.
    var isCurrent = true
    /// Whether the arrow pointing up shows, in the band the tab bar uses when it isn't showing.
    var showsSwipeHint = true
    var onTap: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.screenInsets) private var screenInsets

    var body: some View {
        ZStack {
            Color.cover
            ZStack {
                CoverFrame()
                ShrinkToFit {
                    VStack(spacing: 0) {
                        SmallCapsLabel(title.label, color: .onCover)

                        Text("\(title.id.chapter)")
                            .font(.versedNumber(size: 190))
                            .lineLimit(1)
                            .minimumScaleFactor(0.3)
                            .foregroundStyle(.onCover)

                        Ornament(color: .onCover, lineLength: 44, isDrawn: isCurrent || reduceMotion)
                            .animation(reduceMotion ? nil : .easeOut(duration: 0.7).delay(0.1), value: isCurrent)
                            .padding(.top, 6)
                            .padding(.bottom, 20)

                        Text(title.bookName)
                            .font(.versedTitle(size: 46))
                            .foregroundStyle(.onCover)
                    }
                }
                // VoiceOver reads "Alma, Chapter 32" as one heading.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(title.bookName), \(title.heading)")
                .accessibilityAddTraits(.isHeader)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
            }
            .padding(.horizontal, Hardcover.margin - 8)
            .padding(.top, screenInsets.top + FeedInsets.header + 6)
            .padding(.bottom, screenInsets.bottom + VersedTabBar.height + 12)
        }
        .overlay(alignment: .bottom) {
            Image(systemName: "chevron.up")
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(.onCover)
                .gentleBob(isActive: isCurrent)
                .frame(height: VersedTabBar.height)
                .padding(.bottom, screenInsets.bottom)
                .opacity(showsSwipeHint ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showsSwipeHint)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    ChapterTitleCard(
        title: ChapterTitle(id: ChapterID(bookID: "jer", chapter: 31), bookName: "Jeremiah", label: "Chapter")
    )
    .ignoresSafeArea()
}
