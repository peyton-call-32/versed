import Foundation
import Testing
@testable import Versed

struct AboutSectionTests {
    @Test func showsTheAppVersionAndBuild() {
        // Matches "1.0 (1)", without needing an update every release.
        #expect(AboutSection.versionText().wholeMatch(of: /\d+(\.\d+)+ \(\d+\)/) != nil)
    }

    @Test func linksPointToTheRightPlaces() {
        #expect(AboutSection.privacyPolicyURL.lastPathComponent == "PRIVACY.md")
        #expect(AboutSection.scriptureSourceURL.path() == "/bcbooks/scriptures-json")
    }
}
