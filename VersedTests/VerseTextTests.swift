import Testing
@testable import Versed

struct VerseTextTests {
    private func smallCaps(in verse: String) -> [String] {
        VerseText.smallCapsRanges(in: verse).map { String(verse[$0]) }
    }

    @Test func keepsTheFirstLetterFullSize() {
        #expect(smallCaps(in: "The LORD hath appeared") == ["ORD"])
    }

    @Test func findsEveryWordInCapitals() {
        #expect(smallCaps(in: "Thus saith the Lord GOD; and the LORD said") == ["OD", "ORD"])
    }

    @Test func leavesOrdinaryWordsAlone() {
        #expect(smallCaps(in: "I will go and do the things which the Lord hath commanded").isEmpty)
    }
}
