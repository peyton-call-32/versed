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
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 10))
        XCTAssertFalse(onScreen(app.links.matching(identifier: "Open This Week's Lesson")).isHittable)
        attachScreenshot(named: "week-intro")

        // Swipe past the intro and the chapter title card to the second verse, then save it.
        app.swipeUp()
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.buttons["Save verse"].waitForExistence(timeout: 5))
        onScreen(app.buttons.matching(identifier: "Save verse")).tap()
        XCTAssertTrue(app.buttons["Remove from saved"].waitForExistence(timeout: 5))

        // Reading a verse starts the streak. It waits for a tap, along with the tab bar.
        app.revealControls()
        XCTAssertTrue(app.buttons["1-day reading streak"].waitForExistence(timeout: 5))
        saveScreenshot(named: "1-this-week")

        // Browse to Alma 32 and read to verse 2.
        app.tab("Browse").tap()
        app.openVolume("Book of Mormon")
        app.buttons["Alma"].tap()
        app.buttons["Alma 32"].tap()
        XCTAssertTrue(chapterHeading("Alma, Chapter 32").waitForExistence(timeout: 5))
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Alma 32:2"].waitForExistence(timeout: 5))

        // Back on the Browse list, Continue Reading points to where we stopped.
        while app.navigationBars.buttons.firstMatch.exists, !app.navigationBars["Browse"].exists {
            app.navigationBars.buttons.firstMatch.tap()
        }
        let continueReading = app.buttons["Continue Reading"]
        XCTAssertTrue(continueReading.waitForExistence(timeout: 5))
        XCTAssertEqual(continueReading.value as? String, "Alma 32:2")
        saveScreenshot(named: "2-browse")

        // Continue Reading reopens the feed on that verse.
        continueReading.tap()
        XCTAssertTrue(app.staticTexts["Alma 32:2"].waitForExistence(timeout: 5))
        XCTAssertFalse(chapterHeading("Alma, Chapter 32").isHittable)

        // The saved verse shows on the Saved tab.
        app.tab("Saved").tap()
        XCTAssertTrue(app.navigationBars["Saved"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.cells.count, 1)
        saveScreenshot(named: "3-saved")
    }

    /// Captures the App Store screenshots. Run on the largest iPhone with `TEST_RUNNER_SCREENSHOT_DIR` set.
    func testCapturingAppStoreScreenshots() {
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 10))
        saveScreenshot(named: "2-this-week")

        // Jeremiah 31:3, then save it and the next verse so the Saved tab has something to show.
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Jeremiah 31:1"].waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Jeremiah 31:2"].waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Jeremiah 31:3"].waitForExistence(timeout: 5))
        saveScreenshot(named: "1-verse")
        onScreen(app.buttons.matching(identifier: "Save verse")).tap()

        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Jeremiah 31:4"].waitForExistence(timeout: 5))
        onScreen(app.buttons.matching(identifier: "Save verse")).tap()

        app.tab("Browse").tap()
        XCTAssertTrue(app.buttons["Reading Schedule"].waitForExistence(timeout: 5))
        saveScreenshot(named: "3-browse")

        app.tab("Saved").tap()
        XCTAssertTrue(app.navigationBars["Saved"].waitForExistence(timeout: 5))
        saveScreenshot(named: "4-saved")
    }

    func testBrowseShowsThisWeekAtTheTop() {
        // Start on another week, so going back to this week is a real change.
        app.tab("Browse").tap()
        let thisWeek = app.scrollViews.buttons["This Week"]
        XCTAssertTrue(thisWeek.waitForExistence(timeout: 5))
        let schedule = app.scrollViews.buttons["Reading Schedule"]
        let firstBook = app.buttons["Old Testament"]
        XCTAssertLessThan(thisWeek.frame.maxY, schedule.frame.maxY, "This Week comes first")
        XCTAssertGreaterThan(thisWeek.frame.minY, firstBook.frame.maxY, "Both sit below the book covers")
        XCTAssertTrue(schedule.isHittable, "Stays in view below the covers")
        XCTAssertTrue(thisWeek.label.contains("Jeremiah 31–33"), "Got: \(thisWeek.label)")
        attachScreenshot(named: "browse-weekly-reading")

        // This Week opens this week's reading on the This Week tab.
        thisWeek.tap()
        XCTAssertTrue(app.tab("This Week").isSelected)
        XCTAssertTrue(weekHeading(containing: "Jeremiah 31–33").waitForExistence(timeout: 5))
        XCTAssertTrue(weekHeading(containing: "This Week").exists)
    }

    func testOpeningAWeekFromTheReadingSchedule() {
        app.tab("Browse").tap()
        app.scrollViews.buttons["Reading Schedule"].tap()
        XCTAssertTrue(app.navigationBars["Reading Schedule"].waitForExistence(timeout: 5))

        // The current week is marked, and every week shows its dates and chapters.
        let current = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "This week, Oct 26 – Nov 1")).firstMatch
        XCTAssertTrue(current.waitForExistence(timeout: 5))
        XCTAssertTrue(current.isSelected)
        attachScreenshot(named: "reading-schedule")

        // Tapping another week opens its chapters in the feed.
        app.buttons["Nov 9–15, Daniel 1–7"].tap()
        XCTAssertTrue(app.tab("This Week").isSelected)
        XCTAssertTrue(weekHeading(containing: "Daniel 1–7").waitForExistence(timeout: 5))
        XCTAssertTrue(weekHeading(containing: "Week Of").exists)
        XCTAssertTrue(app.buttons["Week of Nov 9–15"].exists)
        app.swipeUp()
        XCTAssertTrue(chapterHeading("Daniel, Chapter 1").waitForExistence(timeout: 5))

        // Browse's This Week row goes back to this week.
        app.tab("Browse").tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.scrollViews.buttons["This Week"].tap()
        XCTAssertTrue(app.buttons["Week of Oct 26 – Nov 1"].waitForExistence(timeout: 5))
    }

    func testChapterMenuMovesAroundTheWeek() {
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 10))
        for _ in 1...4 { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Jeremiah 31:3"].waitForExistence(timeout: 5))

        // The menu says where we are, and jumps to another chapter.
        app.buttons["Jeremiah 31"].tap()
        sleep(1)
        attachScreenshot(named: "chapter-menu")
        app.buttons["Lamentations 3"].tap()
        XCTAssertTrue(chapterHeading("Lamentations, Chapter 3").waitForExistence(timeout: 5))

        // Back to the week's start keeps our place: swiping up continues from it.
        // A chapter opening hides the menu until a tap on the page.
        app.revealControls()
        XCTAssertTrue(app.buttons["Lamentations 3"].waitForExistence(timeout: 3))
        app.buttons["Lamentations 3"].tap()
        app.buttons["Back to Week's Start"].tap()
        XCTAssertTrue(app.staticTexts["Swipe up to continue reading"].waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(chapterHeading("Lamentations, Chapter 3").waitForExistence(timeout: 5))

        // Other weeks open from the same menu.
        app.buttons["Lamentations 3"].tap()
        app.buttons["Other Weeks"].tap()
        let row = app.buttons["Nov 9–15, Daniel 1–7"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(weekHeading(containing: "Daniel 1–7").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Week of Nov 9–15"].exists)
    }

    func testTappingTheOpenTabGoesBackToItsStart() {
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 10))
        for _ in 1...4 { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Jeremiah 31:3"].waitForExistence(timeout: 5))
        app.tab("This Week").tap()
        XCTAssertTrue(app.staticTexts["Swipe up to continue reading"].waitForExistence(timeout: 5))

        app.tab("Browse").tap()
        app.openVolume("Book of Mormon")
        XCTAssertFalse(app.navigationBars["Browse"].exists)
        app.tab("Browse").tap()
        XCTAssertTrue(app.navigationBars["Browse"].waitForExistence(timeout: 5))
    }

    /// Psalms is the longest book, so this also checks that opening near its end works.
    func testBrowseChapterMenuReachesEarlierChapters() {
        app.tab("Browse").tap()
        app.openVolume("Old Testament")
        let psalms = app.buttons["Psalms"]
        for _ in 1...5 where !(psalms.exists && psalms.isHittable) { app.swipeUp() }
        psalms.tap()
        let lastPsalm = app.buttons["Psalms 150"]
        for _ in 1...10 where !(lastPsalm.exists && lastPsalm.isHittable) { app.swipeUp() }
        lastPsalm.tap()
        XCTAssertTrue(chapterHeading("Psalms, Chapter 150").waitForExistence(timeout: 10))
        sleep(1)
        attachScreenshot(named: "browse-chapter-menu-pill")

        app.revealControls()
        XCTAssertTrue(app.buttons["Chapter menu"].waitForExistence(timeout: 3))
        app.buttons["Chapter menu"].tap()
        let firstPsalm = app.buttons["Psalms 1"]
        for _ in 1...10 where !(firstPsalm.exists && firstPsalm.isHittable) { app.swipeDown() }
        firstPsalm.tap()
        XCTAssertTrue(chapterHeading("Psalms, Chapter 1").waitForExistence(timeout: 10))
    }

    func testThisWeekPicksUpWhereTheReaderStopped() {
        // Read to Jeremiah 31:3: past the opening card, the chapter title, and two verses.
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 10))
        for _ in 1...4 { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Jeremiah 31:3"].waitForExistence(timeout: 5))

        // Leave for another week, then come back to this one.
        app.openWeekFromSchedule("Nov 9–15, Daniel 1–7")
        XCTAssertTrue(weekHeading(containing: "Daniel 1–7").waitForExistence(timeout: 5))
        app.tab("Browse").tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.scrollViews.buttons["This Week"].tap()

        // It opens on the This Week card, with the saved verse hidden underneath.
        XCTAssertTrue(weekHeading(containing: "This Week").waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Jeremiah 31:3"].exists)
        XCTAssertTrue(app.staticTexts["Swipe up to continue reading"].exists)

        // One swipe up lands on the saved verse, and the verses before it are still there.
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Jeremiah 31:3"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Jeremiah 31:3"].isHittable)
        app.swipeDown()
        XCTAssertTrue(app.staticTexts["Jeremiah 31:2"].waitForExistence(timeout: 5))
    }

    func testTappingASectionJumpsToIt() {
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 10))
        app.buttons["Lamentations 3"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["Lamentations, Chapter 3"].waitForExistence(timeout: 5))

        // Swiping up from there keeps reading that chapter.
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Lamentations 3:1"].waitForExistence(timeout: 5))
    }

    func testTappingASectionWorksWhenResuming() {
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 10))
        for _ in 1...4 { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Jeremiah 31:3"].waitForExistence(timeout: 5))
        app.openWeekFromSchedule("Nov 9–15, Daniel 1–7")
        XCTAssertTrue(weekHeading(containing: "Daniel 1–7").waitForExistence(timeout: 5))
        app.tab("Browse").tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.scrollViews.buttons["This Week"].tap()
        XCTAssertTrue(app.staticTexts["Swipe up to continue reading"].waitForExistence(timeout: 5))

        app.buttons["Jeremiah 36–39"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["Jeremiah, Chapter 36"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Swipe up to continue reading"].exists)
    }

    func testFinishedWeekStartsOverFromTheFirstVerse() {
        app.openWeekFromSchedule(XCUIApplication.shortWeek.row)
        XCTAssertTrue(weekHeading(containing: "John 1").waitForExistence(timeout: 5))
        app.swipeToEndOfWeek(pageCount: XCUIApplication.shortWeek.pageCount)
        let end = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "End of the Week's Reading, John 1")).firstMatch
        XCTAssertTrue(end.waitForExistence(timeout: 5))

        // Go to this week, then reopen the finished week.
        app.tab("Browse").tap()
        app.navigationBars.buttons.firstMatch.tap()
        app.scrollViews.buttons["This Week"].tap()
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
        // The chapter menu on the left, showing the week's dates; no count until the first verse is read.
        XCTAssertTrue(app.buttons["Week of Oct 26 – Nov 1"].waitForExistence(timeout: 10))
        let weekMenu = app.buttons["Chapter menu"]
        XCTAssertTrue(weekMenu.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Reading streak"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["1-day reading streak"].exists)
        XCTAssertLessThan(weekMenu.frame.midX, app.frame.midX)

        // Once the streak counts, a tap on the page shows it on the right, and nothing overlaps.
        for _ in 1...3 { app.swipeUp() }
        app.revealControls()
        let streak = app.buttons["1-day reading streak"]
        XCTAssertTrue(streak.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(streak.frame.minX, weekMenu.frame.maxX)
        attachScreenshot(named: "this-week-header")

        // Tapping it opens the calendar, with today marked as read.
        streak.tap()
        XCTAssertTrue(app.navigationBars["Your Streak"].waitForExistence(timeout: 5))
        let today = Date.now.formatted(.dateTime.month(.wide).day())
        let todayCell = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Today, \(today), read")).firstMatch
        XCTAssertTrue(todayCell.waitForExistence(timeout: 5))
        attachScreenshot(named: "streak-calendar")
        app.buttons["Done"].tap()

        // Settings lives on Browse.
        XCTAssertFalse(app.buttons["Settings"].exists)
        app.openSettings()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Browse"].waitForExistence(timeout: 5))
    }

    func testSwipingFromTheOpeningCardReachesTheFirstVerse() {
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 10))
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Jeremiah 31:1"].waitForExistence(timeout: 5))
        app.revealControls()
        XCTAssertTrue(app.buttons["1-day reading streak"].waitForExistence(timeout: 5))
    }

    func testControlsStepAsideWhileReading() {
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 10))
        let tabBar = app.descendants(matching: .any).matching(identifier: "Tab bar").firstMatch
        XCTAssertTrue(tabBar.exists)

        // Reading: the tab bar steps aside.
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Jeremiah 31:1"].waitForExistence(timeout: 5))
        XCTAssertTrue(tabBar.waitForNonExistence(timeout: 3))

        // A tap brings the tab bar back, and the next swipe sends it away again.
        app.revealControls()
        XCTAssertTrue(tabBar.waitForExistence(timeout: 3))
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Jeremiah 31:2"].waitForExistence(timeout: 5))
        XCTAssertTrue(tabBar.waitForNonExistence(timeout: 3))
    }

    func testBrowseCoversOpenOnTheLastBookRead() {
        // With nothing read yet, the middle book is in front, with neighbors on both sides.
        app.tab("Browse").tap()
        let bookOfMormon = app.buttons["Book of Mormon"]
        XCTAssertTrue(bookOfMormon.waitForExistence(timeout: 5))
        XCTAssertEqual(bookOfMormon.frame.midX, app.frame.midX, accuracy: 2)
        XCTAssertLessThan(app.buttons["New Testament"].frame.maxX, bookOfMormon.frame.minX)

        // Tapping an edge brings that book forward without opening it.
        app.buttons["New Testament"].coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.5)).tap()
        let newTestament = app.buttons["New Testament"]
        let isCentered = NSPredicate { _, _ in abs(newTestament.frame.midX - self.app.frame.midX) < 2 }
        wait(for: [expectation(for: isCentered, evaluatedWith: nil)], timeout: 5)
        XCTAssertTrue(app.navigationBars["Browse"].exists)

        // Reading the week's Jeremiah moves the covers to the Old Testament.
        app.tab("This Week").tap()
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 5))
        for _ in 1...2 { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Jeremiah 31:1"].waitForExistence(timeout: 5))
        app.tab("Browse").tap()
        let oldTestament = app.buttons["Old Testament"]
        XCTAssertTrue(oldTestament.waitForExistence(timeout: 5))
        let oldIsCentered = NSPredicate { _, _ in abs(oldTestament.frame.midX - self.app.frame.midX) < 2 }
        wait(for: [expectation(for: oldIsCentered, evaluatedWith: nil)], timeout: 5)
    }

    func testChoosingAnAppearance() {
        app.openSettings()

        // Try each choice, ending back on the default so the simulator is left as it was.
        for option in ["Dark", "Light", "Match Phone"] {
            app.buttons[option].tap()
            // The whole app redraws in the new colors, so give the button a moment to come back.
            XCTAssertTrue(app.buttons[option].waitForExistence(timeout: 5))
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
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 10))
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
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 5))
    }

    func testSkippingTheIntroAndSeeingItAgain() {
        relaunch(showingIntro: true)
        let skip = app.buttons["Skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 10))
        skip.tap()
        XCTAssertTrue(skip.waitForNonExistence(timeout: 5))

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
        XCTAssertTrue(app.descendants(matching: .any)["Version"].exists)
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
