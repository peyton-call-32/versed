import XCTest

/// Walks through the whole app the way a reader would, and captures the README screenshots on the way.
///
/// The app launches with `-ui-testing`, so it starts with nothing saved and never touches real data,
/// and with `-today` set to a fixed date, so "this week" is always the week of Oct 26, 2026.
/// To save the screenshots as files, run the tests with `TEST_RUNNER_SCREENSHOT_DIR` set to a folder.
@MainActor
final class VersedUITests: XCTestCase {
    let app = XCUIApplication()
    static let launchArguments = ["-ui-testing", "-today", "2026-10-28"]

    override func setUp() async throws {
        continueAfterFailure = false
        app.launchArguments = Self.launchArguments
        app.launch()
    }

    func testReadingSavingBrowsingAndResuming() {
        // This Week opens on the week's intro card, which keeps the lesson link for the end.
        XCTAssertTrue(app.staticTexts["Swipe up to read"].waitForExistence(timeout: 10))
        XCTAssertFalse(onScreen(app.links.matching(identifier: "Open This Week's Lesson")).isHittable)
        attachScreenshot(named: "week-intro")

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
        XCTAssertTrue(chapterHeading("Alma, Chapter 32").waitForExistence(timeout: 5))
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
        XCTAssertFalse(chapterHeading("Alma, Chapter 32").isHittable)

        // The saved verse shows on the Saved tab.
        app.tabBars.buttons["Saved"].tap()
        XCTAssertTrue(app.navigationBars["Saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.cells.count, 1)
        saveScreenshot(named: "3-saved")
    }

    func testBrowseShowsThisWeekAtTheTop() {
        // Start on another week, so going back to this week is a real change.
        app.tabBars.buttons["Browse"].tap()
        let thisWeek = app.collectionViews.buttons["This Week"]
        XCTAssertTrue(thisWeek.waitForExistence(timeout: 5))
        let schedule = app.collectionViews.buttons["Reading Schedule"]
        let firstBook = app.staticTexts["Old Testament"]
        XCTAssertLessThan(thisWeek.frame.maxY, schedule.frame.maxY, "This Week comes first")
        XCTAssertLessThan(schedule.frame.maxY, firstBook.frame.minY, "Both come before the books")
        XCTAssertTrue(thisWeek.label.contains("Jeremiah 31–33"), "Got: \(thisWeek.label)")
        attachScreenshot(named: "browse-weekly-reading")

        // This Week opens this week's reading on the This Week tab.
        thisWeek.tap()
        XCTAssertTrue(app.tabBars.buttons["This Week"].isSelected)
        XCTAssertTrue(weekHeading(containing: "Jeremiah 31–33").waitForExistence(timeout: 5))
        XCTAssertTrue(weekHeading(containing: "This Week").exists)
    }

    func testOpeningAWeekFromTheReadingSchedule() {
        app.tabBars.buttons["Browse"].tap()
        app.collectionViews.buttons["Reading Schedule"].tap()
        XCTAssertTrue(app.navigationBars["Reading Schedule"].waitForExistence(timeout: 5))

        // The current week is marked, and every week shows its dates and chapters.
        let current = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "This week, Oct 26 – Nov 1")).firstMatch
        XCTAssertTrue(current.waitForExistence(timeout: 5))
        XCTAssertTrue(current.isSelected)
        attachScreenshot(named: "reading-schedule")

        // Tapping another week opens its chapters in the feed.
        app.buttons["Nov 9–15, Daniel 1–7"].tap()
        XCTAssertTrue(app.tabBars.buttons["This Week"].isSelected)
        XCTAssertTrue(weekHeading(containing: "Daniel 1–7").waitForExistence(timeout: 5))
        XCTAssertTrue(weekHeading(containing: "Week Of").exists)
        XCTAssertTrue(app.buttons["Week of Nov 9–15"].exists)
        app.swipeUp()
        XCTAssertTrue(chapterHeading("Daniel, Chapter 1").waitForExistence(timeout: 5))

        // Browse's This Week row goes back to this week.
        app.tabBars.buttons["Browse"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.collectionViews.buttons["This Week"].tap()
        XCTAssertTrue(app.buttons["Week of Oct 26 – Nov 1"].waitForExistence(timeout: 5))
    }

    func testThisWeekPicksUpWhereTheReaderStopped() {
        // Read to Jeremiah 31:3: past the opening card, the chapter title, and two verses.
        XCTAssertTrue(app.staticTexts["Swipe up to read"].waitForExistence(timeout: 10))
        for _ in 1...4 { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Jeremiah 31:3"].waitForExistence(timeout: 5))

        // Leave for another week, then come back to this one.
        app.openWeekFromSchedule("Nov 9–15, Daniel 1–7")
        XCTAssertTrue(weekHeading(containing: "Daniel 1–7").waitForExistence(timeout: 5))
        app.tabBars.buttons["Browse"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.collectionViews.buttons["This Week"].tap()

        // It opens on the This Week card, with the saved verse hidden underneath.
        XCTAssertTrue(weekHeading(containing: "This Week").waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Jeremiah 31:3"].exists)

        // One swipe up lands on the saved verse, and the verses before it are still there.
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Jeremiah 31:3"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Jeremiah 31:3"].isHittable)
        app.swipeDown()
        XCTAssertTrue(app.staticTexts["Jeremiah 31:2"].waitForExistence(timeout: 5))
    }

    func testFinishedWeekStartsOverFromTheFirstVerse() {
        app.openWeekFromSchedule(XCUIApplication.shortWeek.row)
        XCTAssertTrue(weekHeading(containing: "John 1").waitForExistence(timeout: 5))
        app.swipeToEndOfWeek(pageCount: XCUIApplication.shortWeek.pageCount)
        let end = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "End of the Week's Reading, John 1")).firstMatch
        XCTAssertTrue(end.waitForExistence(timeout: 5))

        // Go to this week, then reopen the finished week.
        app.tabBars.buttons["Browse"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.collectionViews.buttons["This Week"].tap()
        XCTAssertTrue(weekHeading(containing: "This Week").waitForExistence(timeout: 5))
        app.openWeekFromSchedule(XCUIApplication.shortWeek.row)

        // Swiping up from its opening card starts at the beginning again.
        XCTAssertTrue(weekHeading(containing: "John 1").waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(chapterHeading("John, Chapter 1").waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["John 1:1"].waitForExistence(timeout: 5))
    }

    func testLessonLinkWaitsAtTheEndOfTheReading() {
        app.openWeekFromSchedule(XCUIApplication.shortWeek.row)
        XCTAssertTrue(weekHeading(containing: "John 1").waitForExistence(timeout: 5))
        app.swipeToEndOfWeek(pageCount: XCUIApplication.shortWeek.pageCount)

        // After John 1:51, the closing card shows the lesson link.
        let end = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "End of the Week's Reading, John 1")).firstMatch
        XCTAssertTrue(end.waitForExistence(timeout: 5))
        XCTAssertTrue(onScreen(app.links.matching(identifier: "Open This Week's Lesson")).isHittable)
        attachScreenshot(named: "week-end-with-lesson-link")
    }

