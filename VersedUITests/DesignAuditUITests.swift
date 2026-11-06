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
        app.launchArguments = ["-ui-testing", "-today", "2026-10-28", "-appearance", appearance, "-seed-weekly-plan", "-seed-book-plan"] + textSize + extra
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
        app.buttons["Plan details, Book of Mormon"].tap()
        shoot("09-plan-details")
        app.terminate()

        launch()
        app.buttons["Plan Book of Mormon"].tap()
        shoot("09-plan-open")
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

    func test3Browse() {
        launch()
        app.tab("Browse").tap()
        shoot("20-browse")
        app.buttons["weekly-reading"].tap()
        shoot("20-setup-weekly")
        app.buttons["Start from the Beginning"].tap()
        shoot("20-setup-beginning")
        app.buttons["Cancel"].tap()
        sleep(1)
        app.buttons["Make Your Own Plan"].tap()
        shoot("20-picker")
        app.buttons["Pick Old Testament"].tap()
        shoot("20-picker-books")
        app.buttons["Genesis"].tap()
        shoot("20-setup-book")
        app.buttons["By a Date"].tap()
        shoot("20-setup-book-date")
        app.buttons["Cancel"].tap()
        sleep(1)
        app.showVolumeCover("Book of Mormon")
        shoot("20-browse-scriptures")
        app.swipeDown()
        sleep(1)
        app.scrollViews.buttons["Reading Schedule"].tap()
        shoot("21-schedule")
        app.terminate()

        launch()
        app.tab("Browse").tap()
        app.openVolume("Book of Mormon")
        shoot("22-books")
        app.buttons["Alma"].tap()
        shoot("23-chapters")
        app.buttons["Alma 32"].tap()
        shoot("24-browse-chapter-opening")
        app.swipeUp()
        shoot("25-browse-verse")
        app.revealControls()
        shoot("26-browse-verse-revealed")
    }

    func test4SavedEmptyAndSettings() {
        launch()
        app.tab("Saved").tap()
        shoot("31-saved-empty")
        app.openSettings()
        shoot("40-settings")
        app.swipeUp()
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
        step("tab-browse") { app.tab("Browse").tap() }
        step("cover-swipe") { app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.35)).press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.35))) }
        step("cover-open") { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap() }
        step("cover-back") { app.navigationBars.buttons.firstMatch.tap() }
        step("tab-saved") { app.tab("Saved").tap() }
        step("tab-today") { app.tab("Today").tap() }
        step("settings-tab") { app.tab("Browse").tap() }
        step("settings-open") { app.buttons["Settings"].tap() }
        step("settings-close") { app.buttons["Done"].tap() }
        sleep(2)
        try? log.write(to: outputFolder.appendingPathComponent("\(appearance)-motion.log"), atomically: true, encoding: .utf8)
    }
}
