import SwiftUI

/// The first page of a week's reading: a small label with the dates, each book with its
/// chapters, and a button to start. The link to the week's lesson waits on `WeekEndCard`.
struct WeekIntroCard: View {
    let week: ReadingWeek
    /// "Start Reading", or "Continue Reading" when the reader is partway through the week.
    let startTitle: String
    let onStart: () -> Void

    private var isThisWeek: Bool {
        week.contains(VersedApp.today)
    }

    /// "This Week · Nov 2–8" for the current week, or just "Nov 9–15" for any other week.
    private var label: String {
        isThisWeek ? "This Week · \(week.dateRangeText())" : week.dateRangeText()
    }

    private var books: [BookReading] { week.readingByBook }

    /// One short book name gets the big title; longer names and several books need more room.
    private var titleSize: CGFloat {
        books.count == 1 && books[0].name.count <= 9 ? 66 : 44
    }

    var body: some View {
        ShrinkToFit {
            VStack(spacing: 20) {
                VStack(spacing: 20) {
                    SmallCapsLabel(label)
                    reading
                }
                // VoiceOver reads "This Week, Daniel 1–7, Nov 9–15" as one heading
                // ("Week Of, …" for other weeks), in normal case rather than capitals.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(isThisWeek ? "This Week" : "Week Of"), \(week.label), \(week.dateRangeText())")
                .accessibilityAddTraits(.isHeader)

                Button(startTitle, action: onStart)
                    .buttonStyle(.primary)
                    .padding(.top, 14)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .padding(.top, FeedInsets.top)
        .padding(.bottom, FeedInsets.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// One book has the line between its name and chapters. Several books sit close together
    /// as one group, with the line under the group, so they read as one week's reading.
    @ViewBuilder
    private var reading: some View {
        if books.count == 1 {
            title(books[0].name)
            if !books[0].chapters.isEmpty {
                Ornament()
                chapters(books[0].chapters)
            }
        } else {
            VStack(spacing: 16) {
                ForEach(Array(books.enumerated()), id: \.offset) { _, book in
                    VStack(spacing: 4) {
                        title(book.name)
                        if !book.chapters.isEmpty {
                            chapters(book.chapters)
                        }
                    }
                }
            }
            Ornament()
        }
    }

    private func title(_ name: String) -> some View {
        Text(name)
            .font(.versedTitle(size: titleSize))
            .foregroundStyle(.brand)
    }

    /// "1–3 · 33–34 · 36–37 · 47". The no-break space keeps each dot on the same line as the
    /// chapters before it, so a line never starts with one.
    private func chapters(_ sections: [String]) -> some View {
        Text(sections.joined(separator: "\u{00A0}· "))
            .font(.versedNumber(size: 26, relativeTo: .title2))
            .lineSpacing(4)
            .foregroundStyle(.brand)
    }
}

#Preview {
    let schedule = try! ReadingSchedule.loadBundled()
    WeekIntroCard(week: schedule.weeks[1], startTitle: "Start Reading") {}
}
