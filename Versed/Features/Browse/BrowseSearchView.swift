import SwiftUI

/// One place a search can lead: a book, or a chapter in it.
struct ScriptureSearchResult: Hashable, Sendable {
    let title: String
    let bookID: Book.ID
    let chapter: Int?
}

extension ScriptureLibrary {
    /// Books whose names match, in every volume. "alma 32" or "d&c 76" goes straight to that chapter.
    func search(_ query: String) -> [ScriptureSearchResult] {
        let words = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !words.isEmpty else { return [] }

        var name = words
        var chapter: Int?
        if let match = words.firstMatch(of: /^(.*\D)\s+(\d+)$/), let number = Int(match.2) {
            name = String(match.1).trimmingCharacters(in: .whitespaces)
            chapter = number
        }
        let books = volumes.flatMap(\.books).filter {
            $0.name.lowercased().hasPrefix(name) || $0.referenceName.lowercased().hasPrefix(name)
                || $0.name.lowercased().contains(" \(name)")
        }
        return books.prefix(20).compactMap { book in
            guard let chapter else {
                return ScriptureSearchResult(title: book.name, bookID: book.id, chapter: nil)
            }
            guard (1...max(book.chapterCount, 1)).contains(chapter) else { return nil }
            return ScriptureSearchResult(title: book.reference(chapter: chapter), bookID: book.id, chapter: chapter)
        }
    }
}

/// Finds any book or chapter by typing it, including volumes not on the shelf.
struct BrowseSearchView: View {
    let library: ScriptureLibrary
    let onOpen: (ScriptureSearchResult) -> Void

    @State private var query = ""
    @FocusState private var isTyping: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let results = library.search(query)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(spacing: 8) {
                        TextField("Book or chapter, like Alma 32", text: $query)
                            .font(.versedVerse(size: 20, relativeTo: .title3))
                            .foregroundStyle(.brand)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .submitLabel(.go)
                            .focused($isTyping)
                            .onSubmit {
                                if let first = results.first { onOpen(first) }
                            }
                            .accessibilityIdentifier("Search scriptures")
                        Rule(color: .brand)
                    }
                    if !results.isEmpty {
                        Ledger {
                            ForEach(results, id: \.self) { result in
                                if result != results.first { LedgerRule() }
                                Button {
                                    onOpen(result)
                                } label: {
                                    LedgerRowLabel(title: result.title)
                                }
                                .buttonStyle(.ledgerRow)
                            }
                        }
                    } else if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Nothing by that name.")
                            .font(.versedDetail)
                            .foregroundStyle(.secondaryText)
                    }
                }
                .versedPage()
            }
            .scrollDismissesKeyboard(.interactively)
            .versedScreen()
            .navigationTitle("Find")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DoneToolbarItem(title: "Cancel") { dismiss() }
            }
            .onAppear { isTyping = true }
        }
    }
}
