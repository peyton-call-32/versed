import Testing
@testable import Versed

struct FeedItemTests {
    let library = try! ScriptureLibrary.loadBundled()

    @Test func eachChapterStartsWithATitleCard() {
        let items = library.feedItems(for: [Passage(bookID: "jer", chapters: 31...32)])

        // Jeremiah 31 has 40 verses and Jeremiah 32 has 44, plus one title card each.
        #expect(items.count == 1 + 40 + 1 + 44)
        #expect(items[0].id == "chapter:jer.31")
        #expect(items[1].id == "verse:jer.31.1")
        #expect(items[41].id == "chapter:jer.32")
    }

    @Test func titleCardUsesTheBooksChapterLabel() throws {
        let items = library.feedItems(for: [Passage(bookID: "dc", chapters: 76...76)])
        guard case .chapterTitle(let title) = try #require(items.first) else {
            Issue.record("First item should be a title card")
            return
        }
        #expect(title.bookName == "Doctrine and Covenants")
        #expect(title.heading == "Section 76")
    }

    @Test func versesFromTheMiddleOfAChapterHaveNoTitleCard() {
        let items = library.feedItems(for: [Passage(bookID: "isa", chapters: 53...53, verses: 3...5)])
        #expect(items.map(\.id) == ["verse:isa.53.3", "verse:isa.53.4", "verse:isa.53.5"])
    }

    @Test func versesFromTheStartOfAChapterHaveATitleCard() {
        let items = library.feedItems(for: [Passage(bookID: "luke", chapters: 2...2, verses: 1...20)])
        #expect(items.first?.id == "chapter:luke.2")
        #expect(items.count == 21)
    }

    @Test func repeatedVersesAppearOnce() {
        let items = library.feedItems(for: [
            Passage(bookID: "ps", chapters: 23...23),
            Passage(bookID: "ps", chapters: 23...23, verses: 1...1),
        ])
        #expect(items.count == 1 + 6)
    }

    @Test func skipsPassagesThatDontExist() {
        #expect(library.feedItems(for: [Passage(bookID: "jer", chapters: 99...99)]).isEmpty)
        #expect(library.feedItems(for: [Passage(bookID: "nope", chapters: 1...1)]).isEmpty)
    }
}

struct FeedItemIDTests {
    @Test func readsTheVerseAndChapterBackFromAVersePage() {
        let id = FeedItem.id(for: VerseID(bookID: "1-ne", chapter: 3, verse: 7))
        #expect(FeedItem.verseID(of: id) == VerseID(bookID: "1-ne", chapter: 3, verse: 7))
        #expect(FeedItem.chapterID(of: id) == ChapterID(bookID: "1-ne", chapter: 3))
    }

    @Test func readsTheChapterBackFromATitleCard() {
        #expect(FeedItem.verseID(of: "chapter:jer.31") == nil)
        #expect(FeedItem.chapterID(of: "chapter:jer.31") == ChapterID(bookID: "jer", chapter: 31))
    }

    @Test func chapterGroupsFollowTheReadingOrderAndListEachChapterOnce() throws {
        let library = try ScriptureLibrary.loadBundled()
        let items = library.feedItems(for: [
            Passage(bookID: "luke", chapters: 1...1),
            Passage(bookID: "matt", chapters: 1...2),
            Passage(bookID: "luke", chapters: 2...2),
        ])
        // A page from a chapter already listed doesn't list it again.
        let groups = library.chapterGroups(in: items + items)
        #expect(groups.map(\.book.id) == ["luke", "matt", "luke"])
        #expect(groups.map(\.chapters) == [[1], [1, 2], [2]])
    }

    @Test func aWeekIntroHasNoChapter() {
        #expect(FeedItem.chapterID(of: "week:2026-10-26") == nil)
    }
}
