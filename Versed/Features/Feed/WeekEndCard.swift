import SwiftUI

/// The last page of a week's reading, after the final verse: a quiet note that the reading
/// is done, and a link to the week's official lesson for anyone who wants to go further.
struct WeekEndCard: View {
    let week: ReadingWeek

    var body: some View {
        ShrinkToFit {
            VStack(spacing: 18) {
                VStack(spacing: 18) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(.brand)

                    Text("End of the Week’s Reading")
                        .font(.versedTitle(size: 42, relativeTo: .title))
                        .foregroundStyle(.brand)

                    Ornament()

                    Text(week.displayLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondaryText)
                }
                // VoiceOver reads "End of the Week's Reading, Daniel 1–7" as one heading.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("End of the Week's Reading, \(week.label)")
                .accessibilityAddTraits(.isHeader)

                // Only a link: the lesson itself opens in Gospel Library if it's installed
                // (iOS hands churchofjesuschrist.org links to it), otherwise in Safari.
                Link(destination: week.lessonURL) {
                    HStack(spacing: 8) {
                        Text("Open This Week’s Lesson")
                        Image(systemName: "arrow.up.right")
                            .imageScale(.small)
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(.primary)
                .padding(.top, 14)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .accessibilityLabel("Open This Week's Lesson")
                .accessibilityIdentifier("Open This Week's Lesson")
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
