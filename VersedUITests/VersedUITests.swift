import XCTest

/// Walks through the whole app the way a reader would, and captures the README screenshots on the way.
///
/// The app launches with `-ui-testing`, so it starts with nothing saved and never touches real data,
/// with `-today` set to a fixed date, so "this week" is always the week of Oct 26, 2026, and with
/// `-seed-weekly-plan`, so a weekly plan is waiting on Today.
/// To save the screenshots as files, run the tests with `TEST_RUNNER_SCREENSHOT_DIR` set to a folder.
@MainActor
final class VersedUITests: XCTestCase {
    let app = XCUIApplication()
    static let launchArguments = ["-ui-testing", "-today", "2026-10-28", "-seed-weekly-plan"]

    override func setUp() async throws {
        continueAfterFailure = false
        app.launchArguments = Self.launchArguments
        app.launch()
    }

    func testReadingSavingBrowsingAndResuming() {
        // Today shows the plan, and it opens on the week's card, which keeps the lesson link for the end.
        openPlan()
        XCTAssertFalse(onScreen(app.links.matching(identifier: "Open This Week's Lesson")).isHittable)
        attachScreenshot(named: "week-intro")

        // Swipe past the intro and the chapter title card to the second verse, then save it.
        app.swipeUp()
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.buttons["Save verse"].waitForExistence(timeout: 5))
        onScreen(app.buttons.matching(identifier: "Save verse")).tap()
        XCTAssertTrue(app.buttons["Remove from saved"].waitForExistence(timeout: 5))
        saveScreenshot(named: "1-this-week")

        // Reading a verse starts the streak, shown on Today.
        app.revealControls()
        app.goToToday()
        XCTAssertTrue(app.buttons["1-day reading streak"].waitForExistence(timeout: 5))

        // Browse to Alma 32 and read to verse 2.
        app.tab("Library").tap()
        app.openVolume("Book of Mormon")
        app.buttons["Alma"].tap()
        app.buttons["Alma 32"].tap()
        XCTAssertTrue(chapterHeading("Alma, Chapter 32").waitForExistence(timeout: 5))
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Alma 32:2"].waitForExistence(timeout: 5))

        // Back on the Browse list, Continue Reading points to where we stopped.
        app.revealControls()
        app.tab("Library").tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
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
        relaunch(extraArguments: ["-seed-book-plan"])
        XCTAssertTrue(app.buttons["Plan Book of Mormon"].waitForExistence(timeout: 10))
        saveScreenshot(named: "2-today")

        // Jeremiah 31:3, then save it and the next verse so the Saved tab has something to show.
        openPlan()
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

        app.tab("Library").tap()
        XCTAssertTrue(app.buttons["Cover Old Testament"].waitForExistence(timeout: 5))
        sleep(2)
        saveScreenshot(named: "3-browse")

