import Foundation
import SwiftData
import Testing
@testable import Versed

struct PlanPacerTests {
    @Test func sharesEvenChaptersEvenly() {
        let chunks = PlanPacer.chunks(weights: Array(repeating: 10, count: 9), lengths: [1, 1, 1])
        #expect(chunks == [0..<3, 3..<6, 6..<9])
    }

    @Test func aLongChapterCountsForMore() {
        let chunks = PlanPacer.chunks(weights: [100, 10, 10, 10, 10, 10, 10], lengths: [1, 1])
        #expect(chunks == [0..<1, 1..<7])
    }

    @Test func readsAtLeastOneChapter() {
        #expect(PlanPacer.nextCount(weights: [500, 500], lengths: [1, 1, 1, 1, 1, 1]) == 1)
    }

    @Test func aShortFirstWeekGetsASmallerShare() {
        let chunks = PlanPacer.chunks(weights: Array(repeating: 10, count: 8), lengths: [1, 7])
        #expect(chunks == [0..<1, 1..<8])
    }

    @Test func runsOutEarlyWithFewerChaptersThanDays() {
        #expect(PlanPacer.chunks(weights: [10, 10], lengths: [1, 1, 1, 1, 1]).count == 2)
    }

    @Test func coversEveryChapterOnceInOrder() {
        let weights = (1...50).map { 10 + $0 % 17 }
        let chunks = PlanPacer.chunks(weights: weights, lengths: Array(repeating: 1, count: 9))
        #expect(chunks.first?.lowerBound == 0)
        #expect(chunks.last?.upperBound == 50)
        for (one, next) in zip(chunks, chunks.dropFirst()) {
            #expect(one.upperBound == next.lowerBound)
        }
    }
}

struct PlanCalendarTests {
    private let calendar = Calendar(identifier: .gregorian)
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date { calendar.date(from: DateComponents(year: y, month: m, day: d))! }

    @Test func weeksRunMondayToSunday() {
        let dates = PlanCalendar(calendar: calendar)
        #expect(dates.monday(of: date(2026, 11, 5)) == date(2026, 11, 2))
        #expect(dates.monday(of: date(2026, 11, 8)) == date(2026, 11, 2), "Sunday belongs to the week before it")
        #expect(dates.monday(of: date(2026, 11, 9)) == date(2026, 11, 9))
    }

    @Test func aMidweekStartMakesAShortFirstWeek() {
        // Thursday Nov 5 through Sunday Nov 22.
        let periods = PlanCalendar(calendar: calendar).periods(from: date(2026, 11, 5), through: date(2026, 11, 22), pace: .week)
        #expect(periods.map(\.length) == [4, 7, 7])
    }

    @Test func countsEveryDay() {
        let periods = PlanCalendar(calendar: calendar).periods(from: date(2026, 11, 5), through: date(2026, 11, 7), pace: .day)
        #expect(periods.map(\.length) == [1, 1, 1])
    }
}

@MainActor
struct PlanEngineTests {
    private static let library = try! ScriptureLibrary.loadBundled()
    private static let schedule = try! ReadingSchedule.loadBundled()
    private let calendar = Calendar.current
    private var engine: PlanEngine { PlanEngine(library: Self.library, schedule: Self.schedule) }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    private func bookPlan(_ source: PlanSource, pace: PlanPace = .day, start: Date, finish: Date) -> PlanState {
        engine.newPlan(source: source, pace: pace, finish: finish, today: start)
    }

    /// Reads a reading through to its closing card.
    private func finishing(_ state: PlanState, _ reading: ReadingPortion, today: Date) -> PlanState {
        engine.recordingProgress(state, page: FeedItem.closing(reading).id, isClosingCard: true, in: reading, today: today)
    }

    // MARK: Labels

    @Test func labelsReadLikeTheSchedule() {
        let units = [31, 32, 33, 36].map { Passage(bookID: "jer", chapters: $0...$0) } + [Passage(bookID: "lam", chapters: 1...1)]
        #expect(engine.label(for: units) == "Jeremiah 31–33; 36; Lamentations 1")
        #expect(engine.label(for: [Passage(bookID: "isa", chapters: 53...53, verses: 3...5)]) == "Isaiah 53:3–5")
        #expect(engine.label(for: [Passage(bookID: "dc", chapters: 76...76)]) == "D&C 76")
    }

    @Test func labelsSplitIntoBooksOnTheOpeningCard() throws {
        let start = date(2026, 11, 5)
        var state = bookPlan(.volume("bofm"), start: start, finish: date(2026, 11, 15))
        state.unitsRead = 20
        state.periodStart = 20
        let reading = try #require(engine.status(of: state, today: start).reading)
        #expect(reading.label.hasPrefix("1 Nephi 21"))
        #expect(reading.readingByBook.count >= 2, "\(reading.label) runs into 2 Nephi")
        #expect(reading.sectionsByBook[0].first?.start == ChapterID(bookID: "1-ne", chapter: 21))
    }

