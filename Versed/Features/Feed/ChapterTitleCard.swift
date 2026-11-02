import SwiftUI

/// The card shown at the start of each chapter: "CHAPTER", a large number, a thin ornament, then the book name.
struct ChapterTitleCard: View {
    let title: ChapterTitle

    /// The big chapter number grows and shrinks with the iPhone's text size.
    @ScaledMetric(relativeTo: .largeTitle) private var numberSize: CGFloat = 104

    var body: some View {
        ShrinkToFit {
            VStack(spacing: 8) {
                SmallCapsLabel(title.label)

                Text("\(title.id.chapter)")
                    .font(.system(size: numberSize, weight: .light, design: .serif))
                    .foregroundStyle(.brand)

                Ornament()
                    .padding(.bottom, 8)

                Text(title.bookName)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(.brand)
            }
        }
        // VoiceOver reads "Alma, Chapter 32" as one heading.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title.bookName), \(title.heading)")
        .accessibilityAddTraits(.isHeader)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .padding(.top, FeedInsets.top)
        .padding(.bottom, FeedInsets.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ChapterTitleCard(
        title: ChapterTitle(id: ChapterID(bookID: "jer", chapter: 31), bookName: "Jeremiah", label: "Chapter")
    )
}
