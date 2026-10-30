import SwiftData
import Testing
@testable import Versed

@MainActor
struct SavedVerseStoreTests {
    let container = try! ModelContainer(for: SavedVerse.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    var store: SavedVerseStore { SavedVerseStore(context: container.mainContext) }

    let verse = VerseID(bookID: "1-ne", chapter: 3, verse: 7)

    func savedCount() throws -> Int {
        try container.mainContext.fetchCount(FetchDescriptor<SavedVerse>())
    }

    @Test func savesAndRemovesAVerse() throws {
        #expect(!store.isSaved(verse))

        store.save(verse)
        #expect(store.isSaved(verse))

        store.unsave(verse)
        #expect(!store.isSaved(verse))
        #expect(try savedCount() == 0)
    }

    @Test func savingTwiceKeepsOneCopy() throws {
        store.save(verse)
        store.save(verse)
        #expect(try savedCount() == 1)
    }

    @Test func toggleFlipsBetweenSavedAndNot() {
        store.toggle(verse)
        #expect(store.isSaved(verse))
        store.toggle(verse)
        #expect(!store.isSaved(verse))
    }

    @Test func onlyTheMatchingVerseIsAffected() {
        let other = VerseID(bookID: "john", chapter: 3, verse: 16)
        store.save(verse)
        store.save(other)
        store.unsave(verse)
        #expect(store.isSaved(other))
    }
}
