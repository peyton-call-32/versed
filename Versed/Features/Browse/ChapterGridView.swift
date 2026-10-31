import SwiftUI

/// A grid of chapter numbers for one book.
struct ChapterGridView: View {
    let book: Book

    /// Grows with the reader's text size so big chapter numbers still fit.
    @ScaledMetric(relativeTo: .body) private var cellSize = 56.0

    private var columns: [GridItem] { [GridItem(.adaptive(minimum: cellSize), spacing: 12)] }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...book.chapterCount, id: \.self) { chapter in
                    NavigationLink(value: BrowseView.Route.reading(ChapterID(bookID: book.id, chapter: chapter))) {
                        Text("\(chapter)")
                            .font(.body.weight(.medium))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, minHeight: cellSize)
                            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(book.reference(chapter: chapter))
                }
            }
            .padding()
        }
        .navigationTitle(book.name)
    }
}
