import Testing
@testable import Versed

struct PassageTests {
    @Test(arguments: [
        ("jer.31", Passage(bookID: "jer", chapters: 31...31)),
        ("jer.31-33", Passage(bookID: "jer", chapters: 31...33)),
        ("isa.53.3-5", Passage(bookID: "isa", chapters: 53...53, verses: 3...5)),
        ("isa.61.1", Passage(bookID: "isa", chapters: 61...61, verses: 1...1)),
        ("1-sam.2.2", Passage(bookID: "1-sam", chapters: 2...2, verses: 2...2)),
    ])
    func readsAndWritesText(text: String, passage: Passage) {
        #expect(Passage(rawValue: text) == passage)
        #expect(passage.rawValue == text)
    }

    @Test(arguments: ["jer", "jer.0", "jer.33-31", "jer.31-33.1", "jer.x", "jer.1.2.3"])
    func rejectsBadText(text: String) {
        #expect(Passage(rawValue: text) == nil)
    }
}
