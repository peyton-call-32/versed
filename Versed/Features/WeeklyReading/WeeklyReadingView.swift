import SwiftData
import SwiftUI

/// Opens to this week's Come, Follow Me reading, with a menu at the top to pick another week.
/// Each week reopens on the page where the reader left off.
struct WeeklyReadingView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The week picked from the menu, or `nil` to show this week.
    @State private var selectedWeekID: ReadingWeek.ID?

    private var thisWeek: ReadingWeek? { schedule.currentWeek() }

    private var selectedWeek: ReadingWeek? {
        schedule.weeks.first { $0.id == selectedWeekID } ?? thisWeek
    }

    var body: some View {
        if let week = selectedWeek {
            let positions = ReadingPositionStore(context: modelContext)
            FeedView(
                items: [.weekIntro(week)] + library.feedItems(for: week.passages),
                startingAt: positions.position(in: .week(week.id)),
                onPageChange: { positions.setPosition($0, in: .week(week.id)) }
            )
            // A new identity per week reopens each week's feed at its own saved page.
            .id(week.id)
            .overlay(alignment: .top) {
                topBar(selected: week)
            }
        } else {
            ContentUnavailableView("No reading schedule", systemImage: "calendar")
        }
    }

    /// The week menu, centered, with the streak badge on the right. At accessibility text sizes
    /// the menu is too wide to center beside the badge, so it moves to the left.
    private func topBar(selected: ReadingWeek) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                HStack(alignment: .top) {
                    weekMenu(selected: selected)
                    Spacer(minLength: 8)
                    StreakBadge()
                }
            } else {
                weekMenu(selected: selected)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .topTrailing) { StreakBadge() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func weekMenu(selected: ReadingWeek) -> some View {
        Menu {
            ForEach(schedule.weeks) { week in
                Button {
                    selectedWeekID = week.id
                } label: {
                    let dates = week.id == thisWeek?.id ? "\(week.dateRangeText) · This week" : week.dateRangeText
                    if week.id == selected.id {
                        Label(dates, systemImage: "checkmark")
                    } else {
                        Text(dates)
                    }
                    Text(week.title)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(selected.dateRangeText)
                Image(systemName: "chevron.down")
                    .imageScale(.small)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
        }
        .accessibilityLabel("Week of \(selected.dateRangeText)")
        .accessibilityHint("Picks another week's reading.")
    }
}

#Preview {
    WeeklyReadingView(library: try! ScriptureLibrary.loadBundled(), schedule: try! ReadingSchedule.loadBundled())
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
