import Foundation
import SwiftData

/// Saves study plans on the phone. Changes are written right away.
@MainActor
struct ReadingPlanStore {
    let context: ModelContext
    let engine: PlanEngine

    @discardableResult
    func start(source: PlanSource, pace: PlanPace, finish: Date?, today: Date = VersedApp.today) -> ReadingPlan {
        let plan = ReadingPlan(state: engine.newPlan(source: source, pace: pace, finish: finish, today: today))
        context.insert(plan)
        try? context.save()
        return plan
    }

    func plan(for source: PlanSource) -> ReadingPlan? {
        let key = source.key
        var descriptor = FetchDescriptor<ReadingPlan>(predicate: #Predicate { $0.sourceKey == key })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// Saves that the reader reached a page, and remembers their place.
    func recordPage(_ itemID: FeedItem.ID, isClosingCard: Bool, in reading: ReadingPortion, plan: ReadingPlan) {
        plan.state = engine.recordingProgress(plan.state, page: itemID, isClosingCard: isClosingCard, in: reading)
        let positions = ReadingPositionStore(context: context)
        if isClosingCard {
            positions.clearPosition(in: .plan(plan.id))
        } else {
            positions.setPosition(itemID, in: .plan(plan.id))
        }
        try? context.save()
    }

    /// Changes between reading by day and by week, keeping the reader's place.
    func setPace(_ pace: PlanPace, of plan: ReadingPlan, today: Date = VersedApp.today) {
        var state = plan.state
        guard state.pace != pace else { return }
        state.pace = pace
        state.periodKey = engine.dates.periodKey(for: today, pace: pace)
        state.periodStart = state.unitsRead
        plan.state = state
        try? context.save()
    }

    func setFinish(_ finish: Date, of plan: ReadingPlan, today: Date = VersedApp.today) {
        var state = plan.state
        state.finishDay = ReadingDay.key(for: finish, calendar: engine.dates.calendar)
        state.periodKey = engine.dates.periodKey(for: today, pace: state.pace)
        state.periodStart = state.unitsRead
        plan.state = state
        try? context.save()
    }

    /// Removes a plan and its place. Saved verses and the streak stay.
    func remove(_ plan: ReadingPlan) {
        ReadingPositionStore(context: context).clearPosition(in: .plan(plan.id))
        context.delete(plan)
        try? context.save()
    }

    /// Someone who read the weekly schedule before plans existed keeps reading it, in the same place.
    func adoptEarlierWeeklyReading(today: Date = VersedApp.today) {
        guard ((try? context.fetchCount(FetchDescriptor<ReadingPlan>())) ?? 0) == 0 else { return }
        let positions = (try? context.fetch(FetchDescriptor<ReadingPosition>())) ?? []
        guard positions.contains(where: { $0.feed.hasPrefix("week:") }) else { return }

        let plan = start(source: .weeklySchedule(course: nil), pace: .week, finish: nil, today: today)
        if let weekID = plan.trackedWeekID,
           let place = positions.first(where: { $0.feed == ReadingFeed.week(weekID).key }) {
            ReadingPositionStore(context: context).setPosition(place.itemID, in: .plan(plan.id))
        }
    }
}
