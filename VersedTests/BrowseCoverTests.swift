import Foundation
import Testing
@testable import Versed

struct BrowseCoverTests {
    private let library = ScriptureLibrary(volumes: ["ot", "nt", "bofm", "dc", "pgp"].map { id in
        Volume(id: id, title: id, books: [Book(id: "\(id)-book", name: id, shortName: nil, chapterLabel: nil, chapters: [["Verse"]])])
    })

    @Test func splitsNamesIntoBalancedLines() {
        #expect(CoverTitle.lines(for: "Book of Mormon") == "Book of\nMormon")
        #expect(CoverTitle.lines(for: "Doctrine and Covenants") == "Doctrine and\nCovenants")
        #expect(CoverTitle.lines(for: "Pearl of Great Price") == "Pearl of\nGreat Price")
        #expect(CoverTitle.lines(for: "Old Testament") == "Old\nTestament")
    }

    @Test @MainActor func hasNoLastVolumeWithNothingRead() {
        #expect(library.lastReadVolumeID(from: []) == nil)
        #expect(library.middleVolumeID == "bofm")
    }

    /// The cover must keep saying the Church didn't make the app. Changing this is a deliberate decision.
    @Test func weeklyCoverSaysTheAppIsIndependent() {
        #expect(WeeklyCover.title == "Come, Follow Me")
        #expect(WeeklyCover.spokenTitle(course: "Old Testament 2026") == "Come, Follow Me—For Home and Church: Old Testament 2026")
        #expect(WeeklyCover.notice == "Versed is an independent app, not made or endorsed by The Church of Jesus Christ of Latter-day Saints.")
    }

    @Test @MainActor func opensOnTheVolumeReadMostRecently() {
        let older = ReadingPosition(feed: .week("2026-10-26"), itemID: "verse:ot-book.1.1", updatedAt: .distantPast)
        let newer = ReadingPosition(feed: .browse, itemID: "verse:dc-book.1.1", updatedAt: .now)
        #expect(library.lastReadVolumeID(from: [older, newer]) == "dc")
    }

    @Test @MainActor func skipsPagesOutsideAnyBook() {
        let weekCard = ReadingPosition(feed: .week("2026-11-02"), itemID: "week:2026-11-02", updatedAt: .now)
        let verse = ReadingPosition(feed: .browse, itemID: "verse:nt-book.1.1", updatedAt: .distantPast)
        #expect(library.lastReadVolumeID(from: [weekCard, verse]) == "nt")
    }
}
