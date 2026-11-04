import SwiftUI

/// The card shown at the start of each chapter: "CHAPTER", a large number, a thin ornament, then the book name.
struct ChapterTitleCard: View {
    let title: ChapterTitle

    var body: some View {
        ShrinkToFit {
            VStack(spacing: 12) {
                SmallCapsLabel(title.label)

                Text("\(title.id.chapter)")
                    .font(.versedNumber(size: 150))
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .foregroundStyle(.brand)

                Ornament()
                    .padding(.vertical, 6)

                Text(title.bookName)
                    .font(.versedTitle(size: 34))
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
