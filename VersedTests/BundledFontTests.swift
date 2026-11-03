import SwiftUI
import Testing
import UIKit
@testable import Versed

/// The fonts have to be listed in Info.plist by file name and asked for by PostScript name.
/// If either slips, iOS quietly falls back to its own font, so check they really load.
struct BundledFontTests {
    @Test(arguments: Font.Bundled.all)
    func fontLoads(name: String) {
        #expect(UIFont(name: name, size: 17) != nil)
    }
}