    // MARK: Plans with a finish date

    @Test func firstDayOfAPlan() throws {
        let start = date(2026, 11, 5)
        let state = bookPlan(.book("gen"), start: start, finish: date(2026, 12, 4))
        let status = engine.status(of: state, today: start)
        #expect(status.periodText == "Day 1 of 30")
        #expect(status.doneText == nil)
        let reading = try #require(status.reading)
        #expect(reading.label.hasPrefix("Genesis 1"))
        #expect(reading.firstUnit == 0)
    }

    @Test func finishingTodayShowsDoneAndOffersMore() throws {
        let start = date(2026, 11, 5)
        var state = bookPlan(.book("gen"), start: start, finish: date(2026, 12, 4))
        let reading = try #require(engine.status(of: state, today: start).reading)
        state = finishing(state, reading, today: start)

        let status = engine.status(of: state, today: start)
        #expect(status.doneText == "Done today")
        #expect(status.reading == reading, "Today's reading doesn't move once it's read")
        let ahead = try #require(status.readAhead)
        #expect(ahead.firstUnit == reading.passages.count)
        #expect(status.nextToOpen == ahead)
    }

    @Test func tomorrowMovesToTheNextReading() throws {
        let start = date(2026, 11, 5)
        var state = bookPlan(.book("gen"), start: start, finish: date(2026, 12, 4))
        let first = try #require(engine.status(of: state, today: start).reading)
        state = finishing(state, first, today: start)

        let status = engine.status(of: state, today: date(2026, 11, 6))
        #expect(status.periodText == "Day 2 of 30")
        #expect(status.doneText == nil)
        #expect(status.reading?.firstUnit == first.passages.count)
    }

    @Test func missedDaysSpreadAcrossTheDaysLeft() throws {
        let start = date(2026, 11, 5)
        let state = bookPlan(.book("gen"), start: start, finish: date(2026, 11, 14))
        let firstDay = try #require(engine.status(of: state, today: start).reading)

        // Nothing read for five days: half the days are gone, so each day left holds about twice as much.
        let status = engine.status(of: state, today: date(2026, 11, 10))
        let later = try #require(status.reading)
        #expect(later.firstUnit == 0, "Nothing is skipped")
        #expect(later.passages.count > firstDay.passages.count)
        #expect(status.doneText == nil)
    }

    @Test func pastTheFinishDateKeepsTheSamePace() throws {
        let start = date(2026, 11, 5)
        let state = bookPlan(.book("gen"), start: start, finish: date(2026, 11, 14))
        let firstDay = try #require(engine.status(of: state, today: start).reading)

        let status = engine.status(of: state, today: date(2027, 3, 1))
        let reading = try #require(status.reading)
        #expect(reading.passages.count <= firstDay.passages.count + 1, "It never asks for the whole book at once")
        #expect(status.periodText == "0% read")
    }

    @Test func readingWholeBookFinishesThePlan() throws {
        let start = date(2026, 11, 5)
        var state = bookPlan(.book("obad"), start: start, finish: date(2026, 12, 4))
        let reading = try #require(engine.status(of: state, today: start).reading)
        #expect(reading.closingTitle == ReadingPortion.endOfPlan)
        state = finishing(state, reading, today: start)
        let status = engine.status(of: state, today: start)
        #expect(status.isFinished)
        #expect(status.progress == 1)
    }

    @Test func reachingAChapterCountsTheOnesBeforeIt() throws {
        let start = date(2026, 11, 5)
        var state = bookPlan(.book("gen"), start: start, finish: date(2026, 11, 7))
        let reading = try #require(engine.status(of: state, today: start).reading)
        state = engine.recordingProgress(state, page: "verse:gen.3.2", isClosingCard: false, in: reading, today: start)
        #expect(state.unitsRead == 2)
        state = engine.recordingProgress(state, page: "verse:gen.1.1", isClosingCard: false, in: reading, today: start)
        #expect(state.unitsRead == 2, "Going back doesn't undo progress")
    }

    @Test func aWeeklyPaceSharesByWeek() {
        // Thursday Nov 5 through Sunday Nov 29: 4 weeks, the first a short one.
        let start = date(2026, 11, 5)
        let state = bookPlan(.book("gen"), pace: .week, start: start, finish: date(2026, 11, 29))
        let status = engine.status(of: state, today: start)
        #expect(status.periodText == "Week 1 of 4")
        let next = engine.status(of: state, today: date(2026, 11, 9))
        #expect(next.periodText == "Week 2 of 4")
        let firstCount = status.reading?.passages.count ?? 0
        #expect(firstCount < 50 / 4, "The short first week holds less than an even share")
    }

