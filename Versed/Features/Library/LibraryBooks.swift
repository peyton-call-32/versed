import SwiftUI

/// Something a reader can keep in their library: one of the five volumes, or a year of the
/// weekly schedule.
struct LibraryBook: Identifiable {
    enum Kind {
        case volume(Volume)
        case weeklyCourse(String)
    }

    let id: String
    let title: String
    /// The year's course under the title, such as "Old Testament 2026".
    var subtitle: String? = nil
    let kind: Kind

    /// The whole name, for VoiceOver and for the buttons that add or remove it.
    var fullName: String {
        [title, subtitle].compactMap(\.self).joined(separator: " ")
    }
}

/// Which books are in the reader's library, saved on the phone as their IDs.
/// Readers add and remove them from "Your Library".
enum Library {
    static let storageKey = "library.books"

    /// The years of the weekly schedule a reader can add. To offer a new year, add it here: it won't
    /// join anyone's library by itself, so readers choose to add it.
    static let offeredCourses = ["Old Testament 2026"]

    /// What a new reader starts with. Written out so that offering a new year never changes it.
    static let starting = "course:Old Testament 2026,ot,nt,bofm,dc,pgp"

    static func id(forCourse course: String) -> String { "course:\(course)" }

    /// Everything that can be in a library, in the order it stands on the shelf.
    static var allIDs: [String] { offeredCourses.map(id(forCourse:)) + ScriptureLibrary.volumeIDs }

    static func allBooks(in library: ScriptureLibrary) -> [LibraryBook] {
        let courses = offeredCourses.map {
            LibraryBook(id: id(forCourse: $0), title: WeeklyPlanName.title, subtitle: $0, kind: .weeklyCourse($0))
        }
        let volumes = library.volumes.map { LibraryBook(id: $0.id, title: $0.title, kind: .volume($0)) }
        return courses + volumes
    }

    static func bookIDs(from stored: String) -> [String] {
        stored.split(separator: ",").map(String.init)
    }

    /// Adds or removes a book, keeping them all in their usual order.
    static func toggling(_ id: String, in stored: String) -> String {
        var ids = Set(bookIDs(from: stored))
        if !ids.insert(id).inserted { ids.remove(id) }
        return allIDs.filter(ids.contains).joined(separator: ",")
    }
}

/// Adds and removes books from the library.
struct LibraryEditorView: View {
    let books: [LibraryBook]
    @Binding var stored: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Removing a book keeps your progress and saved verses.")
                        .font(.versedNote)
                        .foregroundStyle(.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Ledger {
                        ForEach(books) { book in
                            if book.id != books.first?.id { LedgerRule() }
                            row(for: book)
                        }
                    }
                    Text(WeeklyPlanName.notice)
                        .font(.versedNote)
                        .foregroundStyle(.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .versedPage()
            }
            .versedScreen()
            .navigationTitle("Your Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DoneToolbarItem { dismiss() }
            }
        }
        .environment(\.tabBarClearance, 0)
        // Tall enough for every book, so the covers stay in view above as they change.
        .presentationDetents([typeSize.isAccessibilitySize ? .large : .height(570)])
        .presentationBackground(Color.appBackground)
        .presentationDragIndicator(.hidden)
    }

    private func row(for book: LibraryBook) -> some View {
        let isInLibrary = Library.bookIDs(from: stored).contains(book.id)
        // Stacked at the largest text sizes, so a long name never breaks in the middle of a word.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout())
        return layout {
            VStack(alignment: .leading, spacing: 1) {
                Text(book.title)
                    .font(.versedRow)
                    .foregroundStyle(.brand)
                if let subtitle = book.subtitle {
                    Text(subtitle)
                        .font(.versedDetail)
                        .foregroundStyle(.secondaryText)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            if !typeSize.isAccessibilitySize { Spacer(minLength: 8) }
            if isInLibrary {
                Button("Remove") { stored = Library.toggling(book.id, in: stored) }
                    .buttonStyle(.plainWord)
                    .accessibilityLabel("Remove \(book.fullName)")
            } else {
                Button("+ Add") { stored = Library.toggling(book.id, in: stored) }
                    .buttonStyle(AddBookButtonStyle())
                    .accessibilityLabel("Add \(book.fullName)")
            }
        }
        .padding(.vertical, typeSize.isAccessibilitySize ? 10 : 0)
        .frame(minHeight: 60)
    }
}

/// The small solid button for adding a book.
private struct AddBookButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.versedDetail)
            .foregroundStyle(Color("ProminentButtonLabel"))
            .frame(minWidth: 72, minHeight: 40)
            .background(Color("ProminentButton"), in: Hardcover.corner)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .pressEffect(configuration.isPressed)
    }
}
