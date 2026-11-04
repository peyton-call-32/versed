import SwiftData
import SwiftUI

/// Opens to this week's reading. A header row sits on top: a menu to pick another week on the
/// left, and the streak on the right.
///
/// Each week opens on its opening card. Swiping up goes to the page where the reader left off,
/// or to the start once the week has been read to its closing card.
struct WeeklyReadingView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule

    @Environment(\.modelContext) private var modelContext

    /// The week picked from the menu or the schedule in Browse, or `nil` to show this week.
    @Binding var selectedWeekID: ReadingWeek.ID?

    private var thisWeek: ReadingWeek? { schedule.currentWeek() }

    private var selectedWeek: ReadingWeek? {
        schedule.weeks.first { $0.id == selectedWeekID } ?? thisWeek
    }

    var body: some View {
        if let week = selectedWeek {
            let positions = ReadingPositionStore(context: modelContext)
            FeedView(
                items: [.weekIntro(week)] + library.feedItems(for: week.passages) + [.weekEnd(week)],
                startingAt: positions.position(in: .week(week.id)),
                showsFirstPageOnResume: true,
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
                header(selected: week)
            }
        } else {
            ContentUnavailableView("No reading schedule", systemImage: "calendar")
        }
    }

    private func header(selected: ReadingWeek) -> some View {
        HStack {
            weekMenu(selected: selected)
            Spacer(minLength: 8)
            StreakBadge()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func weekMenu(selected: ReadingWeek) -> some View {
        Menu {
            ForEach(schedule.weeks) { week in
                Button {
                    selectedWeekID = week.id
                } label: {
                    let dates = week.id == thisWeek?.id ? "\(week.dateRangeText()) · This week" : week.dateRangeText()
                    if week.id == selected.id {
                        Label(dates, systemImage: "checkmark")
                    } else {
                        Text(dates)
                    }
                    Text(week.displayLabel)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selected.dateRangeText())
                Image(systemName: "chevron.down")
                    .imageScale(.small)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.brand)
            .padding(.horizontal, 15)
            .frame(minHeight: 44)
            .pillBackground()
        }
        .accessibilityLabel("Week of \(selected.dateRangeText())")
        .accessibilityHint("Picks another week's reading.")
    }
}

#Preview {
    @Previewable @State var selectedWeekID: ReadingWeek.ID?
    WeeklyReadingView(library: try! ScriptureLibrary.loadBundled(), schedule: try! ReadingSchedule.loadBundled(), selectedWeekID: $selectedWeekID)
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
