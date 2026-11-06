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

    /// Brings a book cover on Browse to the middle and opens it. The first tap on a cover at
    /// the side only brings it forward, so swipe until it's in the middle, then tap.
    func openVolume(_ title: String) {
        let cover = showVolumeCover(title)
        for _ in 1...6 where abs(cover.frame.midX - frame.midX) > 5 {
            let moveLeft = cover.frame.midX > frame.midX
            let carousel = coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: cover.frame.midY))
            let target = carousel.withOffset(CGVector(dx: moveLeft ? -260 : 260, dy: 0))
            carousel.press(forDuration: 0.05, thenDragTo: target)
            sleep(1)
        }
        cover.tap()
    }

    /// Scrolls Browse down to the book covers.
    @discardableResult
    func showVolumeCover(_ title: String) -> XCUIElement {
        let cover = buttons[title]
        XCTAssertTrue(cover.waitForExistence(timeout: 5))
        let bar = descendants(matching: .any).matching(identifier: "Tab bar").firstMatch
        for _ in 1...3 where cover.frame.maxY > bar.frame.minY {
            swipeUp()
            sleep(1)
        }
        return cover
    }

    /// Opens the weekly plan from its row on Today.
    func openWeeklyPlan() {
        tab("Today").tap()
        let row = buttons["Plan Come, Follow Me"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
    }

    /// Goes back to Today's list of plans.
    func goToToday() {
        tab("Today").tap()
        if !navigationBars["Today"].waitForExistence(timeout: 1) { tab("Today").tap() }
        XCTAssertTrue(navigationBars["Today"].waitForExistence(timeout: 5))
    }

    /// The top edge of the floating tab bar, for checking nothing slides under it.
    var tabBarTop: CGFloat {
        descendants(matching: .any).matching(identifier: "Tab bar").firstMatch.frame.minY
    }

    /// Opens Settings from the gear at the top of Browse.
    func openSettings() {
        tab("Browse").tap()
        buttons["Settings"].tap()
        XCTAssertTrue(navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    /// Opens a week from Browse > Reading Schedule, by its row's VoiceOver label ("Nov 9–15, Daniel 1–7").
    func openWeekFromSchedule(_ rowLabel: String) {
        tab("Browse").tap()
        if !navigationBars["Browse"].waitForExistence(timeout: 1) { tab("Browse").tap() }
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
