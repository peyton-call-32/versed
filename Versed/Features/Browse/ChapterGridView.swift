import SwiftUI

/// A grid of chapter numbers for one book.
struct ChapterGridView: View {
    let book: Book

    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...book.chapterCount, id: \.self) { chapter in
                    NavigationLink(value: BrowseView.Route.reading(ChapterID(bookID: book.id, chapter: chapter))) {
                        Text("\(chapter)")
                            .font(.body.weight(.medium))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, minHeight: 56)
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
