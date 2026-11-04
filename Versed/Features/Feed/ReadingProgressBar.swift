import SwiftUI

/// The thin line at the bottom of a verse page, with "3 of 40" beside it.
struct ReadingProgressBar: View {
    let position: ChapterPosition

    var body: some View {
        HStack(spacing: 12) {
            Capsule()
                .fill(Color.brand.opacity(0.14))
                .frame(height: 2)
                .overlay(alignment: .leading) {
                    GeometryReader { track in
                        Capsule()
                            .fill(Color.brand)
                            .frame(width: track.size.width * position.fraction)
                    }
                }
            Text("\(position.page) of \(position.pageCount)")
                .font(.footnote.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.secondaryText)
                .contentTransition(.numericText())
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 32)
        .animation(.versed, value: position)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        // It only shows while the controls are aside, which never happens with VoiceOver on.
        .accessibilityHidden(true)
    }
}

/// Where a verse page sits among the verses of its chapter in this feed. A week that reads only
/// part of a chapter counts just the verses it reads.
struct ChapterPosition: Equatable {
    let page: Int
    let pageCount: Int

    var fraction: CGFloat { CGFloat(page) / CGFloat(max(pageCount, 1)) }

    init?(of itemID: FeedItem.ID?, in items: [FeedItem]) {
        guard let itemID, let verseID = FeedItem.verseID(of: itemID) else { return nil }
        let chapter = ChapterID(bookID: verseID.bookID, chapter: verseID.chapter)
        let verses = items.filter { item in
            guard let id = FeedItem.verseID(of: item.id) else { return false }
            return id.bookID == chapter.bookID && id.chapter == chapter.chapter
        }
        guard let index = verses.firstIndex(where: { $0.id == itemID }) else { return nil }
        page = index + 1
        pageCount = verses.count
    }
}