    func testThisWeekHeader() {
        // Streak on the left, week menu in the middle, Settings on the right.
        // With no streak yet, the menu is still centered on the screen.
        let weekMenu = app.buttons["Week of Oct 26 – Nov 1"]
        let settings = app.buttons["Settings"]
        XCTAssertTrue(weekMenu.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["1-day reading streak"].exists)
        XCTAssertEqual(weekMenu.frame.midX, app.frame.midX, accuracy: 1)
        XCTAssertGreaterThan(settings.frame.minX, weekMenu.frame.maxX)

        // Once the streak shows, the menu stays put and nothing overlaps.
        for _ in 1...3 { app.swipeUp() }
        let streak = app.staticTexts["1-day reading streak"]
        XCTAssertTrue(streak.waitForExistence(timeout: 5))
        XCTAssertEqual(weekMenu.frame.midX, app.frame.midX, accuracy: 1)
        XCTAssertLessThan(streak.frame.maxX, weekMenu.frame.minX)
        attachScreenshot(named: "this-week-header")

        // Settings lives only here now, not on Browse.
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        app.tabBars.buttons["Browse"].tap()
        XCTAssertFalse(app.navigationBars["Browse"].buttons["Settings"].exists)
    }

    func testChoosingAnAppearance() {
        app.openSettings()

        // Try each choice, ending back on the default so the simulator is left as it was.
        for option in ["Dark", "Light", "Match Phone"] {
            app.buttons[option].tap()
            XCTAssertTrue(app.buttons[option].isSelected)
            attachScreenshot(named: "appearance-\(option)")
        }

        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
    }

    func testAppearanceIsRememberedAfterRelaunch() {
        app.openSettings()
        app.buttons["Dark"].tap()

        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["Swipe up to read"].waitForExistence(timeout: 10))
        attachScreenshot(named: "appearance-after-relaunch")

        // Put the default back so the simulator is left as it was.
        app.openSettings()
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

        // The last page carries the one line that names the reading schedule.
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label == %@", Self.independenceNotice)).firstMatch.exists)

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

        app.openSettings()
        app.buttons["Show Intro Again"].tap()
        XCTAssertTrue(app.staticTexts["Swipe Up for the Next Verse"].waitForExistence(timeout: 5))
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    func testAboutSection() {
        app.openSettings()
        app.swipeUp()

        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label == %@", Self.independenceNotice)).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.links["Privacy Policy"].exists || app.buttons["Privacy Policy"].exists)
        // The contact row is one tappable link, so the email may be its label or its value.
        let email = NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "peytoncall32@icloud.com", "peytoncall32@icloud.com")
        XCTAssertTrue(app.descendants(matching: .any).matching(email).firstMatch.exists)
        XCTAssertTrue(app.staticTexts["Version"].exists)
        attachScreenshot(named: "settings-about")
    }

    func testTurningOnTheDailyReminder() {
        app.openSettings()

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

    static let independenceNotice = "This Week follows the Come, Follow Me reading schedule. Versed is an independent app and is not made, approved, or endorsed by The Church of Jesus Christ of Latter-day Saints."

    /// The week intro card's heading, which VoiceOver reads as one line: "This Week, Daniel 1–7, Nov 9–15".
    /// A chapter's title card, which VoiceOver reads as one heading: "Alma, Chapter 32".
    private func chapterHeading(_ label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    private func weekHeading(containing text: String) -> XCUIElement {
        let match = NSPredicate(format: "label CONTAINS %@", text)
        return onScreen(app.descendants(matching: .any).matching(match).matching(NSPredicate(format: "label CONTAINS %@", ",")))
    }

    /// Restarts the app, with or without the first-time intro.
    private func relaunch(showingIntro: Bool) {
        app.terminate()
        app.launchArguments = Self.launchArguments + (showingIntro ? ["-show-intro"] : [])
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
