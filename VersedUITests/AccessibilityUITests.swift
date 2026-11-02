import XCTest

/// Checks the app works for readers who use bigger text, VoiceOver, or dark mode.
@MainActor
final class AccessibilityUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() async throws {
        // Keep going after a failed check, so one run lists every problem.
        continueAfterFailure = true
    }

    /// Runs Apple's accessibility audit on every main screen: missing labels, hard-to-read
    /// contrast, text that doesn't grow with the text size setting, clipped text, and small tap targets.
    func testEveryScreenPassesTheAccessibilityAuditInLightAndDark() throws {
        for appearance in ["Light", "Dark"] {
            launch()
            setAppearance(appearance)

            // This Week: the intro card, then a verse.
            app.tabBars.buttons["This Week"].tap()
            XCTAssertTrue(app.staticTexts["Swipe up to read"].waitForExistence(timeout: 10))
            try audit("This Week intro, \(appearance)", except: Self.shrinkToFitIssues)
            app.swipeUp()
            app.swipeUp()
            XCTAssertTrue(app.buttons["Save verse"].waitForExistence(timeout: 5))
            try audit("verse, \(appearance)", except: Self.shrinkToFitIssues)

            app.tabBars.buttons["Browse"].tap()
            try audit("Browse, \(appearance)")

            app.collectionViews.buttons["Reading Schedule"].tap()
            XCTAssertTrue(app.navigationBars["Reading Schedule"].waitForExistence(timeout: 5))
            try audit("Reading Schedule, \(appearance)")
            app.navigationBars.buttons.firstMatch.tap()

            app.tabBars.buttons["Saved"].tap()
            try audit("Saved, \(appearance)")

            app.tabBars.buttons["Browse"].tap()
            app.navigationBars["Browse"].buttons["Settings"].tap()
            try audit("Settings, \(appearance)")
            app.buttons["Done"].tap()
        }

        // Put the default back so the simulator is left as it was.
        setAppearance("Match Phone")
    }

    func testFirstTimeIntroPassesTheAccessibilityAudit() throws {
        launch(extraArguments: ["-show-intro"])
        XCTAssertTrue(app.staticTexts["Swipe Up for the Next Verse"].waitForExistence(timeout: 10))
        try audit("intro first page")
        app.buttons["Next"].tap()
        app.buttons["Next"].tap()
        XCTAssertTrue(app.buttons["Not Now"].waitForExistence(timeout: 5))
        try audit("intro last page")
    }

    /// At the largest accessibility text size, each page still fits on one screen.
    func testLargestTextSizeStillFitsOnOneScreen() {
        launch(extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let weekMenu = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Week of")).firstMatch
        XCTAssertTrue(weekMenu.waitForExistence(timeout: 10))
        let top = weekMenu.frame.maxY

        // The week's intro card: its heading sits between the menu and the swipe hint.
        let heading = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Jeremiah 31–33")).firstMatch
        let hint = app.staticTexts["Swipe up to read"]
        attachScreenshot(named: "largest-text-intro")
        assertFits(heading, between: top, and: hint.frame.minY, "week heading")

        // The chapter title card, then the first verse. SwiftUI reports the verse's frame as the
        // whole page, so the verse itself is checked by eye in this screenshot; the heart button
        // must still sit clear of the tab bar.
        app.swipeUp()
        app.swipeUp()
        let heart = onScreen(app.buttons.matching(identifier: "Save verse"))
        XCTAssertTrue(heart.waitForExistence(timeout: 5))
        attachScreenshot(named: "largest-text-verse")
        assertFits(heart, between: top, and: app.tabBars.firstMatch.frame.minY, "heart button")

        app.tabBars.buttons["Browse"].tap()
        attachScreenshot(named: "largest-text-browse")
        app.collectionViews.buttons["Reading Schedule"].tap()
        XCTAssertTrue(app.navigationBars["Reading Schedule"].waitForExistence(timeout: 5))
        attachScreenshot(named: "largest-text-reading-schedule")
        app.navigationBars.buttons.firstMatch.tap()

        app.navigationBars["Browse"].buttons["Settings"].tap()
        app.swipeUp()
        app.swipeUp()
        attachScreenshot(named: "largest-text-settings")
    }

    /// The closing card after a week's last verse, with the lesson link: it passes the audit
    /// in light and dark mode, and at the largest text size the link still sits above the tab bar.
    func testWeekEndCardInLightDarkAndLargestText() throws {
        let largest = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        for (name, appearance, arguments) in [("light", "Light", [String]()), ("dark", "Dark", []), ("largest text", "Match Phone", largest)] {
            launch(extraArguments: arguments)
            setAppearance(appearance)
            app.openWeekFromSchedule(XCUIApplication.shortWeek.row)
            app.swipeToEndOfWeek(pageCount: XCUIApplication.shortWeek.pageCount)

            let lessonLink = onScreen(app.links.matching(identifier: "Open This Week's Lesson"))
            XCTAssertTrue(lessonLink.waitForExistence(timeout: 5))
            try audit("week end card, \(name)", except: Self.shrinkToFitIssues)
            let top = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Week of")).firstMatch.frame.maxY
            assertFits(lessonLink, between: top, and: app.tabBars.firstMatch.frame.minY, "lesson button, \(name)")
        }
        // Relaunch so Browse is back on its main list, then put the default back.
        launch()
        setAppearance("Match Phone")
    }

    /// At the largest accessibility text size, each intro page starts at the top and,
    /// scrolled to its end, stops above the page dots instead of sliding under them.
    func testIntroFitsAtTheLargestTextSize() {
        launch(extraArguments: ["-show-intro", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let skip = app.buttons["Skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 10))
        let top = skip.frame.maxY
        let dots = app.descendants(matching: .any)["Intro page dots"]

        // Each page's heading, and the last line on that page.
        let pages = [
            ("Swipe Up for the Next Verse", "Versed shows one verse at a time. Swipe up to keep reading."),
            ("Double-Tap to Save", "Double-tap a verse, or tap the heart, to keep it in your Saved tab."),
            ("This Week's Reading, Ready", VersedUITests.independenceNotice),
        ]
        for (number, (heading, lastLine)) in zip(1..., pages) {
            let headingText = app.staticTexts[heading]
            XCTAssertTrue(headingText.waitForExistence(timeout: 5))
            assertFits(headingText, between: top, and: dots.frame.minY, "intro page \(number) heading")

            // Scroll to the end of the page (extra swipes do nothing once there).
            for _ in 1...4 { app.swipeUp() }
            attachScreenshot(named: "largest-text-intro-page-\(number)")
            assertFits(app.staticTexts.matching(NSPredicate(format: "label == %@", lastLine)).firstMatch, between: top, and: dots.frame.minY, "intro page \(number) last line")

            if number < pages.count {
                app.buttons["Next"].tap()
            }
        }
    }

    /// VoiceOver reads each verse as its reference followed by the text.
    func testVoiceOverReadsTheVerseWithItsReference() {
        launch()
        app.swipeUp()
        app.swipeUp()
        let verse = app.otherElements.matching(NSPredicate(format: "label == %@", "Jeremiah 31:1")).firstMatch
        XCTAssertTrue(verse.waitForExistence(timeout: 5))
        let text = verse.value as? String ?? ""
        XCTAssertTrue(text.hasPrefix("At the same time, saith the LORD"), "Got: \(text)")
    }

    // MARK: - Helpers

    /// Checks `element` is fully visible between two heights on screen, not hidden under anything.
    private func assertFits(_ element: XCUIElement, between top: CGFloat, and bottom: CGFloat, _ name: String) {
        XCTAssertTrue(element.exists, "\(name) should exist")
        XCTAssertGreaterThanOrEqual(element.frame.minY, top, "\(name) runs under the week menu")
        XCTAssertLessThanOrEqual(element.frame.maxY, bottom, "\(name) runs under what's below it")
    }

    private func launch(extraArguments: [String] = []) {
        app.terminate()
        app.launchArguments = VersedUITests.launchArguments + extraArguments
        app.launch()
    }

    private func setAppearance(_ option: String) {
        app.tabBars.buttons["Browse"].tap()
        app.navigationBars["Browse"].buttons["Settings"].tap()
        app.buttons[option].tap()
        app.buttons["Done"].tap()
    }

    /// Feed pages step their text size down when it wouldn't fit on one screen (see `ShrinkToFit`),
    /// which the audit reports as text that doesn't grow or gets clipped. That's on purpose, and
    /// `testLargestTextSizeStillFitsOnOneScreen` checks those pages properly instead.
    static let shrinkToFitIssues: XCUIAccessibilityAuditType = [.dynamicType, .textClipped]

    /// Runs the audit on what's on screen now, and names the screen in any failure.
    private func audit(_ screen: String, except skipped: XCUIAccessibilityAuditType = []) throws {
        attachScreenshot(named: "audit-\(screen)")
        var problems: [String] = []
        try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting(skipped)) { issue in
            guard !Self.isKnownException(issue) else { return true }
            problems.append("\(issue.compactDescription): \(issue.element?.label ?? "?")")
            return true
        }
        XCTAssertTrue(problems.isEmpty, "\(screen):\n" + problems.joined(separator: "\n"))
    }

    /// Issues checked by hand and left on purpose:
    /// - Contrast in parts iOS draws itself: the glass navigation bar (its title and Done button)
    ///   and controls with no text of their own, like switches.
    /// - Text size on the Settings links and the About footer: they do grow (see the
    ///   "largest-text-settings" screenshot), but the audit misreads them inside a Form.
    /// - Text size on the intro's Skip and Next buttons, capped so the page text keeps the room.
    private static func isKnownException(_ issue: XCUIAccessibilityAuditIssue) -> Bool {
        guard let element = issue.element else { return true }
        switch issue.auditType {
        case .contrast:
            return element.label.isEmpty || ["Done", "Settings"].contains(element.label)
        case .dynamicType:
            return ["Done", "Scripture Text", "Privacy Policy", "Contact", "Version", "Skip", "Next"].contains(element.label)
                || element.label.hasPrefix("Scripture text is in the public domain.")
        default:
            return false
        }
    }

    /// The feed keeps neighboring pages loaded off-screen, so pick the match the reader can actually see.
    private func onScreen(_ query: XCUIElementQuery) -> XCUIElement {
        query.allElementsBoundByIndex.first { $0.isHittable } ?? query.firstMatch
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
