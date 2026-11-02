import SwiftUI

/// The first page of a week's reading: a small label with the dates, then each book and its chapters.
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
            VStack(spacing: 18) {
                Text(label)
                    .font(.footnote.weight(.semibold))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(.tint)

                // Each book on its own: the name, then its chapters in a smaller, lighter line.
                // More space between books than within one, so each pair reads as a group.
                VStack(spacing: 18) {
                    ForEach(Array(week.readingByBook.enumerated()), id: \.offset) { _, book in
                        VStack(spacing: 4) {
                            Text(book.name)
                                .font(.system(.title, design: .serif, weight: .semibold))
                            if !book.chapters.isEmpty {
                                Text(book.chapters.joined(separator: " · "))
                                    .font(.title3)
                                    .foregroundStyle(.secondaryText)
                            }
                        }
                    }
                }
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
