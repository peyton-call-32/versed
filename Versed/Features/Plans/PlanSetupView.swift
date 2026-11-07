import SwiftData
import SwiftUI

/// Sets up a new plan in a few choices: how long to take, and whether to read by day or by week.
/// The weekly schedule instead asks whether to join this week or start from the beginning.
struct PlanSetupView: View {
    let engine: PlanEngine
    let source: PlanSource
    /// Opens a plan that already exists or was just started.
    let onOpenPlan: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// How long to take over a book.
    private enum Length: Hashable, Identifiable {
        case days(Int)
        case byDate

        var id: Self { self }

        var label: String {
            switch self {
            case .days(30): "30 Days"
            case .days(90): "90 Days"
            case .days(365): "1 Year"
            case .days(let count): "\(count) Days"
            case .byDate: "By a Date"
            }
        }
    }

    @State private var pace: PlanPace
    @State private var length: Length
    @State private var finishDate: Date
    /// For the weekly schedule: follow the calendar, or start from the first week.
    @State private var joinsThisWeek = true
    @State private var course: String

    init(engine: PlanEngine, source: PlanSource, onOpenPlan: @escaping (String) -> Void) {
        self.engine = engine
        self.source = source
        self.onOpenPlan = onOpenPlan

        let today = VersedApp.today
        let calendar = engine.dates.calendar
        _pace = State(initialValue: source.isWeeklySchedule ? .week : .day)
        let chapters = engine.units(of: source).count
        _length = State(initialValue: chapters > 300 ? .days(365) : chapters > 40 ? .days(90) : .days(30))
        // The end of the year, or of next year when this one is nearly over.
        let year = calendar.component(.year, from: today)
        let yearEnd = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) ?? today
        let isNearlyOver = engine.dates.days(from: today, to: yearEnd) < 14
        _finishDate = State(initialValue: isNearlyOver ? calendar.date(byAdding: .year, value: 1, to: yearEnd) ?? yearEnd : yearEnd)
        _course = State(initialValue: engine.course(of: source) ?? engine.courses.first ?? "")
    }

    private var today: Date { VersedApp.today }

    /// Time frames that suit the book. A year means little for a book of four chapters.
    private var lengths: [Length] {
        let chapters = engine.units(of: source).count
        return [30, 90, 365].filter { $0 == 30 || $0 <= chapters * 14 }.map(Length.days) + [.byDate]
    }

    private var finish: Date? {
        switch length {
        case .days(let count): engine.dates.calendar.date(byAdding: .day, value: count - 1, to: today)
        case .byDate: finishDate
        }
    }

    /// What will actually be started, given the choices so far.
    private var chosenSource: PlanSource {
        guard source.isWeeklySchedule else { return source }
        return .weeklySchedule(course: joinsThisWeek ? nil : course)
    }

    private var store: ReadingPlanStore { ReadingPlanStore(context: modelContext, engine: engine) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Hardcover.sectionSpacing) {
                    if source.isWeeklySchedule {
                        startingPoint
                        if !joinsThisWeek && engine.courses.count > 1 { courseChoice }
                    } else {
                        lengthChoice
                    }
                    // A plan that's already going keeps its own pace, changed from its details.
                    if store.plan(for: chosenSource) == nil {
                        paceChoice
                        preview
                    }
                    startButton
                    if source.isWeeklySchedule {
                        Text(WeeklyPlanName.notice)
                            .font(.versedNote)
                            .foregroundStyle(.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .versedPage()
            }
            .versedScreen()
            .tint(Color.brand)
            .navigationTitle(engine.title(of: source))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                DoneToolbarItem(title: "Cancel") { dismiss() }
            }
        }
    }

    private var startingPoint: some View {
        LedgerSection(title: "Where to Start") {
            ChoiceRow(
                title: "Join This Week",
                detail: engine.schedule.currentWeek().map { "\($0.dateRangeText()): \($0.displayLabel)" },
                isSelected: joinsThisWeek
            ) { joinsThisWeek = true }
            ChoiceRow(
                title: "Start from the Beginning",
                detail: "Week 1 starts now, at your own pace.",
                isSelected: !joinsThisWeek
            ) { joinsThisWeek = false }
        }
    }

    private var courseChoice: some View {
        LedgerSection(title: "Which Year") {
            ForEach(engine.courses, id: \.self) { option in
                ChoiceRow(title: option, isSelected: course == option) { course = option }
            }
        }
    }

    private var lengthChoice: some View {
        LedgerSection(title: "How Long") {
            ForEach(lengths) { option in
                ChoiceRow(title: option.label, isSelected: length == option) { length = option }
            }
            if length == .byDate {
                DateRow(title: "Finish By", date: $finishDate, earliest: today)
            }
        }
    }

    private var paceChoice: some View {
        LedgerSection(title: "Read By") {
            BlockPicker(options: PlanPace.allCases, selection: $pace) { $0.label }
        }
    }

    private var preview: some View {
        let text = engine.preview(source: chosenSource, pace: pace, finish: finish)
        return VStack(spacing: 4) {
            Text(text.summary)
                .font(.versedRow)
                .foregroundStyle(.brand)
            if let finish = text.finish {
                Text(finish)
                    .font(.versedDetail)
                    .foregroundStyle(.secondaryText)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("Plan preview")
    }

    @ViewBuilder
    private var startButton: some View {
        if let existing = store.plan(for: chosenSource) {
            Button {
                dismiss()
                onOpenPlan(existing.id)
            } label: {
                Text("Open Your Plan").frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
        } else {
            Button {
                let plan = store.start(source: chosenSource, pace: pace, finish: source.isWeeklySchedule ? nil : finish)
                dismiss()
                onOpenPlan(plan.id)
            } label: {
                Text("Start Plan").frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
        }
    }
}