        app.tab("Saved").tap()
        XCTAssertTrue(app.navigationBars["Saved"].waitForExistence(timeout: 5))
        saveScreenshot(named: "4-saved")
    }

    func testStartingTheWeeklyPlanGoesStraightToReading() {
        relaunch(seeded: false)
        XCTAssertTrue(app.staticTexts["What would you like to read?"].waitForExistence(timeout: 10))
        app.buttons["Come, Follow Me"].tap()

        // It joins this week by default, reading by week.
        XCTAssertTrue(app.buttons["Join This Week"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Join This Week"].isSelected)
        XCTAssertTrue(app.buttons["Week"].isSelected)
        attachScreenshot(named: "plan-setup-weekly")
        app.buttons["Start Plan"].tap()

        // Starting a plan opens its reading.
        XCTAssertTrue(weekHeading(containing: "This Week").waitForExistence(timeout: 5))

        // Back on Today it's waiting, by name, with the reading open.
        app.revealControls()
        app.goToToday()
        let row = app.buttons["Plan Come, Follow Me"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue((row.value as? String ?? "").contains("Jeremiah 31–33"))
        XCTAssertTrue(app.buttons["Read Come, Follow Me"].isHittable)
    }

    func testStartingTheScheduleFromTheBeginning() {
        relaunch(seeded: false)
        XCTAssertTrue(app.buttons["Come, Follow Me"].waitForExistence(timeout: 10))
        app.buttons["Come, Follow Me"].tap()
        app.buttons["Start from the Beginning"].tap()

        // Both years are offered, and it starts at week 1.
        XCTAssertTrue(app.buttons["New Testament 2027"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Old Testament 2026"].isSelected)
        attachScreenshot(named: "plan-setup-beginning")
        app.buttons["Start Plan"].tap()
        sleep(2)
        app.revealControls()
        app.goToToday()

        let row = app.buttons["Plan Come, Follow Me"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue((row.value as? String ?? "").hasPrefix("Week 1 of 52, Introduction"), "Got \(row.value ?? "")")
    }

    func testPlansOpenOneAtATimeAndCanAllClose() {
        relaunch(extraArguments: ["-seed-book-plan"])
        let weekly = app.buttons["Plan Come, Follow Me"]
        let book = app.buttons["Plan Book of Mormon"]
        XCTAssertTrue(weekly.waitForExistence(timeout: 10))

        // The top plan starts open.
        XCTAssertTrue(app.buttons["Read Come, Follow Me"].isHittable)
        XCTAssertFalse(app.buttons["Read Book of Mormon"].exists)

        // Opening another closes it, and tapping the open one closes it too.
        book.tap()
        sleep(1)
        // isHittable misreads a button inside the band that just opened, though a tap works,
        // so check it sits fully on screen instead.
        let readBook = app.buttons["Read Book of Mormon"]
        XCTAssertTrue(readBook.exists)
        XCTAssertTrue(app.windows.firstMatch.frame.contains(readBook.frame))
        XCTAssertFalse(app.buttons["Read Come, Follow Me"].exists)
        book.tap()
        sleep(1)
        XCTAssertFalse(app.buttons["Read Book of Mormon"].exists)
        XCTAssertFalse(app.buttons["Read Come, Follow Me"].exists)
    }

    func testFinishedPlansShowItAndTheNextOneOpens() {
        relaunch(extraArguments: ["-seed-book-plan", "-seed-done-first"])
        let weekly = app.buttons["Plan Come, Follow Me"]
        XCTAssertTrue(weekly.waitForExistence(timeout: 10))
        XCTAssertTrue((weekly.value as? String ?? "").contains("Done"), "Got \(weekly.value ?? "")")
        XCTAssertTrue(app.buttons["Read Book of Mormon"].isHittable)
        XCTAssertEqual(app.buttons["Read Book of Mormon"].label, "Start Reading")
    }

    func testReorderingPlansInSettings() {
        relaunch(extraArguments: ["-seed-book-plan"])
        XCTAssertTrue(app.buttons["Read Come, Follow Me"].waitForExistence(timeout: 10))
        app.openSettings()
        app.buttons["Reorder Plans"].tap()
        XCTAssertTrue(app.navigationBars["Reorder Plans"].waitForExistence(timeout: 5))
        attachScreenshot(named: "reorder-plans")
        let handle = app.buttons["Reorder Book of Mormon"]
        XCTAssertTrue(handle.waitForExistence(timeout: 5))
        handle.press(forDuration: 0.5, thenDragTo: app.buttons["Reorder Come, Follow Me"], withVelocity: .slow, thenHoldForDuration: 0.5)
        sleep(1)
        app.tab("Today").tap()

        // The new top plan comes first.
        let weekly = app.buttons["Plan Come, Follow Me"]
        let book = app.buttons["Plan Book of Mormon"]
        XCTAssertTrue(book.waitForExistence(timeout: 5))
        XCTAssertLessThan(book.frame.minY, weekly.frame.minY)
    }

    func testTheLibraryShowsOnlyTheBooksTheReaderKeeps() {
        app.tab("Library").tap()

        // A new reader has every book, opening on this year's weekly schedule.
        XCTAssertTrue(app.buttons["Cover Come, Follow Me"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Cover Pearl of Great Price"].exists)
        XCTAssertFalse(app.buttons["Continue Reading"].exists)

        // Another cover brings what's inside it.
        app.openVolume("Old Testament")
        XCTAssertTrue(app.buttons["Genesis"].waitForExistence(timeout: 5))

        // A single book lists its sections right there.
        app.openVolume("Doctrine and Covenants")
        XCTAssertTrue(app.buttons["D&C 1"].waitForExistence(timeout: 5))

        // Removing books takes their covers away, even the one on show, and adding one brings it back.
        app.buttons["Your Library"].tap()
        app.buttons["Remove Doctrine and Covenants"].tap()
        app.buttons["Remove Old Testament"].tap()
        app.buttons["Done"].tap()
        XCTAssertFalse(app.buttons["Cover Doctrine and Covenants"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["Cover Old Testament"].exists)

        app.buttons["Your Library"].tap()
        app.buttons["Add Old Testament"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Cover Old Testament"].waitForExistence(timeout: 5))
    }

    func testAReaderCanEmptyTheirLibraryAndStartAgain() {
        app.tab("Library").tap()
        app.buttons["Your Library"].tap()
        for name in ["Come, Follow Me Old Testament 2026", "Old Testament", "New Testament", "Book of Mormon", "Doctrine and Covenants", "Pearl of Great Price"] {
            app.buttons["Remove \(name)"].tap()
        }
        app.buttons["Done"].tap()

        let add = app.buttons["Add a Book"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        app.buttons["Add Book of Mormon"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["1 Nephi"].waitForExistence(timeout: 5))
    }

    func testTheWeeklyCoverOpensThisWeekWithNoPlan() {
        app.tab("Library").tap()
        let thisWeek = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "This week, Oct 26 – Nov 1")).firstMatch
        XCTAssertTrue(thisWeek.waitForExistence(timeout: 5))
        thisWeek.tap()
        XCTAssertFalse(app.navigationBars["Library"].waitForExistence(timeout: 2))
    }

    func testSettingsScrollsAllTheWayClearOfTheTabBar() {
        app.openSettings()
        let lastLine = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Scripture text is in the public domain")).firstMatch
        for _ in 1...4 { app.swipeUp() }
        XCTAssertTrue(lastLine.waitForExistence(timeout: 5))
        sleep(1)
        XCTAssertLessThanOrEqual(lastLine.frame.maxY, app.descendants(matching: .any).matching(identifier: "Tab bar").firstMatch.frame.minY)
    }

    func testFindingAChapter() {
        app.tab("Library").tap()
        app.buttons["Find a Book"].tap()
        let field = app.textFields["Search scriptures"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("Alma 32")
        app.buttons["Alma 32"].tap()
        XCTAssertTrue(chapterHeading("Alma, Chapter 32").waitForExistence(timeout: 5))
    }

    func testMakingAPlanForABookAndFinishingIt() {
        relaunch(seeded: false)
        XCTAssertTrue(app.buttons["Choose Something Else"].waitForExistence(timeout: 10))
        app.buttons["Choose Something Else"].tap()

        // Pick a book from the picker. Obadiah is one short chapter.
        app.buttons["Pick Old Testament"].tap()
        let book = app.buttons["Obadiah"]
        for _ in 1...5 where !(book.exists && book.isHittable) { app.swipeUp() }
        book.tap()

        // The preview follows the choices.
        XCTAssertTrue(app.buttons["Start Plan"].waitForExistence(timeout: 5))
        let preview = app.descendants(matching: .any).matching(identifier: "Plan preview").firstMatch
        XCTAssertTrue(preview.label.contains("About 1 chapter a day"), "Got \(preview.label)")
        app.buttons["Week"].tap()
        XCTAssertTrue(preview.label.contains("About 1 chapter a week"), "Got \(preview.label)")
        attachScreenshot(named: "plan-setup-book")
        app.buttons["Day"].tap()
        app.buttons["Start Plan"].tap()

        // Starting it opens its reading.
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 5))
        let row = app.buttons["Plan Obadiah"]

        // Opening card, chapter card, 21 verses, closing card.
        for _ in 1...24 { app.swipeUp() }
        let end = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "End of the Plan, Obadiah 1")).firstMatch
        XCTAssertTrue(end.waitForExistence(timeout: 5))
        attachScreenshot(named: "plan-finished")

        onScreen(app.buttons.matching(identifier: "Back to Today")).tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue((row.value as? String ?? "").contains("You finished this plan"), "Got \(row.value ?? "")")
    }

    func testPlansSitTogetherOnToday() {
        relaunch(extraArguments: ["-seed-book-plan"])
        let weekly = app.buttons["Plan Come, Follow Me"]
        let book = app.buttons["Plan Book of Mormon"]
        XCTAssertTrue(weekly.waitForExistence(timeout: 10))
        XCTAssertTrue(book.exists)
        XCTAssertLessThan(weekly.frame.maxY, book.frame.minY + 1)
        attachScreenshot(named: "today-two-plans")

        // Each keeps its own place: reading one doesn't move the other.
        app.openPlan("Book of Mormon")
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 5))
        for _ in 1...3 { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["1 Nephi 1:2"].waitForExistence(timeout: 5))
        app.revealControls()
        app.goToToday()
        app.openPlan("Come, Follow Me")
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 5))
        app.goToToday()
        app.openPlan("Book of Mormon")
        XCTAssertTrue(app.staticTexts["Swipe up to continue reading"].waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["1 Nephi 1:2"].waitForExistence(timeout: 5))
    }

    func testChangingAndRemovingAPlan() {
        relaunch(extraArguments: ["-seed-book-plan"])
        XCTAssertTrue(app.buttons["Plan Book of Mormon"].waitForExistence(timeout: 10))
        app.buttons["Plan Book of Mormon"].tap()
        sleep(1)
        app.buttons["Plan details, Book of Mormon"].tap()
        XCTAssertTrue(app.navigationBars["Book of Mormon"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Day"].isSelected)
        attachScreenshot(named: "plan-details")

        // Reading by week changes what Today says.
        app.buttons["Week"].tap()
        XCTAssertTrue(app.buttons["Week"].isSelected)
        app.navigationBars.buttons.firstMatch.tap()
        let row = app.buttons["Plan Book of Mormon"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue((row.value as? String ?? "").hasPrefix("Week 1 of"), "Got \(row.value ?? "")")

        // Removing it leaves the other plan.
        row.tap()
        sleep(1)
        app.buttons["Plan details, Book of Mormon"].tap()
        let remove = app.buttons["Remove Plan"]
        for _ in 1...3 where !remove.isHittable { app.swipeUp() }
        remove.tap()
        app.sheets.buttons["Remove Plan"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Today date"].waitForExistence(timeout: 5))
        XCTAssertFalse(row.waitForExistence(timeout: 1))
        XCTAssertTrue(app.buttons["Plan Come, Follow Me"].exists)
    }

    func testABookOffersAPlanWithoutRequiringOne() {
        app.tab("Library").tap()
        app.openVolume("Book of Mormon")
        let volumePlan = app.buttons["Make a Plan for the Book of Mormon"]
        XCTAssertTrue(volumePlan.waitForExistence(timeout: 5))
        XCTAssertTrue(volumePlan.isHittable)
        app.buttons["Alma"].tap()
        XCTAssertTrue(app.buttons["Make a Plan for Alma"].waitForExistence(timeout: 5))

        // A chapter still opens right away, with no plan asked for.
        app.buttons["Alma 32"].tap()
        XCTAssertTrue(chapterHeading("Alma, Chapter 32").waitForExistence(timeout: 5))
    }

    func testOpeningAWeekFromTheReadingSchedule() {
        app.buttons["Plan details, Come, Follow Me"].tap()
        app.scrollViews.buttons["Reading Schedule"].tap()
        XCTAssertTrue(app.navigationBars["Reading Schedule"].waitForExistence(timeout: 5))

        // The current week is marked, and every week shows its dates and chapters.
        let current = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "This week, Oct 26 – Nov 1")).firstMatch
        XCTAssertTrue(current.waitForExistence(timeout: 5))
        XCTAssertTrue(current.isSelected)
        attachScreenshot(named: "reading-schedule")

        // Tapping another week opens its chapters in the feed.
        app.buttons["Nov 9–15, Daniel 1–7"].tap()
        XCTAssertTrue(weekHeading(containing: "Daniel 1–7").waitForExistence(timeout: 5))
        XCTAssertTrue(weekHeading(containing: "Week Of").exists)
        XCTAssertTrue(app.buttons["Week of Nov 9–15"].exists)
        app.swipeUp()
        XCTAssertTrue(chapterHeading("Daniel, Chapter 1").waitForExistence(timeout: 5))
    }

    func testChapterMenuMovesAroundTheWeek() {
        openPlan()
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
        openPlan()
        for _ in 1...4 { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Jeremiah 31:3"].waitForExistence(timeout: 5))
        app.tab("Today").tap()
        XCTAssertTrue(app.staticTexts["Today date"].waitForExistence(timeout: 5))

        app.tab("Library").tap()
        app.openVolume("Book of Mormon")
        app.buttons["Alma"].tap()
        XCTAssertTrue(app.buttons["Alma 32"].waitForExistence(timeout: 5))
        app.tab("Library").tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
    }

    /// Psalms is the longest book, so this also checks that opening near its end works.
    func testBrowseChapterMenuReachesEarlierChapters() {
        app.tab("Library").tap()
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
        // Waits for each swipe to settle: one more swipe at the top would close the sheet.
        for _ in 1...10 where !(firstPsalm.exists && firstPsalm.isHittable) {
            app.swipeDown()
            sleep(1)
        }
        firstPsalm.tap()
        XCTAssertTrue(chapterHeading("Psalms, Chapter 1").waitForExistence(timeout: 10))
    }

    func testAPlanPicksUpWhereTheReaderStopped() {
        // Read to Jeremiah 31:3: past the opening card, the chapter title, and two verses.
        openPlan()
        for _ in 1...4 { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Jeremiah 31:3"].waitForExistence(timeout: 5))

        // Leave for another week, then come back to the plan.
        app.openWeekFromSchedule("Nov 9–15, Daniel 1–7")
        XCTAssertTrue(weekHeading(containing: "Daniel 1–7").waitForExistence(timeout: 5))
        app.goToToday()
        app.openPlan("Come, Follow Me")

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
        openPlan()
        app.buttons["Lamentations 3"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["Lamentations, Chapter 3"].waitForExistence(timeout: 5))

        // Swiping up from there keeps reading that chapter.
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Lamentations 3:1"].waitForExistence(timeout: 5))
    }

    func testTappingASectionWorksWhenResuming() {
        openPlan()
        for _ in 1...4 { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Jeremiah 31:3"].waitForExistence(timeout: 5))
        app.revealControls()
        app.goToToday()
        app.openPlan("Come, Follow Me")
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

        // Reopen the finished week from the schedule.
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Reading Schedule"].waitForExistence(timeout: 5))
        app.buttons[XCUIApplication.shortWeek.row].tap()

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

    func testTodayHeaderAndStreak() {
        // The streak sits at the top right of Today, with no count until a verse is read.
        XCTAssertTrue(app.buttons["Reading streak"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["1-day reading streak"].exists)

        // The chapter menu sits in the middle while reading.
        openPlan()
        let weekMenu = app.buttons["Chapter menu"]
        XCTAssertTrue(weekMenu.waitForExistence(timeout: 10))
        XCTAssertEqual(weekMenu.frame.midX, app.frame.midX, accuracy: 1)
        for _ in 1...3 { app.swipeUp() }
        app.revealControls()
        app.goToToday()

        // Tapping the count opens the calendar, with today marked as read.
        let streak = app.buttons["1-day reading streak"]
        XCTAssertTrue(streak.waitForExistence(timeout: 5))
        attachScreenshot(named: "today-header")
        streak.tap()
        XCTAssertTrue(app.navigationBars["Your Streak"].waitForExistence(timeout: 5))
        let today = Date.now.formatted(.dateTime.month(.wide).day())
        let todayCell = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Today, \(today), read")).firstMatch
        XCTAssertTrue(todayCell.waitForExistence(timeout: 5))
        attachScreenshot(named: "streak-calendar")
        app.buttons["Done"].tap()

        // Settings is its own tab.
        app.openSettings()
    }

    func testSwipingFromTheOpeningCardReachesTheFirstVerse() {
        openPlan()
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Jeremiah 31:1"].waitForExistence(timeout: 5))
        app.revealControls()
        app.goToToday()
        XCTAssertTrue(app.buttons["1-day reading streak"].waitForExistence(timeout: 5))
    }

    func testControlsStepAsideWhileReading() {
        openPlan()
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

    }

    func testAppearanceIsRememberedAfterRelaunch() {
        app.openSettings()
        app.buttons["Dark"].tap()

        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["Today date"].waitForExistence(timeout: 10))
        attachScreenshot(named: "appearance-after-relaunch")

        // Put the default back so the simulator is left as it was.
        app.openSettings()
        XCTAssertTrue(app.buttons["Dark"].isSelected)
        app.buttons["Match Phone"].tap()
    }

    func testFirstTimeIntro() {
        relaunch(seeded: false, extraArguments: ["-show-intro"])
        XCTAssertTrue(app.staticTexts["Swipe Up for the Next Verse"].waitForExistence(timeout: 10))
        saveScreenshot(named: "4-intro")

        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Double-Tap to Save"].waitForExistence(timeout: 5))
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Read at Your Own Pace"].waitForExistence(timeout: 5))

        // The last page carries the one line that names the reading schedule.
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label == %@", Self.independenceNotice)).firstMatch.exists)

        // The last page offers the reminder, with no Skip since Not Now does the same thing.
        XCTAssertTrue(app.buttons["Not Now"].exists)
        XCTAssertFalse(app.buttons["Skip"].exists)
        attachScreenshot(named: "intro-reminder-offer")

        // With nothing chosen yet, Today asks what to read. No plan is started on the reader's behalf.
        app.buttons["Not Now"].tap()
        XCTAssertTrue(app.staticTexts["What would you like to read?"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Plan Come, Follow Me"].exists)
    }

    func testSkippingTheIntroAndSeeingItAgain() {
        relaunch(extraArguments: ["-show-intro"])
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
            reminder.tap()
        }
        XCTAssertEqual(reminder.value as? String, "0")
        XCTAssertFalse(app.buttons["Time Picker"].exists, "The time only shows once the reminder is on.")

        reminder.tap()

        // iOS asks for permission the first time only. Allow it if it asks.
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.buttons["Allow"]
        if allow.waitForExistence(timeout: 3) {
            allow.tap()
        }

        XCTAssertTrue(app.buttons["Time Picker"].waitForExistence(timeout: 5))
        XCTAssertEqual(reminder.value as? String, "1")
        attachScreenshot(named: "daily-reminder-on")

        // Turn it back off so the simulator is left as it was.
        reminder.tap()
        XCTAssertFalse(app.buttons["Time Picker"].waitForExistence(timeout: 2))
    }

    static let independenceNotice = "The Come, Follow Me plan follows the published reading schedule of The Church of Jesus Christ of Latter-day Saints. Versed is an independent app and is not made, approved, or endorsed by The Church of Jesus Christ of Latter-day Saints."

    /// The week intro card's heading, which VoiceOver reads as one line: "This Week, Daniel 1–7, Nov 9–15".
    /// A chapter's title card, which VoiceOver reads as one heading: "Alma, Chapter 32".
    private func chapterHeading(_ label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    private func weekHeading(containing text: String) -> XCUIElement {
        let match = NSPredicate(format: "label CONTAINS %@", text)
        return onScreen(app.descendants(matching: .any).matching(match).matching(NSPredicate(format: "label CONTAINS %@", ",")))
    }

    /// Restarts the app, with or without the weekly plan already started.
    private func relaunch(seeded: Bool = true, extraArguments: [String] = []) {
        app.terminate()
        app.launchArguments = Self.launchArguments.filter { seeded || $0 != "-seed-weekly-plan" } + extraArguments
        app.launch()
    }

    /// Opens the weekly plan from Today, on its opening card.
    private func openPlan() {
        app.openWeeklyPlan()
        XCTAssertTrue(app.staticTexts["Swipe up to start reading"].waitForExistence(timeout: 10))
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
