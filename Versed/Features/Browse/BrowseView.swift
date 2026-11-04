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
            ScrollView {
                VStack(spacing: 22) {
                    weeklyReadingSection
                    scripturesSection
                }
                .versedPage()
            }
            .background(Color.appBackground)
            .navigationTitle("Browse")
            .navigationDestination(for: Route.self, destination: destination)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { showsSettings = true }
                }
            }
            .sheet(isPresented: $showsSettings) {
                SettingsView()
            }
        }
    }

    private var weeklyReadingSection: some View {
        CardSection(title: "This Week") {
            if let week = schedule.currentWeek() {
                Button {
                    openWeek(nil)
                } label: {
                    thisWeekRow(week)
                }
                .buttonStyle(.cardRow)
                .accessibilityLabel("This Week, \(week.label), \(week.dateRangeText())")
                .accessibilityHint("Opens this week's reading.")
                .accessibilityIdentifier("This Week")

                CardDivider()
            }

            NavigationLink(value: Route.schedule) {
                CardRowLabel(title: "Reading Schedule")
            }
            .buttonStyle(.cardRow)

            if let itemID = lastBrowsePosition, let reference = reference(for: itemID) {
                CardDivider()
                NavigationLink(value: Route.resume(itemID)) {
                    CardRowLabel(title: "Continue Reading", detail: reference)
                }
                .buttonStyle(.cardRow)
            }
        }
    }

    /// The week's book names, with its dates under them.
    private func thisWeekRow(_ week: ReadingWeek) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(week.readingByBook.map(\.name).joined(separator: ", "))
                    .font(.versedTitle(size: 20, relativeTo: .title3))
                    .foregroundStyle(.brand)
                Text(week.dateRangeText())
                    .font(.subheadline)
                    .foregroundStyle(.secondaryText)
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            CardRowArrow()
        }
        .cardRowPadding()
        .contentShape(Rectangle())
    }

    private var scripturesSection: some View {
        CardSection(title: "Scriptures") {
            ForEach(library.volumes) { volume in
                if volume.id != library.volumes.first?.id {
                    CardDivider()
                }
                NavigationLink(value: route(for: volume)) {
                    CardRowLabel(title: volume.title, detail: subtitle(for: volume))
                }
                .buttonStyle(.cardRow)
            }
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
