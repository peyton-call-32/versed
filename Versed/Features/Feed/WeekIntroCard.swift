import SwiftUI

/// The first page of a week's reading: a small label with the dates, each book with its
/// tappable chapter sections, and a line at the foot saying to swipe up. The link to the week's lesson waits on `WeekEndCard`.
struct WeekIntroCard: View {
    let week: ReadingWeek
    /// Whether the reader is partway through the week, so swiping up continues rather than starts.
    var isResuming = false
    /// Called when the reader taps a chapter section, with the chapter it starts on.
    var onSelectSection: (ChapterID) -> Void = { _ in }

    @Environment(\.screenInsets) private var screenInsets
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isThisWeek: Bool {
        week.contains(VersedApp.today)
    }

    /// "This Week · Nov 2–8" for the current week, or just "Nov 9–15" for any other week.
    private var label: String {
        isThisWeek ? "This Week · \(week.dateRangeText())" : week.dateRangeText()
    }

    private var books: [BookReading] { week.readingByBook }

    private var swipeGoal: String {
        isResuming ? "continue reading" : "start reading"
    }

    /// One short book name gets the big title; longer names and several books need more room.
    private var titleSize: CGFloat {
        books.count == 1 && books[0].name.count <= 9 ? 72 : 50
    }

    var body: some View {
        ShrinkToFit {
            VStack(spacing: 20) {
                SmallCapsLabel(label)
                    // VoiceOver reads "This Week, Daniel 1–7, Nov 9–15" as one heading
                    // ("Week Of, …" for other weeks), in normal case rather than capitals.
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(isThisWeek ? "This Week" : "Week Of"), \(week.label), \(week.dateRangeText())")
                    .accessibilityAddTraits(.isHeader)
                reading

            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Hardcover.margin + 8)
        .padding(.top, FeedInsets.top)
        .padding(.bottom, FeedInsets.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pageDepth(drift: reduceMotion ? 0 : 0.14, fade: 1.6)
        // The way forward always sits in the same place, just above the tab bar.
        .overlay(alignment: .bottom) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondaryText)
                    .gentleBob(isActive: true)
                    .accessibilityHidden(true)
                SmallCapsLabel("Swipe up to \(swipeGoal)")
                    // With VoiceOver on, moving the page takes three fingers.
                    .accessibilityLabel("Swipe up with three fingers to \(swipeGoal)")
                    .accessibilityIdentifier("Swipe up to \(swipeGoal)")
            }
            .padding(.bottom, screenInsets.bottom + VersedTabBar.height + 28)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
    }

    /// One book sits right above its chapters. Several books sit close together as one
    /// group, so they read as one week's reading.
    @ViewBuilder
    private var reading: some View {
        if books.count == 1 {
            book(at: 0)
        } else {
            VStack(spacing: 16) {
                ForEach(books.indices, id: \.self) { index in
                    book(at: index)
                }
            }
        }
    }

    /// A book's name with its chapter sections close beneath it, so they read as one thing.
    private func book(at index: Int) -> some View {
        VStack(spacing: 2) {
            title(books[index].name)
            if !books[index].chapters.isEmpty {
                sections(of: index)
            }
        }
    }

    private func title(_ name: String) -> some View {
        Text(name)
            .font(.versedTitle(size: titleSize))
            .foregroundStyle(.brand)
            // A long name like "Lamentations" shrinks rather than breaking in the middle.
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            // VoiceOver already reads each book in the heading and its sections.
            .accessibilityHidden(true)
    }

    /// The book's chapter sections on one line. At large text sizes or on narrow phones, the
    /// text steps down only as far as it takes to keep them all on that line.
    private func sections(of index: Int) -> some View {
        ViewThatFits(in: .horizontal) {
            sectionRow(of: index)
            ForEach(Self.smallerTextSizes, id: \.self) { size in
                sectionRow(of: index).dynamicTypeSize(...size)
            }
        }
    }

    /// Text sizes to try after the reader's own, largest first.
    private static var smallerTextSizes: [DynamicTypeSize] {
        [.accessibility3, .accessibility1, .xxxLarge, .xLarge, .large, .small, .xSmall]
    }

    /// Underlined words that each jump to where their section starts.
    private func sectionRow(of index: Int) -> some View {
        HStack(spacing: 18) {
            ForEach(Array(week.sectionsByBook[index].enumerated()), id: \.offset) { _, section in
                Button(section.title) {
                    onSelectSection(section.start)
                }
                .buttonStyle(.underlinedLink)
                .font(.versedTitle(size: 25, relativeTo: .title3))
                .lineLimit(1)
                .fixedSize()
                .accessibilityLabel("\(books[index].name) \(section.title.replacingOccurrences(of: "\u{2060}", with: ""))")
                .accessibilityHint("Jumps to this reading.")
            }
        }
    }
}

#Preview {
    let schedule = try! ReadingSchedule.loadBundled()
    WeekIntroCard(week: schedule.weeks[1])
}
