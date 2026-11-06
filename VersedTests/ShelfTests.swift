import Testing
@testable import Versed

struct ShelfTests {
    @Test func newReadersStartWithTheTwoTestaments() {
        #expect(Shelf.volumeIDs(from: Shelf.starting) == ["ot", "nt"])
    }

    @Test func addingABookKeepsTheCanonicalOrder() {
        #expect(Shelf.toggling("bofm", in: "ot,pgp") == "ot,bofm,pgp")
    }

    @Test func removingEveryBookLeavesAnEmptyShelf() {
        #expect(Shelf.toggling("ot", in: "ot") == "")
        #expect(Shelf.volumeIDs(from: "").isEmpty)
    }

    /// Removing the name from Today was a deliberate decision, but the words themselves must stay.
    @Test func weeklyPlanSaysTheAppIsIndependent() {
        #expect(WeeklyPlanName.title == "Come, Follow Me")
        #expect(WeeklyPlanName.notice == "Versed is an independent app, not made or endorsed by The Church of Jesus Christ of Latter-day Saints.")
    }

    @Test func searchFindsBooksAndChapters() throws {
        let library = try ScriptureLibrary.loadBundled()
        #expect(library.search("alma 32").first?.title == "Alma 32")
        #expect(library.search("alma").first?.title == "Alma")
        #expect(library.search("psalms 999").isEmpty)
        #expect(library.search("  ").isEmpty)
    }

    @Test func readingTimeCountsWhatsLeft() throws {
        let engine = PlanEngine(library: try ScriptureLibrary.loadBundled(), schedule: try ReadingSchedule.loadBundled())
        let start = VersedApp.today
        var state = engine.newPlan(source: .weeklySchedule(course: nil), pace: .week, finish: nil, today: start)
        let full = try #require(engine.readingTime(of: state, today: start))
        #expect(!full.hasStarted)
        #expect(full.text.hasPrefix("About"))
        state.unitsRead = 1
        let partway = try #require(engine.readingTime(of: state, today: start))
        #expect(partway.hasStarted)
        #expect(partway.minutes < full.minutes)
        #expect(partway.text.hasSuffix("left"))
    }
}
