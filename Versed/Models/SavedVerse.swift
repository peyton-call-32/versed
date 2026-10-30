import Foundation
import SwiftData

/// A verse the reader saved, stored on the phone.
///
/// Only the verse's permanent ID is stored, never a copy of its text, so saved verses
/// can later be shared with a group just by sending IDs.
@Model
final class SavedVerse {
    /// The verse's `VerseID.rawValue`, such as "1-ne.3.7".
    var verseID: String
    var savedAt: Date

    init(verseID: VerseID, savedAt: Date = .now) {
        self.verseID = verseID.rawValue
        self.savedAt = savedAt
    }

    var verse: VerseID? { VerseID(rawValue: verseID) }
}
