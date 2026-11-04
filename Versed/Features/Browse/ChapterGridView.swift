import SwiftUI

/// A grid of chapter numbers for one book.
struct ChapterGridView: View {
    let book: Book

    /// Grows with the reader's text size so big chapter numbers still fit.
    @ScaledMetric(relativeTo: .body) private var cellSize = 46.0

    private var columns: [GridItem] { [GridItem(.adaptive(minimum: cellSize), spacing: 8)] }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...book.chapterCount, id: \.self) { chapter in
                    NavigationLink(value: BrowseView.Route.reading(ChapterID(bookID: book.id, chapter: chapter))) {
                        Text("\(chapter)")
                            .font(.body)
                            .monospacedDigit()
                            .foregroundStyle(.brand)
                            .frame(maxWidth: .infinity, minHeight: cellSize)
                            .raised(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(ChapterGridButtonStyle())
                    .accessibilityLabel(book.reference(chapter: chapter))
                }
            }
            .versedPage()
        }
        .background(Color.appBackground)
        .navigationTitle(book.name)
    }
}

private struct ChapterGridButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .pressEffect(configuration.isPressed, scale: 0.92)
    }
}
