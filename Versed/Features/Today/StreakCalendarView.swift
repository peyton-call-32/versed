import SwiftUI

/// The reader's streak: the current count, a month calendar of the days they read, and two totals.
/// Past months are reachable back to the first day they read.
struct StreakCalendarView: View {
    let readDays: Set<String>

    @Environment(\.dismiss) private var dismiss
    @State private var month = ReadingMonth(containing: .now)
    /// Grows with the reader's text size, to stay in step with the big number beside it.
    @ScaledMetric(relativeTo: .largeTitle) private var flameSize = 38.0

    private var streak: Int { ReadingStreak.count(readDays: readDays) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    streakHeading
                    Ornament()
                    MonthCalendar(month: $month, readDays: readDays)
                    HStack(spacing: 0) {
                        StreakStat(title: "Best Streak", value: ReadingStreak.best(readDays: readDays))
                        Rectangle().fill(Color.hairline).frame(width: 1).padding(.vertical, 10).accessibilityHidden(true)
                        StreakStat(title: "Days Read", value: readDays.count)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .versedPage()
            }
            .versedScreen()
            .navigationTitle("Your Streak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DoneToolbarItem { dismiss() }
            }
        }
    }

    @ViewBuilder private var streakHeading: some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                FlameMark()
                    .stroke(lineWidth: 1)
                    .frame(width: flameSize * 0.72, height: flameSize)
                if streak > 0 {
                    Text("\(streak)")
                        .font(.versedNumber(size: 84))
                }
            }
            Text(streak > 0 ? "day streak" : "Read a verse to start a streak")
                .font(.versedTitle(size: 23, relativeTo: .title3))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.brand)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(streak > 0 ? "\(streak)-day reading streak" : "Read a verse to start a streak")
    }
}

/// A month with arrows to move between months. Days in a row join into one solid band.
private struct MonthCalendar: View {
    @Binding var month: ReadingMonth
    let readDays: Set<String>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let currentMonth = ReadingMonth(containing: .now)

    /// Stops at the month of the first reading, or this month if there's been none yet.
    private var earliestMonth: ReadingMonth {
        readDays.min().flatMap { ReadingDay.date(forKey: $0) }.map { ReadingMonth(containing: $0) } ?? currentMonth
    }

    var body: some View {
        Ledger {
            VStack(spacing: 8) {
                monthHeader
                // Seven columns need a limit: past this, two-digit days wouldn't fit across the phone.
                Group {
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(Array(month.weekdayLetters.enumerated()), id: \.offset) { _, letter in
                            Text(letter)
                                .font(.versedVerse(size: 12, relativeTo: .caption))
                                .foregroundStyle(.secondaryText)
                                .accessibilityHidden(true)
                        }
                    }
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(0..<month.leadingBlanks, id: \.self) { _ in
                            Color.clear.accessibilityHidden(true)
                        }
                        ForEach(month.days(readDays: readDays)) { day in
                            CalendarDayCell(day: day)
                        }
                    }
                }
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            }
            .padding(.vertical, 8)
        }
    }

    private var monthHeader: some View {
        HStack {
            arrow("chevron.backward", label: "Previous month", isEnabled: month.start > earliestMonth.start) {
                month = month.adding(months: -1)
            }
            Spacer(minLength: 4)
            Text(month.title)
                .font(.versedTitle(size: 21, relativeTo: .headline))
                .foregroundStyle(.brand)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 4)
            arrow("chevron.forward", label: "Next month", isEnabled: month.start < currentMonth.start) {
                month = month.adding(months: 1)
            }
        }
    }

    private func arrow(_ symbol: String, label: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(.brand)
                .opacity(isEnabled ? 1 : 0.25)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

/// One day: plain if unread, navy if read, with a short line under today.
private struct CalendarDayCell: View {
    let day: ReadingMonth.Day

    /// Grows with the reader's text size so bigger numbers still fit inside the band.
    @ScaledMetric(relativeTo: .subheadline) private var height = 34.0

    private var numberColor: Color {
        if day.isRead { return Color("ProminentButtonLabel") }
        return day.isToday ? .brand : .secondaryText
    }

    var body: some View {
        Text("\(day.number)")
            .font(.versedDetail)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(numberColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background {
                if day.isRead { band }
            }
            .overlay(alignment: .bottom) {
                // A short line under today's number.
                if day.isToday {
                    Rectangle()
                        .fill(numberColor)
                        .frame(width: 14, height: 1)
                        .padding(.bottom, 5)
                }
            }
            // The row is taller than the band, which leaves a small gap between weeks.
            .frame(minHeight: 44)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
            .accessibilityAddTraits(.isStaticText)
    }

    private var band: some View {
        let round = Hardcover.cornerRadius
        return UnevenRoundedRectangle(
            topLeadingRadius: day.joinsPrevious ? 0 : round,
            bottomLeadingRadius: day.joinsPrevious ? 0 : round,
            bottomTrailingRadius: day.joinsNext ? 0 : round,
            topTrailingRadius: day.joinsNext ? 0 : round
        )
        .fill(Color("ProminentButton"))
        // A slight overlap, so no hairline shows where two days meet.
        .padding(.leading, day.joinsPrevious ? -0.5 : 0)
        .padding(.trailing, day.joinsNext ? -0.5 : 0)
    }

    private var accessibilityText: String {
        let date = day.date.formatted(.dateTime.month(.wide).day())
        let name = day.isToday ? "Today, \(date)" : date
        return day.isRead ? "\(name), read" : name
    }
}

/// A number with a small label under it.
private struct StreakStat: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.versedNumber(size: 38, relativeTo: .title))
                .foregroundStyle(.brand)
            SmallCapsLabel(title)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(value)")
    }
}

#Preview {
    StreakCalendarView(readDays: ["2026-11-01", "2026-11-02", "2026-11-03", "2026-11-04"])
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
