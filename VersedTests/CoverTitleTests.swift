import XCTest
@testable import Versed

/// Book covers stack their titles like a title page, never breaking a phrase.
final class CoverTitleTests: XCTestCase {
    private func stacked(_ title: String) -> [String] {
        CoverTitle.lines(for: title).map(\.text)
    }

    func testJoiningWordsSitOnTheirOwnLine() {
        XCTAssertEqual(stacked("Pearl of Great Price"), ["Pearl", "of", "Great Price"])
        XCTAssertEqual(stacked("Doctrine and Covenants"), ["Doctrine", "and", "Covenants"])
        XCTAssertEqual(stacked("Book of Mormon"), ["Book", "of", "Mormon"])
        XCTAssertEqual(CoverTitle.lines(for: "Book of Mormon").map(\.isJoiningWord), [false, true, false])
    }

    func testOtherTitlesBreakAfterACommaOrBetweenTwoWords() {
        XCTAssertEqual(stacked("Come, Follow Me"), ["Come,", "Follow Me"])
        XCTAssertEqual(stacked("Old Testament"), ["Old", "Testament"])
        XCTAssertEqual(stacked("Genesis"), ["Genesis"])
    }
}
