import XCTest

/// Walks through the whole app the way a reader would, and captures the README screenshots on the way.
///
/// The app launches with `-ui-testing`, so it starts with nothing saved and never touches real data.
/// To save the screenshots as files, run the tests with `TEST_RUNNER_SCREENSHOT_DIR` set to a folder.
@MainActor
final class VersedUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
        app.launchArguments = ["-ui-testing"]
        app.launch()
    }

    func testReadingSavingBrowsingAndResuming() {
        // This Week opens on the week's intro card.
        XCTAssertTrue(app.staticTexts["Swipe up to read"].waitForExistence(timeout: 10))
        XCTAssertTrue(onScreen(app.links.matching(identifier: "Open This Week's Lesson")).isHittable)
        attachScreenshot(named: "week-intro-with-lesson-link")

        // Swipe past the intro and the chapter title card to the second verse, then save it.
        app.swipeUp()
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.buttons["Save verse"].waitForExistence(timeout: 5))
        onScreen(app.buttons.matching(identifier: "Save verse")).tap()
        XCTAssertTrue(app.buttons["Remove from saved"].waitForExistence(timeout: 5))

        // Reading a verse starts the streak.
        XCTAssertTrue(app.staticTexts["1-day reading streak"].waitForExistence(timeout: 5))
        saveScreenshot(named: "1-this-week")

        // Browse to Alma 32 and read to verse 2.
        app.tabBars.buttons["Browse"].tap()
        app.staticTexts["Book of Mormon"].tap()
        app.staticTexts["Alma"].tap()
        app.buttons["Alma 32"].tap()
        XCTAssertTrue(app.staticTexts["Chapter 32"].waitForExistence(timeout: 5))
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Alma 32:2"].waitForExistence(timeout: 5))

        // Back on the Browse list, Continue Reading points to where we stopped.
        while app.navigationBars.buttons.firstMatch.exists, !app.navigationBars["Browse"].exists {
            app.navigationBars.buttons.firstMatch.tap()
        }
        let continueReading = app.buttons["Alma 32:2"]
        XCTAssertTrue(continueReading.waitForExistence(timeout: 5))
        saveScreenshot(named: "2-browse")

        // Continue Reading reopens the feed on that verse.
        continueReading.tap()
        XCTAssertTrue(app.staticTexts["Alma 32:2"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Chapter 32"].isHittable)

        // The saved verse shows on the Saved tab.
        app.tabBars.buttons["Saved"].tap()
        XCTAssertTrue(app.navigationBars["Saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.cells.count, 1)
        saveScreenshot(named: "3-saved")
    }

    func testChoosingAnAppearance() {
        app.tabBars.buttons["Browse"].tap()
        app.navigationBars["Browse"].buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        // Try each choice, ending back on the default so the simulator is left as it was.
        for option in ["Dark", "Light", "Match Phone"] {
            app.buttons[option].tap()
            XCTAssertTrue(app.buttons[option].isSelected)
            attachScreenshot(named: "appearance-\(option)")
        }

        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Browse"].waitForExistence(timeout: 5))
    }

    func testAppearanceIsRememberedAfterRelaunch() {
        app.tabBars.buttons["Browse"].tap()
        app.navigationBars["Browse"].buttons["Settings"].tap()
        app.buttons["Dark"].tap()

        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["Swipe up to read"].waitForExistence(timeout: 10))
        attachScreenshot(named: "appearance-after-relaunch")

        // Put the default back so the simulator is left as it was.
        app.tabBars.buttons["Browse"].tap()
        app.navigationBars["Browse"].buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["Dark"].isSelected)
        app.buttons["Match Phone"].tap()
    }

    func testFirstTimeIntro() {
        relaunch(showingIntro: true)
        XCTAssertTrue(app.staticTexts["Swipe Up for the Next Verse"].waitForExistence(timeout: 10))
        saveScreenshot(named: "4-intro")

        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Double-Tap to Save"].waitForExistence(timeout: 5))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["This Week's Reading, Ready"].waitForExistence(timeout: 5))

        // The last page offers the reminder, with no Skip since Not Now does the same thing.
        XCTAssertTrue(app.buttons["Not Now"].exists)
        XCTAssertFalse(app.buttons["Skip"].exists)
        attachScreenshot(named: "intro-reminder-offer")

        app.buttons["Not Now"].tap()
        XCTAssertTrue(app.staticTexts["Swipe up to read"].waitForExistence(timeout: 5))
    }

    func testSkippingTheIntroAndSeeingItAgain() {
        relaunch(showingIntro: true)
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.staticTexts["Swipe up to read"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Browse"].tap()
        app.navigationBars["Browse"].buttons["Settings"].tap()
        app.buttons["Show Intro Again"].tap()
        XCTAssertTrue(app.staticTexts["Swipe Up for the Next Verse"].waitForExistence(timeout: 5))
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    func testAboutSection() {
        app.tabBars.buttons["Browse"].tap()
        app.navigationBars["Browse"].buttons["Settings"].tap()
        app.swipeUp()

        XCTAssertTrue(app.staticTexts["Versed is an independent app. It is not made, approved, or endorsed by The Church of Jesus Christ of Latter-day Saints."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.links["Privacy Policy"].exists || app.buttons["Privacy Policy"].exists)
        // The contact row is one tappable link, so the email may be its label or its value.
        let email = NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "peytoncall32@icloud.com", "peytoncall32@icloud.com")
        XCTAssertTrue(app.descendants(matching: .any).matching(email).firstMatch.exists)
        XCTAssertTrue(app.staticTexts["Version"].exists)
        attachScreenshot(named: "settings-about")
    }

    func testTurningOnTheDailyReminder() {
        app.tabBars.buttons["Browse"].tap()
        app.navigationBars["Browse"].buttons["Settings"].tap()

        let reminder = app.switches["Daily reminder"]
        // Settings stay on the simulator between runs, so start from off in case a run stopped early.
        if reminder.value as? String == "1" {
            reminder.switches.firstMatch.tap()
        }
        XCTAssertEqual(reminder.value as? String, "0")
        XCTAssertFalse(app.buttons["Time Picker"].exists, "The time only shows once the reminder is on.")

        reminder.switches.firstMatch.tap()

        // iOS asks for permission the first time only. Allow it if it asks.
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.buttons["Allow"]
        if allow.waitForExistence(timeout: 3) {
            allow.tap()
        }

        XCTAssertTrue(app.buttons["Time Picker"].waitForExistence(timeout: 5))
        XCTAssertEqual(reminder.value as? String, "1")
        attachScreenshot(named: "daily-reminder-on")

        // Turn it back off so the simulator is left as it was.
        reminder.switches.firstMatch.tap()
        XCTAssertFalse(app.buttons["Time Picker"].waitForExistence(timeout: 2))
    }

    /// Restarts the app, with or without the first-time intro.
    private func relaunch(showingIntro: Bool) {
        app.terminate()
        app.launchArguments = ["-ui-testing"] + (showingIntro ? ["-show-intro"] : [])
        app.launch()
    }

    /// The feed keeps neighboring pages loaded off-screen, so pick the match the reader can actually see.
    private func onScreen(_ query: XCUIElementQuery) -> XCUIElement {
        query.allElementsBoundByIndex.first { $0.isHittable } ?? query.firstMatch
    }

    /// Keeps a screenshot with the test results, for checking by eye in Xcode's test report.
    @discardableResult
    private func attachScreenshot(named name: String) -> XCUIScreenshot {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        return screenshot
    }

    /// Attaches a README screenshot, and saves it as a file when `SCREENSHOT_DIR` is set.
    private func saveScreenshot(named name: String) {
        let screenshot = attachScreenshot(named: name)

        if let folder = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            let url = URL(fileURLWithPath: folder).appendingPathComponent("\(name).png")
            XCTAssertNoThrow(try screenshot.pngRepresentation.write(to: url))
        }
    }
}
