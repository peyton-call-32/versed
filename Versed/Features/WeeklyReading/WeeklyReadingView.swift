import SwiftData
import SwiftUI

/// Opens to this week's reading. A header row sits on top: the chapter menu in the middle, and
/// the streak on the right, which opens the streak calendar.
///
/// Each week opens on its opening card. Swiping up goes to the page where the reader left off,
/// or to the start once the week has been read to its closing card.
struct WeeklyReadingView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule
    let navigation: FeedNavigation

    @Environment(\.modelContext) private var modelContext
    @Environment(ReadingChrome.self) private var chrome

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
            .background(Color.appBackground)
        } else {
            ContentUnavailableView("No reading schedule", systemImage: "calendar")
        }
    }

    private func header(selected: ReadingWeek, items: [FeedItem]) -> some View {
        // A chapter opening already says where the reader is, so its menu waits for a tap.
        let hidesMenu = chrome.isOnCover && chrome.hidesControls
        return ChapterMenu(
                library: library,
                items: items,
                navigation: navigation,
                weekOptions: .init(schedule: schedule, dates: selected.dateRangeText()) { selectedWeekID = $0 },
                isOnCover: chrome.isOnCover
            )
        .frame(maxWidth: .infinity)
        .frame(height: FeedInsets.header - 8)
        .opacity(hidesMenu ? 0 : 1)
        .allowsHitTesting(!hidesMenu)
        .accessibilityHidden(hidesMenu)
        .overlay(alignment: .trailing) {
            if !chrome.hidesControls {
                StreakBadge()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: chrome.hidesControls)
        .padding(.horizontal, Hardcover.margin - 12)
        .padding(.top, 8)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

#Preview {
    @Previewable @State var selectedWeekID: ReadingWeek.ID?
    WeeklyReadingView(library: try! ScriptureLibrary.loadBundled(), schedule: try! ReadingSchedule.loadBundled(), navigation: FeedNavigation(), selectedWeekID: $selectedWeekID)
        .environment(ReadingChrome())
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
