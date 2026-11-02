import SwiftUI

/// The last page of a week's reading, after the final verse: a quiet note that the reading
/// is done, and a link to the week's official lesson for anyone who wants to go further.
struct WeekEndCard: View {
    let week: ReadingWeek

    var body: some View {
        ShrinkToFit {
            VStack(spacing: 16) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 44))
                        .foregroundStyle(.tint)

                    Text("End of the Week's Reading")
                        .font(.system(.title, design: .serif, weight: .semibold))

                    Text(week.displayLabel)
                        .font(.title3)
                        .foregroundStyle(.secondaryText)
                }
                // VoiceOver reads "End of the Week's Reading, Daniel 1–7" as one heading.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("End of the Week's Reading, \(week.label)")
                .accessibilityAddTraits(.isHeader)

                // Only a link: the lesson itself opens in Gospel Library if it's installed
                // (iOS hands churchofjesuschrist.org links to it), otherwise in Safari.
                Link(destination: week.lessonURL) {
                    Label("Open This Week's Lesson", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.secondary)
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
    WeekEndCard(week: schedule.weeks[1])
}
