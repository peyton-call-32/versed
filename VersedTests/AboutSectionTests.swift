import Foundation
import Testing
@testable import Versed

struct AboutSectionTests {
    @Test func showsTheAppVersionAndBuild() {
        // Matches "1.0 (1)", without needing an update every release.
        #expect(AboutSection.versionText().wholeMatch(of: /\d+(\.\d+)+ \(\d+\)/) != nil)
    }

    @Test func linksPointToTheRightPlaces() {
        #expect(AboutSection.privacyPolicyURL.absoluteString == "https://peyton-call-32.github.io/versed/privacy/")
        #expect(AboutSection.scriptureSourceURL.path() == "/bcbooks/scriptures-json")
    }

    /// "Come, Follow Me" is a Church trademark, so this line's wording is a deliberate decision.
    @Test func theIndependenceNoticeIsWordedExactly() {
        #expect(AboutSection.independenceNotice == "The Come, Follow Me plan follows the published reading schedule of The Church of Jesus Christ of Latter-day Saints. Versed is an independent app and is not made, approved, or endorsed by The Church of Jesus Christ of Latter-day Saints.")
    }
}
