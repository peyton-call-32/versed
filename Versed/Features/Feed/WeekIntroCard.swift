import SwiftUI

/// The first page of a week's reading: a small label with the dates, each book with its
/// tappable chapter sections, and a line saying to swipe up. The link to the week's lesson waits on `WeekEndCard`.
struct WeekIntroCard: View {
    let week: ReadingWeek
    /// Whether the reader is partway through the week, so swiping up continues rather than starts.
    var isResuming = false
    /// Called when the reader taps a chapter section, with the chapter it starts on.
    var onSelectSection: (ChapterID) -> Void = { _ in }

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
        books.count == 1 && books[0].name.count <= 9 ? 66 : 44
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

                HStack(spacing: 8) {
                    Image(systemName: "arrow.up")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondaryText)
                        .accessibilityHidden(true)
                    SmallCapsLabel("Swipe up to \(swipeGoal)")
                        // With VoiceOver on, moving the page takes three fingers.
                        .accessibilityLabel("Swipe up with three fingers to \(swipeGoal)")
                        .accessibilityIdentifier("Swipe up to \(swipeGoal)")
                }
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
                sections(of: 0)
            }
        } else {
            VStack(spacing: 16) {
                ForEach(Array(books.enumerated()), id: \.offset) { index, book in
                    VStack(spacing: 8) {
                        title(book.name)
                        if !book.chapters.isEmpty {
                            sections(of: index)
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
            // VoiceOver already reads each book in the heading and its sections.
            .accessibilityHidden(true)
    }

    /// The book's chapter sections as soft pills, each jumping to where that section starts.
    private func sections(of index: Int) -> some View {
        SectionRows {
            ForEach(Array(week.sectionsByBook[index].enumerated()), id: \.offset) { position, section in
                if position > 0 {
                    Rectangle()
                        .fill(Color.brand)
                        .accessibilityHidden(true)
                }
                Button(section.title) {
                    onSelectSection(section.start)
                }
                .buttonStyle(.tintedPill)
                .font(.versedTitle(size: 32, relativeTo: .title2))
                .accessibilityLabel("\(books[index].name) \(section.title.replacingOccurrences(of: "\u{2060}", with: ""))")
                .accessibilityHint("Jumps to this reading.")
            }
        }
    }
}

/// Lays out a book's section pills and the thin vertical lines between them, which take turns as
/// subviews: pill, line, pill. Rows are centered and wrap when they run out of room, and a line
/// that would land at a row's edge is hidden, so lines only ever sit between two pills.
private struct SectionRows: Layout {
    private static let lineWidth: CGFloat = 1.5
    private static let gap: CGFloat = 9
    private static let rowSpacing: CGFloat = 10

    private struct Row {
        var pills: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// Fills rows up to `width`, then narrows it for as long as that takes no extra rows, so
    /// wrapped rows come out even ("1–3 | 33–34" over "36–37 | 47") with no pill left alone.
    private func rows(fitting width: CGFloat, in subviews: Subviews) -> [Row] {
        var best = filledRows(fitting: width, in: subviews)
        while best.count > 1 {
            let widest = best.map(\.width).max() ?? 0
            let narrower = filledRows(fitting: widest - 1, in: subviews)
            // Stop when it needs another row, or can't get any narrower (one pill per row).
            guard narrower.count == best.count, (narrower.map(\.width).max() ?? 0) < widest else { break }
            best = narrower
        }
        return best
    }

    private func filledRows(fitting width: CGFloat, in subviews: Subviews) -> [Row] {
        let separation = Self.lineWidth + Self.gap * 2
        var rows: [Row] = []
        for index in stride(from: 0, to: subviews.count, by: 2) {
            let size = subviews[index].sizeThatFits(.unspecified)
            if let last = rows.last, last.width + separation + size.width <= width {
                rows[rows.count - 1].pills.append(index)
                rows[rows.count - 1].width += separation + size.width
                rows[rows.count - 1].height = max(last.height, size.height)
            } else {
                rows.append(Row(pills: [index], width: size.width, height: size.height))
            }
        }
        return rows
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(fitting: proposal.width ?? .infinity, in: subviews)
        return CGSize(
            width: rows.map(\.width).max() ?? 0,
            height: rows.map(\.height).reduce(0, +) + Self.rowSpacing * CGFloat(max(rows.count - 1, 0))
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        // Every line starts hidden; the ones between two pills are placed again below.
        for index in stride(from: 1, to: subviews.count, by: 2) {
            subviews[index].place(at: bounds.origin, proposal: .zero)
        }

        var y = bounds.minY
        for row in rows(fitting: bounds.width, in: subviews) {
            var x = bounds.midX - row.width / 2
            for pill in row.pills {
                if pill != row.pills[0] {
                    x += Self.gap
                    subviews[pill - 1].place(
                        at: CGPoint(x: x, y: y + row.height / 2),
                        anchor: .leading,
                        proposal: ProposedViewSize(width: Self.lineWidth, height: row.height * 0.55)
                    )
                    x += Self.lineWidth + Self.gap
                }
                let size = subviews[pill].sizeThatFits(.unspecified)
                subviews[pill].place(
                    at: CGPoint(x: x, y: y + row.height / 2),
                    anchor: .leading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width
            }
            y += row.height + Self.rowSpacing
        }
    }
}

#Preview {
    let schedule = try! ReadingSchedule.loadBundled()
    WeekIntroCard(week: schedule.weeks[1])
}
