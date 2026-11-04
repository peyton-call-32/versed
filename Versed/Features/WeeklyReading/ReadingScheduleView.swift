import SwiftUI

/// Every week in the schedule, with its dates and chapters, grouped by year's course.
/// The current week is a solid navy row, and the list opens scrolled to it.
/// Tapping a week opens its reading on the This Week tab.
struct ReadingScheduleView: View {
    let schedule: ReadingSchedule
    /// Shows a week on the This Week tab: `nil` for this week, or any week from the schedule.
    let openWeek: (ReadingWeek.ID?) -> Void

    private var thisWeekID: ReadingWeek.ID? { schedule.currentWeek()?.id }

    /// The weeks split by course, in order, such as "Old Testament 2026" then "New Testament 2027".
    private var courses: [(name: String, weeks: [ReadingWeek])] {
        schedule.weeks.reduce(into: []) { courses, week in
            if courses.last?.name == week.course {
                courses[courses.count - 1].weeks.append(week)
            } else {
                courses.append((week.course, [week]))
            }
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 22) {
                    ForEach(courses, id: \.name) { course in
                        CardSection(title: course.name) {
                            ForEach(course.weeks) { week in
                                if week.id != course.weeks.first?.id {
                                    CardDivider()
                                }
                                WeekRow(week: week, isThisWeek: week.id == thisWeekID) {
                                    // This week opens as "this week", so it keeps following the calendar.
                                    openWeek(week.id == thisWeekID ? nil : week.id)
                                }
                                .id(week.id)
                            }
                        }
                    }
                }
                .versedPage()
            }
            .background(Color.appBackground)
            .navigationTitle("Reading Schedule")
            .onAppear {
                if let thisWeekID {
                    proxy.scrollTo(thisWeekID, anchor: .center)
                }
            }
        }
    }
}

/// One week: its dates in a column on the left and its chapters beside them.
/// At the largest text sizes, the chapters move under the dates.
private struct WeekRow: View {
    let week: ReadingWeek
    let isThisWeek: Bool
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    /// Wide enough that "Nov 30 – Dec 6" stays on one line.
    @ScaledMetric(relativeTo: .footnote) private var dateWidth = 100.0

    private var layout: AnyLayout {
        typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
    }

    var body: some View {
        Button(action: action) {
            layout {
                Text(week.dateRangeText())
                    .font(.footnote)
                    .foregroundStyle(isThisWeek ? Color("ProminentButtonLabel") : .secondaryText)
                    .frame(width: typeSize.isAccessibilitySize ? nil : dateWidth, alignment: .leading)
                Text(week.displayLabel)
                    .font(.subheadline.weight(isThisWeek ? .semibold : .regular))
                    .foregroundStyle(isThisWeek ? Color("ProminentButtonLabel") : .brand)
                    .multilineTextAlignment(.leading)
            }
            .cardRowPadding()
            .contentShape(Rectangle())
            .background(isThisWeek ? Color("ProminentButton") : .clear)
        }
        .buttonStyle(.cardRow)
        .accessibilityAddTraits(isThisWeek ? .isSelected : [])
        .accessibilityLabel("\(isThisWeek ? "This week, " : "")\(week.dateRangeText()), \(week.label)")
        .accessibilityHint("Opens the reading.")
    }
}

#Preview {
    NavigationStack {
        ReadingScheduleView(schedule: try! ReadingSchedule.loadBundled(), openWeek: { _ in })
    }
}
