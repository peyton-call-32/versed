import SwiftUI

/// The first page of a week's reading: "This Week", what's being read, and the dates.
/// The link to the week's lesson waits at the end of the reading, on `WeekEndCard`.
struct WeekIntroCard: View {
    let week: ReadingWeek

    /// "This Week" for the current week, and "Week Of" for any other week picked from the schedule.
    private var heading: String {
        week.contains(VersedApp.today) ? "This Week" : "Week Of"
    }

    var body: some View {
        ShrinkToFit {
            VStack(spacing: 16) {
                Text(heading.uppercased())
                    .font(.footnote.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.tint)

                Text(week.displayLabel)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))

                Text(week.dateRangeText())
                    .font(.title3)
                    .foregroundStyle(.secondaryText)
            }
            // VoiceOver reads "This Week, Daniel 1–7, Nov 9–15" as one heading.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(heading), \(week.label), \(week.dateRangeText())")
            .accessibilityAddTraits(.isHeader)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .padding(.top, FeedInsets.top)
        .padding(.bottom, FeedInsets.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let schedule = try! ReadingSchedule.loadBundled()
    WeekIntroCard(week: schedule.weeks[0])
}
