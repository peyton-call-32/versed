import SwiftData
import Testing
@testable import Versed

@MainActor
struct ReadingPositionStoreTests {
    let container = try! ModelContainer(for: ReadingPosition.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    var store: ReadingPositionStore { ReadingPositionStore(context: container.mainContext) }

    @Test func aNewFeedHasNoPosition() {
        #expect(store.position(in: .browse) == nil)
    }

    @Test func remembersTheLastPage() throws {
        store.setPosition("verse:alma.32.21", in: .browse)
        store.setPosition("verse:alma.32.22", in: .browse)

        #expect(store.position(in: .browse) == "verse:alma.32.22")
        #expect(try container.mainContext.fetchCount(FetchDescriptor<ReadingPosition>()) == 1)
    }

    @Test func eachFeedKeepsItsOwnPosition() {
        store.setPosition("verse:dan.1.8", in: .week("2026-10-26"))
        store.setPosition("verse:dan.8.1", in: .week("2026-11-02"))
        store.setPosition("verse:john.3.16", in: .browse)

        #expect(store.position(in: .week("2026-10-26")) == "verse:dan.1.8")
        #expect(store.position(in: .week("2026-11-02")) == "verse:dan.8.1")
        #expect(store.position(in: .browse) == "verse:john.3.16")
    }
}
