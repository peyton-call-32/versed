import XCTest

/// Walks through every screen and saves a full-size picture of each, for reviewing the design by eye.
/// Only runs when a folder is given, so it stays out of the normal test run:
/// `TEST_RUNNER_VERSED_AUDIT_DIR=/some/folder TEST_RUNNER_VERSED_AUDIT_APPEARANCE=dark xcodebuild test
/// -only-testing:VersedUITests/DesignAuditUITests ...`. `TEST_RUNNER_VERSED_AUDIT_TEXT_SIZE` picks a text size.
@MainActor
final class DesignAuditUITests: XCTestCase {
    private var outputFolder: URL!
    private var app: XCUIApplication!
    private var appearance = "light"

    override func setUp() async throws {
        continueAfterFailure = true
        let environment = ProcessInfo.processInfo.environment
        try XCTSkipIf(environment["VERSED_AUDIT_DIR"] == nil, "Set VERSED_AUDIT_DIR to run the design audit.")
        appearance = environment["VERSED_AUDIT_APPEARANCE"] ?? "light"
        outputFolder = URL(fileURLWithPath: environment["VERSED_AUDIT_DIR"]!, isDirectory: true)
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)
    }

    private func launch(_ extra: [String] = []) {
        app = XCUIApplication()
        var textSize: [String] = []
        if let size = ProcessInfo.processInfo.environment["VERSED_AUDIT_TEXT_SIZE"] {
            textSize = ["-UIPreferredContentSizeCategoryName", size]
        }
        app.launchArguments = ["-ui-testing", "-today", "2026-10-28", "-appearance", appearance, "-seed-weekly-plan", "-seed-book-plan", "-seed-streak"] + textSize + extra
        app.launch()
    }

    private func shoot(_ name: String) {
        sleep(1)
        let data = XCUIScreen.main.screenshot().pngRepresentation
        try? data.write(to: outputFolder.appendingPathComponent("\(appearance)-\(name).png"))
    }

    /// The feed keeps the neighboring pages loaded, so there can be several hearts. This taps the one on screen.
    private func tapVisibleHeart() {
        let hearts = app.buttons.matching(identifier: "Save verse").allElementsBoundByIndex
        hearts.first { app.frame.contains($0.frame) }?.tap()
    }

    func test1Intro() {
        launch(["-show-intro"])
        shoot("00-intro-1")
        app.buttons["Next"].tap()
        shoot("01-intro-2")
        app.buttons["Next"].tap()
        shoot("02-intro-3")
    }

    func test2Week() {
        launch()
        shoot("09-today")
        app.buttons["Plan Book of Mormon"].tap()
        shoot("09-today-second-open")
        app.buttons["Plan Book of Mormon"].tap()
        shoot("09-today-all-closed")
        app.buttons["Plan Book of Mormon"].tap()
        sleep(1)
        app.buttons["Plan details, Book of Mormon"].tap()
        shoot("09-plan-details")
        app.terminate()

        launch()
        app.openWeeklyPlan()
        shoot("10-week-open")
        app.swipeUp()
        shoot("11-chapter-opening")
        app.revealControls()
        shoot("12-chapter-opening-revealed")
        app.swipeUp()
        shoot("13-verse")
        app.revealControls()
        shoot("14-verse-revealed")
        tapVisibleHeart()
        shoot("15-verse-saved")
        app.buttons["Chapter menu"].tap()
        shoot("16-go-to")
        app.buttons["Done"].tap()
        sleep(1)
        app.goToToday()
        app.buttons["Streak"].tap()
        shoot("18-streak")
        app.buttons["Done"].tap()
        sleep(1)
        app.tab("Saved").tap()
        shoot("30-saved")
    }

    func test2bDoneStates() {
        launch(["-seed-done-first"])
        shoot("09-today-one-done")
        app.terminate()
        launch(["-seed-done-all"])
        shoot("09-today-all-done")
        app.buttons["Plan Come, Follow Me"].tap()
        shoot("09-today-read-ahead")
    }

    func test3Browse() {
        launch()
        app.buttons["Add a Plan"].tap()
        shoot("20-picker")
        app.buttons["Pick Old Testament"].tap()
        shoot("20-picker-books")
        app.buttons["Genesis"].tap()
        shoot("20-setup-book")
        app.buttons["By a Date"].tap()
        shoot("20-setup-book-date")
        app.buttons["Cancel"].tap()
        sleep(1)
        app.tab("Library").tap()
        shoot("20-library")
        app.buttons["Your Library"].tap()
        shoot("20-your-library")
        app.buttons["Remove Pearl of Great Price"].tap()
        shoot("20-your-library-removed")
        app.buttons["Add Pearl of Great Price"].tap()
        app.buttons["Done"].tap()
        sleep(1)
        app.buttons["Find a Book"].tap()
        shoot("20-find")
        app.textFields["Search scriptures"].typeText("Alma 32")
        shoot("20-find-results")
        app.buttons["Cancel"].tap()
        sleep(1)
        app.openVolume("Doctrine and Covenants")
        shoot("21-sections")
        app.openVolume("Book of Mormon")
        shoot("22-books")
        app.buttons["Alma"].tap()
        shoot("23-chapters")
        // At the largest text sizes the chapter is further down the page.
        let chapter = app.buttons["Alma 32"]
        for _ in 1...6 where !(chapter.exists && chapter.isHittable) { app.swipeUp() }
        chapter.tap()
        shoot("24-browse-chapter-opening")
        app.swipeUp()
        shoot("25-browse-verse")
        app.revealControls()
        shoot("26-browse-verse-revealed")
        app.tab("Library").tap()
        app.tab("Library").tap()
        shoot("27-browse-continue")
    }

    func test4SavedEmptyAndSettings() {
        launch()
        app.tab("Saved").tap()
        shoot("31-saved-empty")
        app.openSettings()
        shoot("40-settings")
        app.buttons["Reorder Plans"].tap()
        shoot("40-reorder")
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)
        for _ in 1...4 { app.swipeUp() }
        sleep(1)
        shoot("41-settings-bottom")
    }

    func test5OtherWeeks() {
        launch()
        app.openWeekFromSchedule("Dec 21–27, Christmas")
        shoot("50-week-christmas")
        app.terminate()

        launch()
        app.openWeekFromSchedule(XCUIApplication.shortWeek.row)
        sleep(1)
        shoot("51-week-john")
        app.swipeToEndOfWeek(pageCount: XCUIApplication.shortWeek.pageCount)
        shoot("52-week-end")
    }

    /// One long pass through the app's motion, for a screen recording to be checked frame by frame.
    /// Writes when each step starts, so each one can be found in the recording.
    func test6Motion() {
        launch()
        app.openWeeklyPlan()
        var log = ""
        func step(_ name: String, _ action: () -> Void) {
            sleep(2)
            log += "\(Date().timeIntervalSince1970) \(name)\n"
            action()
        }
        step("week-to-chapter") { app.swipeUp() }
        step("chapter-to-verse") { app.swipeUp() }
        step("verse-to-verse") { app.swipeUp() }
        step("reveal") { app.revealControls() }
        step("swipe-hides") { app.swipeUp() }
        step("heart") { tapVisibleHeart() }
        step("double-tap") { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).doubleTap() }
        step("reveal-2") { app.revealControls() }
        step("go-to-open") { app.buttons["Chapter menu"].tap() }
        step("go-to-close") { app.buttons["Done"].tap() }
        step("tab-today-return") { app.goToToday() }
        step("plan-open-second") { app.buttons["Plan Book of Mormon"].tap() }
        step("plan-close") { app.buttons["Plan Book of Mormon"].tap() }
        step("plan-open-first") { app.buttons["Plan Come, Follow Me"].tap() }
        step("plan-details") { app.buttons["Plan details, Come, Follow Me"].tap() }
        step("plan-details-back") { app.navigationBars.buttons.firstMatch.tap() }
        step("ribbon") { app.buttons["Streak"].tap() }
        step("ribbon-close") { app.buttons["Done"].tap() }
        step("tab-browse") { app.tab("Library").tap() }
        step("cover-next") { app.buttons["Cover Old Testament"].tap() }
        step("book-open") { app.buttons["Genesis"].tap() }
        step("book-back") { app.navigationBars.buttons.firstMatch.tap() }
        step("tab-saved") { app.tab("Saved").tap() }
        step("tab-settings") { app.tab("Settings").tap() }
        step("tab-today") { app.tab("Today").tap() }
        sleep(2)
        try? log.write(to: outputFolder.appendingPathComponent("\(appearance)-motion.log"), atomically: true, encoding: .utf8)
    }
}
