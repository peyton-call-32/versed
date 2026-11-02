import SwiftUI

/// The first page of a week's reading: a small label with the dates, then the chapters.
/// The link to the week's lesson waits at the end of the reading, on `WeekEndCard`.
struct WeekIntroCard: View {
    let week: ReadingWeek

    private var isThisWeek: Bool {
        week.contains(VersedApp.today)
    }

    /// "This Week · Nov 2–8" for the current week, or just "Nov 9–15" for any other week.
    /// Shown in small capitals.
    private var label: String {
        isThisWeek ? "This Week · \(week.dateRangeText())" : week.dateRangeText()
    }

    var body: some View {
        ShrinkToFit {
            VStack(spacing: 14) {
                Text(label)
                    .font(.footnote.weight(.semibold))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(.tint)

                Text(week.displayLabel)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
            }
            // VoiceOver reads "This Week, Daniel 1–7, Nov 9–15" as one heading
            // ("Week Of, …" for other weeks), in normal case rather than capitals.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(isThisWeek ? "This Week" : "Week Of"), \(week.label), \(week.dateRangeText())")
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
