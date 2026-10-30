import Foundation
import SwiftData

/// The page the reader was last on in one feed, stored on the phone so reading picks up where it left off.
@Model
final class ReadingPosition {
    /// The `ReadingFeed.key` this position belongs to, such as "week:2026-10-26".
    var feed: String
    /// The `FeedItem.ID` of the page, such as "verse:1-ne.3.7".
    var itemID: String
    var updatedAt: Date

    init(feed: ReadingFeed, itemID: FeedItem.ID, updatedAt: Date = .now) {
        self.feed = feed.key
        self.itemID = itemID
        self.updatedAt = updatedAt
    }
}

/// A feed whose place is remembered separately from the others.
enum ReadingFeed: Hashable, Sendable {
    /// One week of the reading schedule.
    case week(ReadingWeek.ID)
    /// Reading from the Browse or Saved tab.
    case browse

    var key: String {
        switch self {
        case .week(let id): "week:\(id)"
        case .browse: "browse"
        }
    }
}
