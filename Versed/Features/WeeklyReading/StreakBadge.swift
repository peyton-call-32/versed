import SwiftData
import SwiftUI

/// How many days in a row the reader has read, in small quiet text. Hidden until the first day.
struct StreakBadge: View {
    @Query private var readingDays: [ReadingDay]

    var body: some View {
        let streak = ReadingStreak.count(readDays: Set(readingDays.map(\.day)))
        if streak > 0 {
            Text(streak == 1 ? "1 day" : "\(streak) days")
                .font(.subheadline)
                .foregroundStyle(.secondaryText)
                .accessibilityLabel("\(streak)-day reading streak")
        }
    }
}
