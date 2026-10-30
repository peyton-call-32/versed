import SwiftUI

/// A full-screen, swipe-up feed with one verse per page.
struct FeedView: View {
    let items: [FeedItem]

    /// The ID of the page currently on screen.
    @State private var currentItemID: FeedItem.ID?

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    page(for: item)
                        .containerRelativeFrame([.horizontal, .vertical])
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentItemID)
        .scrollIndicators(.hidden)
        .background(Color(.systemBackground))
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func page(for item: FeedItem) -> some View {
        switch item {
        case .chapterTitle(let title):
            ChapterTitleCard(title: title, isFirstPage: item.id == items.first?.id)
        case .verse(let verse):
            VerseCard(verse: verse)
        }
    }
}

#Preview {
    let library = try! ScriptureLibrary.loadBundled()
    FeedView(items: library.feedItems(for: [ChapterID(bookID: "1-ne", chapter: 3)]))
}
