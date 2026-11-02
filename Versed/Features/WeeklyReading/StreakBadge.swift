import SwiftData
import SwiftUI

/// A small flame showing how many days in a row the reader has read. Hidden until the first day.
struct StreakBadge: View {
    @Query private var readingDays: [ReadingDay]

    var body: some View {
        let streak = ReadingStreak.count(readDays: Set(readingDays.map(\.day)))
        if streak > 0 {
            Label {
                Text("\(streak)")
            } icon: {
                // Orange text is hard to read in light mode, so only the flame is orange.
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .pillBackground()
            .accessibilityLabel("\(streak)-day reading streak")
        }
    }
}
