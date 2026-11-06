import SwiftData
import SwiftUI

/// The Versed "V" from the app's icon, set in the page's ink. Decoration only: VoiceOver skips it.
struct VersedMark: View {
    var body: some View {
        MarkShape()
            .fill(.brand)
            .frame(width: 30, height: 29)
            .accessibilityHidden(true)
    }

    private struct MarkShape: Shape {
        func path(in rect: CGRect) -> Path {
            // Traced from the icon, in the icon's own 1024-point drawing.
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: rect.minX + (x - 250) / 522 * rect.width, y: rect.minY + (y - 262) / 500 * rect.height)
            }
            var path = Path()
            path.move(to: point(255, 265))
            path.addLine(to: point(528, 265))
            path.addCurve(to: point(505, 365), control1: point(490, 272), control2: point(484, 295))
            path.addLine(to: point(595, 668))
            path.addLine(to: point(684, 350))
            path.addCurve(to: point(652, 265), control1: point(697, 305), control2: point(692, 275))
            path.addLine(to: point(767, 265))
            path.addCurve(to: point(695, 360), control1: point(730, 275), control2: point(715, 300))
            path.addLine(to: point(567, 759))
            path.addLine(to: point(450, 759))
            path.addLine(to: point(320, 360))
            path.addCurve(to: point(255, 265), control1: point(300, 300), control2: point(290, 275))
            path.closeSubpath()
            return path
        }
    }
}

/// A ribbon bookmark hanging from the top of the page, holding how many days in a row the reader
/// has read. It opens the calendar of days read, so it stays even with no streak going.
struct StreakRibbon: View {
    static let width: CGFloat = 60
    static let height: CGFloat = 128

    @Query private var readingDays: [ReadingDay]
    @State private var showsCalendar = false

    private var readDays: Set<String> { Set(readingDays.map(\.day)) }

    var body: some View {
        let streak = ReadingStreak.count(readDays: readDays)
        Button {
            showsCalendar = true
        } label: {
            VStack(spacing: 3) {
                if streak > 0 {
                    Text("\(streak)")
                        .font(.custom(Font.Bundled.number, fixedSize: streak > 999 ? 28 : 38))
                        .contentTransition(.numericText())
                    Text(streak == 1 ? "day in\na row" : "days in\na row")
                        .font(.custom(Font.Bundled.verse, fixedSize: 12))
                        .lineSpacing(-1)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "diamond")
                        .font(.system(size: 9, weight: .light))
                        .padding(.top, 14)
                }
            }
            .foregroundStyle(.onCover)
            .padding(.top, 14)
            .frame(width: Self.width, height: Self.height, alignment: .top)
            .background(Swallowtail().fill(.cover))
            .contentShape(Swallowtail())
        }
        .buttonStyle(RibbonButtonStyle())
        .accessibilityLabel(streak > 0 ? "\(streak)-day reading streak" : "Reading streak")
        .accessibilityHint("Shows your reading calendar.")
        .accessibilityIdentifier("Streak")
        .sheet(isPresented: $showsCalendar) {
            StreakCalendarView(readDays: readDays)
                .versedSheet()
        }
    }

    /// A ribbon's cut end: straight sides with a notch out of the bottom.
    private struct Swallowtail: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: rect.origin)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 15))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }

    /// A gentle tug: the ribbon stretches down under the finger, held at the top where it hangs.
    private struct RibbonButtonStyle: ButtonStyle {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(y: configuration.isPressed && !reduceMotion ? 1.05 : 1, anchor: .top)
                .animation(.spring(duration: 0.3, bounce: 0.3), value: configuration.isPressed)
        }
    }
}

/// Opens its content downward. Its height follows `progress`, so everything below moves in step,
/// on every frame of the animation, with nothing jumping at the start or the end.
struct RevealLayout: Layout {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let content = subviews.first else { return .zero }
        let full = content.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
        return CGSize(width: proposal.width ?? full.width, height: full.height * progress)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(width: bounds.width, height: nil))
    }
}
