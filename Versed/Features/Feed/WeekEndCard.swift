import SwiftUI

/// The last page of a week's reading, after the final verse: a quiet note that the reading
/// is done, and a link to the week's official lesson for anyone who wants to go further.
struct WeekEndCard: View {
    let week: ReadingWeek
    /// Whether this page is the one on screen. Reaching it draws the check mark.
    var isCurrent = true

    var body: some View {
        ShrinkToFit {
            VStack(spacing: 18) {
                VStack(spacing: 18) {
                    FinishedMark(isDrawn: isCurrent)

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
        .sensoryFeedback(trigger: isCurrent) { _, reached in reached ? .success : nil }
    }
}

/// A thin circle and check mark that draw themselves when the reader finishes the week.
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
    WeekEndCard(week: schedule.weeks[1])
}