    @Test func upcomingListsWhatComesNext() {
        let start = date(2026, 11, 5)
        let state = bookPlan(.book("gen"), start: start, finish: date(2026, 12, 4))
        let upcoming = engine.upcoming(for: state, limit: 3, today: start)
        #expect(upcoming.count == 3)
        #expect(upcoming[0].when == "Nov 6")
    }

    // MARK: Following the calendar

    @Test func followingTheCalendarByWeek() throws {
        let today = date(2026, 10, 28)
        var state = engine.newPlan(source: .weeklySchedule(course: nil), pace: .week, finish: nil, today: today)
        let status = engine.status(of: state, today: today)
        let reading = try #require(status.reading)
        #expect(reading.label == "Jeremiah 31–33; 36–39; Lamentations 1; 3")
        #expect(reading.heading == "This Week · Oct 26 – Nov 1")
        #expect(reading.lessonURL != nil)
        #expect(status.periodText == "Oct 26 – Nov 1")

        state = finishing(state, reading, today: today)
        #expect(engine.status(of: state, today: today).doneText == "Done this week")

        // The next Monday brings the next week, fresh.
        let next = engine.status(of: state, today: date(2026, 11, 2))
        #expect(next.reading?.label == "Ezekiel 1–3; 33–34; 36–37; 47")
        #expect(next.doneText == nil)
    }

    @Test func followingTheCalendarSectionsStillJump() throws {
        let today = date(2026, 10, 28)
        let state = engine.newPlan(source: .weeklySchedule(course: nil), pace: .week, finish: nil, today: today)
        let reading = try #require(engine.status(of: state, today: today).reading)
        #expect(reading.sectionsByBook[0].map(\.start.chapter) == [31, 36])
        #expect(reading.sectionsByBook[1].map(\.start.chapter) == [1, 3])
    }

    @Test func aFeedLeftOpenPastSundayDoesNotCountTowardTheNewWeek() throws {
        let today = date(2026, 10, 28)
        let state = engine.newPlan(source: .weeklySchedule(course: nil), pace: .week, finish: nil, today: today)
        let reading = try #require(engine.status(of: state, today: today).reading)
        let later = finishing(state, reading, today: date(2026, 11, 2))
        #expect(later.unitsRead == 0)
    }

    @Test func followingTheCalendarByDaySplitsTheWeek() throws {
        // Monday of a week with 9 chapters.
        let monday = date(2026, 10, 26)
        var state = engine.newPlan(source: .weeklySchedule(course: nil), pace: .day, finish: nil, today: monday)
        let status = engine.status(of: state, today: monday)
        #expect(status.periodText == "Day 1 of 7")
        let reading = try #require(status.reading)
        #expect(reading.passages.count < 9)
        #expect(reading.closingTitle == ReadingPortion.endOfDay)

        state = finishing(state, reading, today: monday)
        #expect(engine.status(of: state, today: monday).doneText == "Done today")
        #expect(engine.status(of: state, today: monday).readAhead != nil)
        #expect(engine.status(of: state, today: date(2026, 10, 27)).periodText == "Day 2 of 7")
    }

    @Test func aScatteredWeekKeepsItsNameWhenSplit() throws {
        let monday = date(2026, 12, 21)
        let state = engine.newPlan(source: .weeklySchedule(course: nil), pace: .day, finish: nil, today: monday)
        #expect(engine.status(of: state, today: monday).reading?.label == "Christmas")
    }

    // MARK: A course at the reader's own pace

    @Test func startingOverBeginsAtWeekOne() throws {
        let today = date(2026, 11, 5)
        let state = engine.newPlan(source: .weeklySchedule(course: "Old Testament 2026"), pace: .week, finish: nil, today: today)
        let status = engine.status(of: state, today: today)
        #expect(status.periodText == "Week 1 of 52")
        #expect(status.reading?.label == "Introduction")
    }

    @Test func aWeekWaitsUntilItsFinished() throws {
        let today = date(2026, 11, 5)
        var state = engine.newPlan(source: .weeklySchedule(course: "Old Testament 2026"), pace: .week, finish: nil, today: today)
        let first = try #require(engine.status(of: state, today: today).reading)

        // A month later it's still week 1, with nothing about being late.
        #expect(engine.status(of: state, today: date(2026, 12, 7)).periodText == "Week 1 of 52")

        state = finishing(state, first, today: today)
        let done = engine.status(of: state, today: today)
        #expect(done.doneText == "Done this week")
        #expect(done.readAhead?.label == "Moses 1; Abraham 3")

        // The next Monday moves on.
        #expect(engine.status(of: state, today: date(2026, 11, 9)).periodText == "Week 2 of 52")
    }

