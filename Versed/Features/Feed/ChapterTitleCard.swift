import SwiftUI

/// The card shown at the start of each chapter, with the book name and chapter number.
struct ChapterTitleCard: View {
    let title: ChapterTitle

    var body: some View {
        VStack(spacing: 12) {
            Text(title.bookName)
                .font(.system(.largeTitle, design: .serif, weight: .semibold))

            Rectangle()
                .fill(.tint)
                .frame(width: 40, height: 2)

            Text(title.heading)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ChapterTitleCard(
        title: ChapterTitle(id: ChapterID(bookID: "jer", chapter: 31), bookName: "Jeremiah", heading: "Chapter 31")
    )
}
