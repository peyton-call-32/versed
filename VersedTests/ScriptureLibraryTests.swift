import Testing
@testable import Versed

struct ScriptureLibraryTests {
    let library = try! ScriptureLibrary.loadBundled()

    @Test func loadsAllFiveVolumes() {
        #expect(library.volumes.map(\.id) == ScriptureLibrary.volumeIDs)
    }

    @Test func hasEveryVerse() {
        #expect(library.verseCount == 41_995)
    }

    @Test func findsAVerseByID() throws {
        let verse = try #require(library.verse(VerseID(bookID: "john", chapter: 3, verse: 16)))
        #expect(verse.reference == "John 3:16")
        #expect(verse.text.hasPrefix("For God so loved the world"))
    }

    @Test func doctrineAndCovenantsUsesSections() throws {
        let book = try #require(library.book(id: "dc"))
        #expect(book.chapterCount == 138)
        #expect(book.reference(chapter: 76) == "D&C 76")
        #expect(library.verse(VerseID(bookID: "dc", chapter: 4, verse: 2))?.reference == "D&C 4:2")
    }

    @Test func missingVerseReturnsNil() {
        #expect(library.verse(VerseID(bookID: "1-ne", chapter: 99, verse: 1)) == nil)
        #expect(library.verse(VerseID(bookID: "nope", chapter: 1, verse: 1)) == nil)
    }
}

struct VerseIDTests {
    @Test func roundTripsThroughText() {
        let id = VerseID(bookID: "1-ne", chapter: 3, verse: 7)
        #expect(id.rawValue == "1-ne.3.7")
        #expect(VerseID(rawValue: "1-ne.3.7") == id)
    }

    @Test func rejectsBadText() {
        #expect(VerseID(rawValue: "1-ne.3") == nil)
        #expect(VerseID(rawValue: "1-ne.three.7") == nil)
    }
}
