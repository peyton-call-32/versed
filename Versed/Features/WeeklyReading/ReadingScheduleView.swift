import SwiftUI

/// Every week in the schedule, with its dates and chapters, grouped by year's course.
/// The current week is highlighted, and the list opens scrolled to it.
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
            List {
                ForEach(courses, id: \.name) { course in
                    Section {
                        ForEach(course.weeks) { week in
                            row(for: week, isThisWeek: week.id == thisWeekID)
                                .id(week.id)
                        }
                    } header: {
                        SectionHeader(course.name)
                    }
                }
            }
            .versedListStyle()
            .navigationTitle("Reading Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let thisWeekID {
                    proxy.scrollTo(thisWeekID, anchor: .center)
                }
            }
        }
    }

    private func row(for week: ReadingWeek, isThisWeek: Bool) -> some View {
        Button {
            // This week opens as "this week", so it keeps following the calendar.
            openWeek(isThisWeek ? nil : week.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if isThisWeek {
                        Text("THIS WEEK")
                            .font(.caption.weight(.semibold))
                            .tracking(1)
                            .foregroundStyle(.tint)
                    }
                    Text(week.dateRangeText())
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text(week.displayLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondaryText)
                }
                Spacer(minLength: 8)
                DisclosureChevron()
            }
            .padding(.vertical, 2)
        }
        .listRowBackground(isThisWeek ? Color.brand.opacity(0.1) : Color.cardBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isThisWeek ? "This week, " : "")\(week.dateRangeText()), \(week.label)")
        .accessibilityAddTraits(isThisWeek ? .isSelected : [])
        .accessibilityHint("Opens the reading.")
    }
}

#Preview {
    NavigationStack {
        ReadingScheduleView(schedule: try! ReadingSchedule.loadBundled(), openWeek: { _ in })
    }
}
