import XCTest

/// Steps several UI tests share.
extension XCUIApplication {
    /// The shortest week in the schedule: John 1 is 51 verses, so its feed is 54 pages
    /// (opening card, chapter title, verses, closing card).
    static let shortWeek = (row: "Jan 11–17, John 1", pageCount: 54)

    /// Opens Settings from the gear at the top of This Week.
    func openSettings() {
        tabBars.buttons["This Week"].tap()
        buttons["Settings"].tap()
        XCTAssertTrue(navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    /// Opens a week from Browse > Reading Schedule, by its row's VoiceOver label ("Nov 9–15, Daniel 1–7").
    func openWeekFromSchedule(_ rowLabel: String) {
        tabBars.buttons["Browse"].tap()
        collectionViews.buttons["Reading Schedule"].tap()
        XCTAssertTrue(navigationBars["Reading Schedule"].waitForExistence(timeout: 5))

        // The list opens on this week, so swipe until the row is loaded and on screen.
        let row = buttons[rowLabel]
        for _ in 1...10 where !(row.exists && row.isHittable) {
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
