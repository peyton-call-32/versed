import Foundation
import SwiftData

/// Saves and removes saved verses. Each verse is saved at most once.
@MainActor
struct SavedVerseStore {
    let context: ModelContext

    func isSaved(_ id: VerseID) -> Bool {
        !records(for: id).isEmpty
    }

    func save(_ id: VerseID) {
        guard !isSaved(id) else { return }
        context.insert(SavedVerse(verseID: id))
    }

    func unsave(_ id: VerseID) {
        records(for: id).forEach(context.delete)
    }

    func toggle(_ id: VerseID) {
        isSaved(id) ? unsave(id) : save(id)
    }

    private func records(for id: VerseID) -> [SavedVerse] {
        let rawValue = id.rawValue
        let descriptor = FetchDescriptor<SavedVerse>(predicate: #Predicate { $0.verseID == rawValue })
        return (try? context.fetch(descriptor)) ?? []
    }
}
