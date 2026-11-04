import SwiftData
import SwiftUI

/// Opens to this week's reading. A header row sits on top: the chapter menu on the left, and
/// the streak on the right, which opens the streak calendar.
///
/// Each week opens on its opening card. Swiping up goes to the page where the reader left off,
/// or to the start once the week has been read to its closing card.
struct WeeklyReadingView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule
    let navigation: FeedNavigation

    @Environment(\.modelContext) private var modelContext

    /// The week picked from the menu or the schedule in Browse, or `nil` to show this week.
    @Binding var selectedWeekID: ReadingWeek.ID?

    private var selectedWeek: ReadingWeek? {
        schedule.weeks.first { $0.id == selectedWeekID } ?? schedule.currentWeek()
    }

    var body: some View {
        if let week = selectedWeek {
            let positions = ReadingPositionStore(context: modelContext)
            let items: [FeedItem] = [.weekIntro(week)] + library.feedItems(for: week.passages) + [.weekEnd(week)]
            FeedView(
                items: items,
                startingAt: positions.position(in: .week(week.id)),
                showsFirstPageOnResume: true,
                navigation: navigation,
                onPageChange: { itemID in
                    // Reaching the closing card finishes the week, so next time it starts over.
                    if itemID == FeedItem.weekEnd(week).id {
                        positions.clearPosition(in: .week(week.id))
                    } else {
                        positions.setPosition(itemID, in: .week(week.id))
                    }
                }
            )
            // A new identity per week reopens each week's feed at its own saved page.
            .id(week.id)
            .overlay(alignment: .top) {
                header(selected: week, items: items)
            }
        } else {
            ContentUnavailableView("No reading schedule", systemImage: "calendar")
        }
    }

    private func header(selected: ReadingWeek, items: [FeedItem]) -> some View {
        HStack {
            ChapterMenu(
                library: library,
                items: items,
                navigation: navigation,
                weekOptions: .init(schedule: schedule, dates: selected.dateRangeText()) { selectedWeekID = $0 }
            )
            Spacer(minLength: 8)
            StreakBadge()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

#Preview {
    @Previewable @State var selectedWeekID: ReadingWeek.ID?
    WeeklyReadingView(library: try! ScriptureLibrary.loadBundled(), schedule: try! ReadingSchedule.loadBundled(), navigation: FeedNavigation(), selectedWeekID: $selectedWeekID)
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
