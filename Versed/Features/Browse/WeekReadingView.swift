import SwiftData
import SwiftUI

/// One week of the schedule, opened on its own, apart from any plan. Each week opens on its
/// opening card, and swiping up goes to where the reader left off, or to the start once the week
/// has been read to its closing card.
struct WeekReadingView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule
    /// The week on screen. "Other Weeks" in the chapter menu changes it.
    @State var weekID: ReadingWeek.ID

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if let week = schedule.weeks.first(where: { $0.id == weekID }) {
            let positions = ReadingPositionStore(context: modelContext)
            let reading = ReadingPortion(week: week)
            let items = library.feedItems(for: reading)
            PagedReadingView(
                library: library,
                items: items,
                startingAt: positions.position(in: .week(week.id)),
                showsFirstPageOnResume: true,
                menuOptions: .init(
                    spokenPlace: "Week of \(week.dateRangeText())",
                    otherWeeks: .init(schedule: schedule) { weekID = $0 }
                ),
                onPageChange: { itemID in
                    // Reaching the closing card finishes the week, so next time it starts over.
                    if itemID == FeedItem.closing(reading).id {
                        positions.clearPosition(in: .week(week.id))
                    } else {
                        positions.setPosition(itemID, in: .week(week.id))
                    }
                }
            )
            // A new identity per week reopens each week's feed at its own saved page.
            .id(week.id)
            .background(Color.appBackground)
        }
    }
}
