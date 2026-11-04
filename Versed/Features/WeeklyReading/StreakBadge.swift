import SwiftData
import SwiftUI

/// The pill at the top right of This Week: a flame and how many days in a row the reader has
/// read. It opens the streak calendar, so it stays visible even with no streak going.
struct StreakBadge: View {
    @Query private var readingDays: [ReadingDay]

    @State private var showsCalendar = false

    private var readDays: Set<String> { Set(readingDays.map(\.day)) }

    var body: some View {
        let streak = ReadingStreak.count(readDays: readDays)
        Button {
            showsCalendar = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .imageScale(.small)
                if streak > 0 {
                    Text(streak == 1 ? "1 day" : "\(streak) days")
                        .lineLimit(1)
                }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.brand)
            .padding(.horizontal, streak > 0 ? 15 : 0)
            .frame(minWidth: 44, minHeight: 44)
            .pillBackground()
        }
        .buttonStyle(.plain)
        .layoutPriority(1)
        .accessibilityLabel(streak > 0 ? "\(streak)-day reading streak" : "Reading streak")
        .accessibilityHint("Shows your reading calendar.")
        .accessibilityIdentifier("Streak")
        .sheet(isPresented: $showsCalendar) {
            StreakCalendarView(readDays: readDays)
        }
    }
}
