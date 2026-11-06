import SwiftUI

/// The last page of a reading, after the final verse: a quiet note that the reading is done,
/// a link to the week's official lesson when there is one, and the way onward.
struct ReadingClosingCard: View {
    /// The ways onward from a plan's reading. A week opened from the schedule has none.
    struct Actions {
        var backToToday: (() -> Void)? = nil
        var readAhead: (() -> Void)? = nil
    }

    let reading: ReadingPortion
    /// Whether this page is the one on screen. Reaching it draws the check mark.
    var isCurrent = true
    var actions = Actions()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var spokenTitle: String {
        reading.closingTitle.replacingOccurrences(of: "’", with: "'")
    }

    var body: some View {
        ShrinkToFit {
            VStack(spacing: 18) {
                VStack(spacing: 18) {
                    FinishedMark(isDrawn: isCurrent)

                    Text(reading.closingTitle)
                        .font(.versedTitle(size: 42, relativeTo: .title))
                        .foregroundStyle(.brand)

                    Ornament()

                    Text(reading.displayLabel)
                        .font(.versedDetail)
                        .foregroundStyle(.secondaryText)
                }
                // VoiceOver reads "End of the Week's Reading, Daniel 1–7" as one heading.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(spokenTitle), \(reading.label)")
                .accessibilityAddTraits(.isHeader)

                VStack(spacing: 10) {
                    // Only a link: the lesson itself opens in Gospel Library if it's installed
                    // (iOS hands churchofjesuschrist.org links to it), otherwise in Safari.
                    if let lessonURL = reading.lessonURL {
                        Link(destination: lessonURL) {
                            HStack(spacing: 8) {
                                Text("Open This Week’s Lesson")
                                Image(systemName: "arrow.up.right")
                                    .imageScale(.small)
                                    .accessibilityHidden(true)
                            }
                        }
                        .buttonStyle(.primary)
                        .accessibilityLabel("Open This Week's Lesson")
                        .accessibilityIdentifier("Open This Week's Lesson")
                        .accessibilityHint("Opens the lesson in Gospel Library or Safari.")
                    }
                    if let readAhead = actions.readAhead {
                        Button("Read Ahead", action: readAhead)
                            .buttonStyle(.secondary)
                    }
                    if let backToToday = actions.backToToday {
                        if reading.lessonURL == nil && actions.readAhead == nil {
                            Button("Back to Today", action: backToToday)
                                .buttonStyle(.primary)
                        } else {
                            Button("Back to Today", action: backToToday)
                                .buttonStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 14)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Hardcover.margin + 8)
        .padding(.top, FeedInsets.top)
        .padding(.bottom, FeedInsets.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pageDepth(drift: reduceMotion ? 0 : 0.14, fade: 1.6)
        .sensoryFeedback(trigger: isCurrent) { _, reached in reached ? .success : nil }
    }
}

/// A thin circle and check mark that draw themselves when the reader finishes the reading.
private struct FinishedMark: View {
    let isDrawn: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let progress: CGFloat = isDrawn || reduceMotion ? 1 : 0
        ZStack {
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.brand.opacity(0.5), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.7), value: isDrawn)
            CheckMark()
                .trim(from: 0, to: progress)
                .stroke(Color.brand, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                .frame(width: 24, height: 18)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.35).delay(0.45), value: isDrawn)
        }
        .frame(width: 62, height: 62)
        .accessibilityHidden(true)
    }
}

private struct CheckMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width * 0.36, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

#Preview {
    let schedule = try! ReadingSchedule.loadBundled()
    ReadingClosingCard(reading: ReadingPortion(week: schedule.weeks[1]))
}
