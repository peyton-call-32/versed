import SwiftData
import SwiftUI

/// A plan's reading in the feed. Opens on the reading's opening card, and swiping up goes to where
/// the reader left off. Each page reached is saved as progress through the plan.
struct PlanReadingView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule
    let plan: ReadingPlan
    let openDetails: () -> Void
    let openWeek: (ReadingWeek.ID) -> Void
    let backToToday: () -> Void

    @Environment(\.modelContext) private var modelContext
    /// Stays put while it's being read, even as finishing it changes what the plan asks for next.
    @State private var reading: ReadingPortion?

    init(
        library: ScriptureLibrary,
        schedule: ReadingSchedule,
        plan: ReadingPlan,
        openDetails: @escaping () -> Void,
        openWeek: @escaping (ReadingWeek.ID) -> Void,
        backToToday: @escaping () -> Void
    ) {
        self.library = library
        self.schedule = schedule
        self.plan = plan
        self.openDetails = openDetails
        self.openWeek = openWeek
        self.backToToday = backToToday
        _reading = State(initialValue: PlanEngine(library: library, schedule: schedule).status(of: plan.state).nextToOpen)
    }

    private var engine: PlanEngine { PlanEngine(library: library, schedule: schedule) }

    var body: some View {
        if let reading {
            let store = ReadingPlanStore(context: modelContext, engine: engine)
            let closingID = FeedItem.closing(reading).id
            PagedReadingView(
                library: library,
                items: library.feedItems(for: reading),
                startingAt: ReadingPositionStore(context: modelContext).position(in: .plan(plan.id)),
                showsFirstPageOnResume: true,
                menuOptions: menuOptions(for: reading),
                closingActions: closingActions,
                onPageChange: { itemID in
                    store.recordPage(itemID, isClosingCard: itemID == closingID, in: reading, plan: plan)
                }
            )
            // A new identity per reading opens its feed on its own first page.
            .id(reading.id)
            .background(Color.appBackground)
        }
    }

    /// The way onward from the closing card. Reading ahead shows once this period's reading is done.
    private var closingActions: ReadingClosingCard.Actions {
        var actions = ReadingClosingCard.Actions(backToToday: backToToday)
        if engine.status(of: plan.state).readAhead != nil {
            actions.readAhead = { reading = engine.status(of: plan.state).readAhead }
        }
        return actions
    }

    private func menuOptions(for reading: ReadingPortion) -> ChapterMenu.Options {
        ChapterMenu.Options(
            spokenPlace: reading.heading,
            backToStartTitle: reading.weekID == nil ? "Back to Reading's Start" : "Back to Week's Start",
            otherWeeks: plan.state.source.isWeeklySchedule ? .init(schedule: schedule, open: openWeek) : nil,
            planDetails: openDetails
        )
    }
}
