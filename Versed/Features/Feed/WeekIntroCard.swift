import SwiftUI

/// The first page of a week's reading: the dates, the lesson title, what's being read,
/// and a link to the week's official lesson.
struct WeekIntroCard: View {
    let week: ReadingWeek

    var body: some View {
        ShrinkToFit {
            VStack(spacing: 16) {
                VStack(spacing: 16) {
                    Text(week.dateRangeText.uppercased())
                        .font(.footnote.weight(.semibold))
                        .tracking(1.5)
                        .foregroundStyle(.tint)
                        // Read as "Oct 26 – Nov 1", not spelled out in capitals.
                        .accessibilityLabel(week.dateRangeText)

                    Text(week.title)
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))

                    Text(week.label)
                        .font(.title3)
                        .foregroundStyle(.secondaryText)
                }
                // VoiceOver reads the dates, title, and reading as one heading.
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                // Only a link: the lesson itself opens in Gospel Library if it's installed
                // (iOS hands churchofjesuschrist.org links to it), otherwise in Safari.
                Link(destination: week.lessonURL) {
                    Label("Open This Week's Lesson", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
                .accessibilityHint("Opens the lesson in Gospel Library or Safari.")
            }
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
