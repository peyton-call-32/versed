import SwiftData
import SwiftUI

/// The words at the top right of This Week: a flame and how many days in a row the reader has
/// read. It opens the streak calendar, so it stays visible even with no streak going.
struct StreakBadge: View {
    @Query private var readingDays: [ReadingDay]

    @State private var showsCalendar = false
    @Environment(ReadingChrome.self) private var chrome

    private var readDays: Set<String> { Set(readingDays.map(\.day)) }

    var body: some View {
        let streak = ReadingStreak.count(readDays: readDays)
        Button {
            showsCalendar = true
        } label: {
            HStack(spacing: 4) {
                FlameMark()
                    .stroke(lineWidth: 1)
                    .frame(width: 11, height: 15)
                if streak > 0 {
                    Text("\(streak)")
                        .font(.versedDetail)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                }
            }
            .foregroundStyle(chrome.isOnCover ? Color.onCover : Color.brand)
            .padding(.horizontal, 12)
            .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .layoutPriority(1)
        .accessibilityLabel(streak > 0 ? "\(streak)-day reading streak" : "Reading streak")
        .accessibilityHint("Shows your reading calendar.")
        .accessibilityIdentifier("Streak")
        .sheet(isPresented: $showsCalendar) {
            StreakCalendarView(readDays: readDays)
                .versedSheet()
        }
    }
}

/// A plain flame, drawn as one clean line so it stays crisp at the small sizes it's used.
struct FlameMark: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        var path = Path()
        path.move(to: point(0.56, 0))
        path.addCurve(to: point(0.96, 0.66), control1: point(0.62, 0.24), control2: point(0.96, 0.38))
        path.addCurve(to: point(0.5, 1), control1: point(0.96, 0.87), control2: point(0.75, 1))
        path.addCurve(to: point(0.04, 0.64), control1: point(0.25, 1), control2: point(0.04, 0.86))
        path.addCurve(to: point(0.2, 0.28), control1: point(0.04, 0.49), control2: point(0.12, 0.39))
        path.addCurve(to: point(0.36, 0.5), control1: point(0.21, 0.39), control2: point(0.28, 0.47))
        path.addCurve(to: point(0.56, 0), control1: point(0.33, 0.3), control2: point(0.4, 0.13))
        path.closeSubpath()
        return path
    }
}