    @Test func ownPaceByDayKeepsTheWeeksOrder() throws {
        let today = date(2026, 11, 5)
        let state = engine.newPlan(source: .weeklySchedule(course: "New Testament 2027"), pace: .day, finish: nil, today: today)
        let status = engine.status(of: state, today: today)
        #expect(status.periodText == "Week 1, Day 1")
        #expect(engine.upcoming(for: state, limit: 2, today: today).count == 2)
    }

    // MARK: Previews

    @Test func previewsSayHowMuchAndUntilWhen() {
        let today = date(2026, 11, 5)
        let preview = engine.preview(source: .volume("bofm"), pace: .day, finish: date(2026, 12, 31), today: today)
        // 239 chapters over 57 days.
        #expect(preview.summary == "About 4 chapters a day.")
        #expect(preview.finish == "Finishes Dec 31.")

        let weekly = engine.preview(source: .volume("bofm"), pace: .week, finish: date(2026, 12, 31), today: today)
        #expect(weekly.summary.hasSuffix("chapters a week."))
    }

    @Test func aShortBookFinishesEarly() {
        let today = date(2026, 11, 5)
        let preview = engine.preview(source: .book("ruth"), pace: .day, finish: date(2026, 12, 4), today: today)
        #expect(preview.summary == "About 1 chapter a day.")
        #expect(preview.finish == "Finishes Nov 8.")
    }

    @Test func theDoctrineAndCovenantsCountsSections() {
        let today = date(2026, 11, 5)
        let preview = engine.preview(source: .volume("dc"), pace: .day, finish: date(2027, 1, 13), today: today)
        #expect(preview.summary.hasSuffix("sections a day."))
    }

    // MARK: Saving

    private func store() throws -> ReadingPlanStore {
        let container = try ModelContainer(for: ReadingPlan.self, ReadingPosition.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ReadingPlanStore(context: ModelContext(container), engine: engine)
    }

    @Test func savesAPlanAndItsProgress() throws {
        let store = try store()
        let start = VersedApp.today
        let finish = calendar.date(byAdding: .day, value: 29, to: start)
        let plan = store.start(source: .book("gen"), pace: .day, finish: finish)
        #expect(store.plan(for: .book("gen"))?.id == plan.id)
        #expect(store.plan(for: .book("ex")) == nil)

        let reading = try #require(engine.status(of: plan.state).reading)
        store.recordPage("verse:gen.1.3", isClosingCard: false, in: reading, plan: plan)
        #expect(ReadingPositionStore(context: store.context).position(in: .plan(plan.id)) == "verse:gen.1.3")

        store.recordPage(FeedItem.closing(reading).id, isClosingCard: true, in: reading, plan: plan)
        #expect(ReadingPositionStore(context: store.context).position(in: .plan(plan.id)) == nil)
        #expect(plan.unitsRead == reading.passages.count)
    }

    @Test func changingThePaceKeepsThePlace() throws {
        let store = try store()
        let plan = store.start(source: .book("gen"), pace: .day, finish: calendar.date(byAdding: .day, value: 29, to: VersedApp.today))
        plan.unitsRead = 7
        store.setPace(.week, of: plan)
        #expect(plan.unitsRead == 7)
        #expect(plan.state.pace == .week)
        #expect(engine.status(of: plan.state).reading?.firstUnit == 7)
    }

    @Test func removingAPlanForgetsItsPlace() throws {
        let store = try store()
        let plan = store.start(source: .book("gen"), pace: .day, finish: VersedApp.today)
        let id = plan.id
        ReadingPositionStore(context: store.context).setPosition("verse:gen.1.1", in: .plan(id))
        store.remove(plan)
        #expect(store.plan(for: .book("gen")) == nil)
        #expect(ReadingPositionStore(context: store.context).position(in: .plan(id)) == nil)
    }

    @Test func earlierWeeklyReadersKeepReading() throws {
        let store = try store()
        let today = date(2026, 10, 28)
        ReadingPositionStore(context: store.context).setPosition("verse:jer.31.3", in: .week("2026-10-26"))

        store.adoptEarlierWeeklyReading(today: today)
        let plan = try #require(store.plan(for: .weeklySchedule(course: nil)))
        #expect(ReadingPositionStore(context: store.context).position(in: .plan(plan.id)) == "verse:jer.31.3")

        // It only happens once.
        store.adoptEarlierWeeklyReading(today: today)
        #expect(try store.context.fetchCount(FetchDescriptor<ReadingPlan>()) == 1)
    }

    @Test func newReadersGetNoPlanOnTheirOwn() throws {
        let store = try store()
        store.adoptEarlierWeeklyReading()
        #expect(try store.context.fetchCount(FetchDescriptor<ReadingPlan>()) == 0)
    }
}
