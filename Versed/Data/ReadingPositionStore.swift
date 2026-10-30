import Foundation
import SwiftData

/// Remembers the last page read in each feed. Each feed keeps one position.
@MainActor
struct ReadingPositionStore {
    let context: ModelContext

    /// The page last read in `feed`, or `nil` if it hasn't been read yet.
    func position(in feed: ReadingFeed) -> FeedItem.ID? {
        record(for: feed)?.itemID
    }

    func setPosition(_ itemID: FeedItem.ID, in feed: ReadingFeed) {
        if let existing = record(for: feed) {
            existing.itemID = itemID
            existing.updatedAt = .now
        } else {
            context.insert(ReadingPosition(feed: feed, itemID: itemID))
        }
    }

    private func record(for feed: ReadingFeed) -> ReadingPosition? {
        let key = feed.key
        var descriptor = FetchDescriptor<ReadingPosition>(predicate: #Predicate { $0.feed == key })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
