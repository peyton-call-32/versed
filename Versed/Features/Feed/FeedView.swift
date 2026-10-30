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
                        .overlay(alignment: .bottom) {
                            if item.id == items.first?.id {
                                swipeHint
                            }
                        }
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
        case .weekIntro(let week):
            WeekIntroCard(week: week)
        case .chapterTitle(let title):
            ChapterTitleCard(title: title)
        case .verse(let verse):
            VerseCard(verse: verse)
        }
    }

    private var swipeHint: some View {
        Label("Swipe up to read", systemImage: "chevron.up")
            .font(.footnote)
            .foregroundStyle(.secondary)
            // Clears the tab bar, which floats over the bottom of the feed.
            .padding(.bottom, 120)
    }
}

#Preview {
    let library = try! ScriptureLibrary.loadBundled()
    FeedView(items: library.feedItems(for: [Passage(bookID: "1-ne", chapters: 3...3)]))
}
