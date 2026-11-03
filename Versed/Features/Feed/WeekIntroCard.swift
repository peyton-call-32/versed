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
                    .font(.callout.weight(.semibold))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(.tint)

                // Each book on its own: the name, then its chapter sections in the same light
                // navy serif as the chapter card's number. More space between books than within
                // one, so each name and its chapters read as a group.
                VStack(spacing: 24) {
                    ForEach(Array(week.readingByBook.enumerated()), id: \.offset) { _, book in
                        VStack(spacing: 10) {
                            Text(book.name)
                                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                                .foregroundStyle(.brand)
                            if !book.chapters.isEmpty {
                                ChapterSections(sections: book.chapters)
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

/// A book's chapter sections, such as "1–3 ◆ 33–34 ◆ 36–37 ◆ 47", with a small diamond
/// between each so they're easy to tell apart. When they don't fit on one line (at large
/// text sizes), each section gets its own line instead.
private struct ChapterSections: View {
    let sections: [String]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                    if index > 0 { OrnamentDiamond() }
                    sectionText(section)
                }
            }
            VStack(spacing: 4) {
                ForEach(sections, id: \.self) { sectionText($0) }
            }
        }
    }

    private func sectionText(_ section: String) -> some View {
        Text(section)
            .font(.system(.title, design: .serif, weight: .light))
            .monospacedDigit()
            .foregroundStyle(.brand)
            .fixedSize()
    }
}

#Preview {
    let schedule = try! ReadingSchedule.loadBundled()
    WeekIntroCard(week: schedule.weeks[0])
}
