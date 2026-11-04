import Foundation
import SwiftData

/// Remembers the last page read in each feed. Each feed keeps one position.
///
/// Changes are written to the phone right away, so the place isn't lost if the app is closed.
@MainActor
struct ReadingPositionStore {
    let context: ModelContext

    /// The page last read in `feed`, or `nil` if it hasn't been read yet.
    func position(in feed: ReadingFeed) -> FeedItem.ID? {
        record(for: feed)?.itemID
    }

    func setPosition(_ itemID: FeedItem.ID, in feed: ReadingFeed) {
        if let existing = record(for: feed) {
            // Just reopening a feed on its saved page isn't reading, so it keeps its old date.
            // Browse's book covers rely on that to open on the book last read.
            guard existing.itemID != itemID else { return }
            existing.itemID = itemID
            existing.updatedAt = .now
        } else {
            context.insert(ReadingPosition(feed: feed, itemID: itemID))
        }
        try? context.save()
    }

    /// Forgets the place in `feed`, so it opens at the start next time.
    func clearPosition(in feed: ReadingFeed) {
        guard let existing = record(for: feed) else { return }
        context.delete(existing)
        try? context.save()
    }

    private func record(for feed: ReadingFeed) -> ReadingPosition? {
        let key = feed.key
        var descriptor = FetchDescriptor<ReadingPosition>(predicate: #Predicate { $0.feed == key })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
