import Testing
@testable import Versed

struct FeedItemTests {
    let library = try! ScriptureLibrary.loadBundled()

    @Test func eachChapterStartsWithATitleCard() {
        let items = library.feedItems(for: [ChapterID(bookID: "jer", chapter: 31), ChapterID(bookID: "jer", chapter: 32)])

        // Jeremiah 31 has 40 verses and Jeremiah 32 has 44, plus one title card each.
        #expect(items.count == 1 + 40 + 1 + 44)
        #expect(items[0].id == "chapter:jer.31")
        #expect(items[1].id == "verse:jer.31.1")
        #expect(items[41].id == "chapter:jer.32")
    }

    @Test func titleCardUsesTheBooksChapterLabel() throws {
        let items = library.feedItems(for: [ChapterID(bookID: "dc", chapter: 76)])
        guard case .chapterTitle(let title) = try #require(items.first) else {
            Issue.record("First item should be a title card")
            return
        }
        #expect(title.bookName == "Doctrine and Covenants")
        #expect(title.heading == "Section 76")
    }

    @Test func skipsChaptersThatDontExist() {
        #expect(library.feedItems(for: [ChapterID(bookID: "jer", chapter: 99)]).isEmpty)
    }
}
