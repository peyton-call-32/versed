import SwiftUI

/// The page that opens each chapter, made like a hardcover: solid navy with a thin double border,
/// "CHAPTER", a large number, a line that draws itself as the page settles, and the book's name.
struct ChapterTitleCard: View {
    let title: ChapterTitle
    /// Whether this page is the one on screen.
    var isCurrent = true
    /// How far down the border starts, so it clears the top of the phone.
    var topInset: CGFloat = 0
    var onTap: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.cover
            border
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
            .padding(.horizontal, 44)
            .padding(.top, FeedInsets.top)
            .padding(.bottom, FeedInsets.bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .pageDepth(drift: reduceMotion ? 0 : 0.3, fade: 0.9)
        }
        .overlay(alignment: .bottom) {
            Image(systemName: "chevron.up")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.onCover)
                .gentleBob(isActive: isCurrent)
                .padding(.bottom, 56)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    /// Two thin lines, like the frame stamped on a book's cover. It stays below the top of the phone.
    private var border: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.onCover.opacity(0.5))
                .padding(.horizontal, 16)
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(Color.onCover.opacity(0.22))
                .padding(.horizontal, 22)
                .padding(.vertical, 6)
        }
        .padding(.top, topInset + 4)
        .padding(.bottom, 16)
        .accessibilityHidden(true)
    }
}

#Preview {
    ChapterTitleCard(
        title: ChapterTitle(id: ChapterID(bookID: "jer", chapter: 31), bookName: "Jeremiah", label: "Chapter")
    )
    .ignoresSafeArea()
}
