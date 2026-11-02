import SwiftData
import SwiftUI

/// Pick any volume, book, and chapter, then read from there in the feed.
/// At the top: this week's reading, the full reading schedule, and a "Continue Reading" row
/// that returns to the last page read here or from Saved.
struct BrowseView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule
    /// Shows a week on the This Week tab: `nil` for this week, or any week from the schedule.
    let openWeek: (ReadingWeek.ID?) -> Void

    @Query private var positions: [ReadingPosition]
    @State private var showsSettings = false

    /// The screens the browse tab can open.
    enum Route: Hashable {
        case schedule
        case volume(Volume.ID)
        case book(Book.ID)
        case reading(ChapterID)
        /// Reopens the feed on a saved page.
        case resume(FeedItem.ID)
    }

    var body: some View {
        NavigationStack {
            List {
                weeklyReadingSection

                if let itemID = lastBrowsePosition, let reference = reference(for: itemID) {
                    Section("Continue Reading") {
                        NavigationLink(value: Route.resume(itemID)) {
                            Label(reference, systemImage: "bookmark")
                                .font(.system(.body, design: .serif))
                        }
                    }
                }

                Section {
                    ForEach(library.volumes) { volume in
                        NavigationLink(value: route(for: volume)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(volume.title)
                                    .font(.system(.title3, design: .serif))
                                Text(subtitle(for: volume))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondaryText)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Browse")
            .toolbar {
                Button("Settings", systemImage: "gearshape") {
                    showsSettings = true
                }
            }
            .sheet(isPresented: $showsSettings) {
                SettingsView()
            }
            .navigationDestination(for: Route.self, destination: destination)
        }
    }

    private var weeklyReadingSection: some View {
        Section {
            if let week = schedule.currentWeek() {
                Button {
                    openWeek(nil)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("This Week")
                                .font(.system(.title3, design: .serif))
                                .foregroundStyle(Color.primary)
                            Text(week.label)
                                .font(.subheadline)
                                .foregroundStyle(.secondaryText)
                            Text(week.dateRangeText())
                                .font(.subheadline)
                                .foregroundStyle(.secondaryText)
                        }
                        Spacer(minLength: 8)
                        DisclosureChevron()
                    }
                    .padding(.vertical, 4)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("This Week, \(week.label), \(week.dateRangeText())")
                .accessibilityHint("Opens this week's reading.")
                .accessibilityIdentifier("This Week")
            }

            NavigationLink(value: Route.schedule) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    Text("Reading Schedule")
                        .font(.system(.title3, design: .serif))
                }
            }
            .accessibilityIdentifier("Reading Schedule")
        } header: {
            Text("Weekly Reading")
                .foregroundStyle(.secondaryText)
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .schedule:
            ReadingScheduleView(schedule: schedule, openWeek: openWeek)
        case .volume(let id):
            if let volume = library.volume(id: id) {
                BookListView(volume: volume)
            }
        case .book(let id):
            if let book = library.book(id: id) {
                ChapterGridView(book: book)
            }
        case .reading(let chapterID):
            if let book = library.book(id: chapterID.bookID) {
                ChapterReadingView(library: library, book: book, startChapter: chapterID.chapter)
            }
        case .resume(let itemID):
            if let chapterID = FeedItem.chapterID(of: itemID), let book = library.book(id: chapterID.bookID) {
                ChapterReadingView(library: library, book: book, startChapter: chapterID.chapter, startItem: itemID)
            }
        }
    }

    private var lastBrowsePosition: FeedItem.ID? {
        positions.first { $0.feed == ReadingFeed.browse.key }?.itemID
    }

    /// "Alma 32:21" for a verse page, or "Alma 32" for a chapter's title card.
    private func reference(for itemID: FeedItem.ID) -> String? {
        guard let chapterID = FeedItem.chapterID(of: itemID),
              let book = library.book(id: chapterID.bookID)
        else { return nil }

        if let verseID = FeedItem.verseID(of: itemID), let verse = library.verse(verseID) {
            return verse.reference
        }
        return book.reference(chapter: chapterID.chapter)
    }

    /// A volume with a single book (the Doctrine and Covenants) skips straight to its chapters.
    private func route(for volume: Volume) -> Route {
        if volume.books.count == 1, let book = volume.books.first {
            return .book(book.id)
        }
        return .volume(volume.id)
    }

    /// "39 books" or "138 sections".
    private func subtitle(for volume: Volume) -> String {
        if volume.books.count == 1, let book = volume.books.first {
            return "\(book.chapterCount) \((book.chapterLabel ?? "Chapter").lowercased())s"
        }
        return "\(volume.books.count) books"
    }
}

#Preview {
    BrowseView(library: try! ScriptureLibrary.loadBundled(), schedule: try! ReadingSchedule.loadBundled(), openWeek: { _ in })
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
