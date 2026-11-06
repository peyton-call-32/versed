import SwiftData
import SwiftUI

/// The first tab: every study plan with what to read next. Tapping one opens its reading.
/// With no plans yet, it asks what the reader would like to read.
struct TodayView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule
    /// Goes to Browse, for choosing another book.
    let openBrowse: () -> Void
    @Binding var path: [Route]

    @Query(sort: \ReadingPlan.createdAt) private var plans: [ReadingPlan]
    @State private var setupSource: PlanSource?
    @Environment(\.scenePhase) private var scenePhase

    /// The screens this tab can open.
    enum Route: Hashable {
        case reading(String)
        case details(String)
        case week(ReadingWeek.ID)
        case schedule
    }

    private var engine: PlanEngine { PlanEngine(library: library, schedule: schedule) }

    var body: some View {
        // Reading the phase redraws the plans when the app comes back on a new day.
        let _ = scenePhase
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 22) {
                    if plans.isEmpty {
                        emptyState
                    } else {
                        planList
                    }
                }
                .versedPage()
            }
            .scrollBounceBehavior(.basedOnSize)
            .versedScreen()
            .navigationTitle("Today")
            .navigationDestination(for: Route.self, destination: destination)
            .toolbar {
                PlainToolbarItem(placement: .topBarTrailing) {
                    StreakBadge()
                        .padding(.trailing, Hardcover.margin - 28)
                }
            }
            .sheet(item: $setupSource) { source in
                PlanSetupView(engine: engine, source: source) { _ in }
                    .versedSheet()
            }
        }
    }

    private var planList: some View {
        let engine = engine
        return VStack(alignment: .leading, spacing: 18) {
            Ledger {
                ForEach(plans) { plan in
                    if plan.id != plans.first?.id { LedgerRule() }
                    let status = engine.status(of: plan.state)
                    PlanRow(
                        title: engine.title(of: plan.state.source),
                        status: status,
                        onOpen: { path.append(status.isFinished ? .details(plan.id) : .reading(plan.id)) },
                        onDetails: { path.append(.details(plan.id)) }
                    )
                }
            }
            Ledger {
                Button(action: openBrowse) {
                    LedgerRowLabel(title: "Add a Plan")
                }
                .buttonStyle(.ledgerRow)
            }
            if plans.contains(where: { $0.state.source.isWeeklySchedule }) {
                Text(WeeklyCover.notice)
                    .font(.versedNote)
                    .foregroundStyle(.secondaryText)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("What would you like to read?")
                .font(.versedTitle(size: 30, relativeTo: .title))
                .foregroundStyle(.brand)
                .accessibilityAddTraits(.isHeader)
            Ledger {
                Button {
                    setupSource = .weeklySchedule(course: nil)
                } label: {
                    LedgerRowLabel(title: WeeklyCover.title, detail: "Weekly schedule")
                }
                .buttonStyle(.ledgerRow)
                LedgerRule()
                Button {
                    setupSource = .volume("bofm")
                } label: {
                    LedgerRowLabel(title: "Book of Mormon", detail: "At your pace")
                }
                .buttonStyle(.ledgerRow)
                LedgerRule()
                Button(action: openBrowse) {
                    LedgerRowLabel(title: "Choose Something Else")
                }
                .buttonStyle(.ledgerRow)
            }
            Text(WeeklyCover.notice)
                .font(.versedNote)
                .foregroundStyle(.secondaryText)
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .reading(let id):
            if let plan = plans.first(where: { $0.id == id }) {
                PlanReadingView(
                    library: library,
                    schedule: schedule,
                    plan: plan,
                    openDetails: { path.append(.details(id)) },
                    openWeek: { path.append(.week($0)) },
                    backToToday: { path = [] }
                )
            }
        case .details(let id):
            if let plan = plans.first(where: { $0.id == id }) {
                PlanDetailView(
                    engine: engine,
                    plan: plan,
                    openSchedule: { path.append(.schedule) },
                    onRemoved: { path = [] }
                )
            }
        case .week(let id):
            WeekReadingView(library: library, schedule: schedule, weekID: id)
        case .schedule:
            ReadingScheduleView(schedule: schedule) { path.append(.week($0)) }
        }
    }
}

/// One plan: its name and where it is on the first line, its reading and whether it's done on the
/// second. The dots at the end open the plan's details.
private struct PlanRow: View {
    let title: String
    let status: PlanStatus
    let onOpen: () -> Void
    let onDetails: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private var layout: AnyLayout {
        typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
    }

    private var readingText: String {
        status.reading?.displayLabel ?? "You finished this plan."
    }

    private var spokenStatus: String {
        let reading = status.reading?.label ?? "You finished this plan."
        return [status.periodText, reading, status.doneText].compactMap(\.self).joined(separator: ", ")
    }

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 4) {
                    layout {
                        Text(title)
                            .font(.versedTitle(size: 25, relativeTo: .title3))
                            .foregroundStyle(.brand)
                            // Wraps at the largest text sizes instead of cutting the name off.
                            .fixedSize(horizontal: false, vertical: true)
                        if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                        Text(status.periodText)
                            .font(.versedNote)
                            .foregroundStyle(.secondaryText)
                    }
                    layout {
                        Text(readingText)
                            .font(.versedDetail)
                            .foregroundStyle(.brand)
                            .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                            .fixedSize(horizontal: false, vertical: typeSize.isAccessibilitySize)
                        if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                        if let doneText = status.doneText {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .regular))
                                Text(doneText)
                                    .font(.versedNote)
                            }
                            .foregroundStyle(.secondaryText)
                            .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
                .multilineTextAlignment(.leading)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.ledgerRow)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(spokenStatus)
            .accessibilityHint(status.isFinished ? "Opens this plan's details." : "Opens the reading.")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("Plan \(title)")

            Button(action: onDetails) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondaryText)
                    .frame(width: 44, height: 44, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.ledgerRow)
            .accessibilityLabel("Plan details, \(title)")
        }
    }
}
