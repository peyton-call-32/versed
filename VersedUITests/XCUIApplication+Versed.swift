import XCTest

/// Steps several UI tests share.
extension XCUIApplication {
    /// The shortest week in the schedule: John 1 is 51 verses, so its feed is 54 pages
    /// (opening card, chapter title, verses, closing card).
    static let shortWeek = (row: "Jan 11–17, John 1", pageCount: 54)

    /// A button in the floating tab bar.
    /// The bar steps aside while reading, so this taps the page to bring it back first.
    func tab(_ title: String) -> XCUIElement {
        let button = buttons.matching(identifier: "Tab \(title)").firstMatch
        if !button.waitForExistence(timeout: 1) { revealControls() }
        _ = button.waitForExistence(timeout: 3)
        return button
    }

    /// One tap on the page brings back the controls that step aside while reading.
    func revealControls() {
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// Brings a volume's cover to the middle of Browse, so its books show underneath.
    func openVolume(_ title: String) {
        let cover = showVolumeCover(title)
        cover.tap()
        sleep(1)
    }

    /// Swipes through Browse's covers until a volume's cover is on screen.
    @discardableResult
    func showVolumeCover(_ title: String) -> XCUIElement {
        let cover = buttons["Cover \(title)"]
        XCTAssertTrue(cover.waitForExistence(timeout: 5))
        let window = windows.firstMatch.frame
        for _ in 1...6 {
            let middle = cover.frame.midX
            if middle > window.minX, middle < window.maxX { break }
            let height = cover.frame.midY / window.height
            let (start, end) = middle > window.maxX ? (0.8, 0.2) : (0.2, 0.8)
            coordinate(withNormalizedOffset: CGVector(dx: start, dy: height))
                .press(forDuration: 0.05, thenDragTo: coordinate(withNormalizedOffset: CGVector(dx: end, dy: height)))
            sleep(1)
        }
        return cover
    }

    /// Opens a plan on Today, if it isn't already, and goes into its reading.
    func openPlan(_ title: String) {
        let read = buttons["Read \(title)"]
        if !read.waitForExistence(timeout: 2) {
            let row = buttons["Plan \(title)"]
            XCTAssertTrue(row.waitForExistence(timeout: 10))
            row.tap()
            sleep(1)
        }
        // At the largest text sizes the button is further down the page.
        for _ in 1...4 where !read.isHittable { swipeUp() }
        read.tap()
    }

    /// Opens the weekly plan's reading from Today.
    func openWeeklyPlan() {
        tab("Today").tap()
        openPlan("Come, Follow Me")
    }

    /// Goes back to Today's list of plans.
    func goToToday() {
        tab("Today").tap()
        let date = staticTexts["Today date"]
        if !date.waitForExistence(timeout: 1) { tab("Today").tap() }
        XCTAssertTrue(date.waitForExistence(timeout: 5))
    }

    /// The top edge of the floating tab bar, for checking nothing slides under it.
    var tabBarTop: CGFloat {
        descendants(matching: .any).matching(identifier: "Tab bar").firstMatch.frame.minY
    }

    /// Opens the Settings tab.
    func openSettings() {
        tab("Settings").tap()
        XCTAssertTrue(navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    /// Opens a week from the weekly plan's Reading Schedule, by its row's VoiceOver label ("Nov 9–15, Daniel 1–7").
    func openWeekFromSchedule(_ rowLabel: String) {
        tab("Today").tap()
        let details = buttons["Plan details, Come, Follow Me"]
        if !(details.waitForExistence(timeout: 2) && details.isHittable) {
            buttons["Plan Come, Follow Me"].tap()
            sleep(1)
        }
        details.tap()
        let schedule = scrollViews.buttons["Reading Schedule"]
        XCTAssertTrue(schedule.waitForExistence(timeout: 5))
        for _ in 1...3 where !schedule.isHittable { swipeUp() }
        schedule.tap()
        XCTAssertTrue(navigationBars["Reading Schedule"].waitForExistence(timeout: 5))

        // The list opens on this week, so swipe until the row is loaded and on screen.
        let row = buttons[rowLabel]
        for _ in 1...14 where !(row.exists && row.isHittable) {
            swipeUp()
        }
        row.tap()
    }

    /// Swipes from a week's opening card to its closing card. Extra swipes at the end do nothing.
    func swipeToEndOfWeek(pageCount: Int) {
        for _ in 1..<pageCount + 2 {
            swipeUp()
        }
    }
}
