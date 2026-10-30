import SwiftUI

/// The first page of a week's reading: the dates, the lesson title, and what's being read.
struct WeekIntroCard: View {
    let week: ReadingWeek

    var body: some View {
        VStack(spacing: 16) {
            Text(week.dateRangeText.uppercased())
                .font(.footnote.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(.tint)

            Text(week.title)
                .font(.system(.largeTitle, design: .serif, weight: .semibold))

            Text(week.label)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let schedule = try! ReadingSchedule.loadBundled()
    WeekIntroCard(week: schedule.weeks[0])
}
