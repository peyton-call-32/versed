import SwiftData
import SwiftUI

/// A small flame showing how many days in a row the reader has read. Hidden until the first day.
struct StreakBadge: View {
    @Query private var readingDays: [ReadingDay]

    var body: some View {
        let streak = ReadingStreak.count(readDays: Set(readingDays.map(\.day)))
        if streak > 0 {
            Label("\(streak)", systemImage: "flame.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
                .accessibilityLabel("\(streak)-day reading streak")
        }
    }
}
