import SwiftData
import SwiftUI

/// The first tab: every study plan, one open at a time, with today's reading set large.
/// With no plans yet, it asks what the reader would like to read.
struct TodayView: View {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule
    @Binding var path: [Route]

    @Query(sort: \ReadingPlan.createdAt) private var plans: [ReadingPlan]
    /// The plan that's open. `nil` means every plan is closed.
    @State private var openPlanID: String?
    @State private var hasChosenOpenPlan = false
    /// The one sheet open over Today. iOS can close a sheet when a neighboring one updates, so they share this.
    @State private var sheet: Sheet?
    /// A choice from the plan picker, set up once the picker has closed.
    @State private var pickedSource: PlanSource?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The screens this tab can open.
    enum Route: Hashable {
        case reading(String)
        case details(String)
        case week(ReadingWeek.ID)
        case schedule
    }

    private enum Sheet: Identifiable {
        case picker
        case setup(PlanSource)

        var id: String {
            switch self {
            case .picker: "picker"
            case .setup(let source): "setup:\(source.key)"
            }
        }
    }

    private var engine: PlanEngine { PlanEngine(library: library, schedule: schedule) }
    private var orderedPlans: [ReadingPlan] { plans.sorted(by: ReadingPlan.comesFirst) }

    /// The first plan with reading left today.
    private var nextUpID: String? {
        let engine = engine
        return orderedPlans.first { plan in
            let status = engine.status(of: plan.state)
            return !status.isFinished && status.doneText == nil
        }?.id
    }

    var body: some View {
        // Reading the phase redraws the plans when the app comes back on a new day.
        let _ = scenePhase
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    if plans.isEmpty {
                        emptyState
                    } else {
                        planList
                    }
                }
                .padding(.horizontal, Hardcover.margin)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .top, spacing: 0) {
                // The line the ribbon hangs from, with solid paper above it so nothing scrolls under the clock.
                Rule().background(Color.appBackground.ignoresSafeArea(edges: .top))
            }
            .versedScreen()
            .toolbar(.hidden, for: .navigationBar)
            .navigationTitle("Today")
            .navigationDestination(for: Route.self, destination: destination)
            .onAppear(perform: chooseOpenPlanOnce)
            // Coming back from a reading lands on whatever's left to read.
            .onChange(of: path.isEmpty) { _, isOnToday in
                if isOnToday { openPlanID = nextUpID }
            }
            .onChange(of: plans.count) { _, _ in openPlanID = nextUpID }
            .sheet(item: $sheet, onDismiss: {
                if let pickedSource {
                    sheet = .setup(pickedSource)
                    self.pickedSource = nil
                }
            }) { sheet in
                sheetContent(sheet).versedSheet()
            }
        }
    }

    private func chooseOpenPlanOnce() {
        guard !hasChosenOpenPlan else { return }
        hasChosenOpenPlan = true
        openPlanID = nextUpID
    }

    /// The V, the ribbon, and the date, which holds the first line of the page.
    private var header: some View {
        VStack(alignment: .leading, spacing: 34) {
            HStack(alignment: .top) {
                VersedMark().padding(.top, 19)
                Spacer(minLength: 0)
                StreakRibbon()
            }
            SmallCapsLabel(VersedApp.today.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .accessibilityIdentifier("Today date")
        }
    }

    private var planList: some View {
        let engine = engine
        return VStack(alignment: .leading, spacing: 0) {
            Rule().padding(.top, 8)
            ForEach(orderedPlans) { plan in
                let isOpen = openPlanID == plan.id
                PlanSection(
                    title: engine.title(of: plan.state.source),
                    status: engine.status(of: plan.state),
                    time: engine.readingTime(of: plan.state),
                    chapterWord: engine.chapterWord(of: plan.state),
                    isOpen: isOpen,
                    onToggle: {
                        withAnimation(reduceMotion ? nil : .versed) {
                            openPlanID = isOpen ? nil : plan.id
                        }
                    },
                    onRead: { path.append(.reading(plan.id)) },
                    onDetails: { path.append(.details(plan.id)) }
                )
                Rule()
            }
            Button {
                sheet = .picker
            } label: {
                Text("+ Add a Plan")
                    .font(.versedRow)
                    .foregroundStyle(.brand)
                    .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.ledgerRow)
            .accessibilityLabel("Add a Plan")
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("What would you like to read?")
                .font(.versedTitle(size: 38, relativeTo: .title))
                .foregroundStyle(.brand)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 6)
            Ledger {
                Button {
                    sheet = .setup(.weeklySchedule(course: nil))
                } label: {
                    LedgerRowLabel(title: WeeklyPlanName.title, detail: "Weekly schedule")
                }
                .buttonStyle(.ledgerRow)
                LedgerRule()
                Button {
                    sheet = .setup(.volume("bofm"))
                } label: {
                    LedgerRowLabel(title: "Book of Mormon", detail: "At your pace")
                }
                .buttonStyle(.ledgerRow)
                LedgerRule()
                Button {
                    sheet = .picker
                } label: {
                    LedgerRowLabel(title: "Choose Something Else")
                }
                .buttonStyle(.ledgerRow)
            }
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: Sheet) -> some View {
        switch sheet {
        case .picker:
            PlanPickerView(engine: engine) { source in
                pickedSource = source
                self.sheet = nil
            }
        case .setup(let source):
            // Starting a plan goes straight into its reading.
            PlanSetupView(engine: engine, source: source) { path = [.reading($0)] }
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

/// One plan: its name, which opens and closes it, and when open, the reading set large with
/// how long it takes and the way in.
private struct PlanSection: View {
    let title: String
    let status: PlanStatus
    let time: PlanReadingTime?
    let chapterWord: String
    let isOpen: Bool
    let onToggle: () -> Void
    let onRead: () -> Void
    let onDetails: () -> Void

    private var isDone: Bool { status.doneText != nil || status.isFinished }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    (Text(title) + Text(isDone ? "  " : "") + checkmark)
                        .font(.versedTitle(size: 34, relativeTo: .title))
                        .foregroundStyle(.brand)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(.secondaryText)
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.ledgerRow)
            .accessibilityLabel(title)
            .accessibilityValue(spokenValue)
            .accessibilityHint(isOpen ? "Closes this plan." : "Opens this plan.")
            .accessibilityIdentifier("Plan \(title)")

            RevealLayout(progress: isOpen ? 1 : 0) {
                openContent
                    .opacity(isOpen ? 1 : 0)
            }
            .clipped()
            .allowsHitTesting(isOpen)
            .accessibilityHidden(!isOpen)
        }
    }

    private var checkmark: Text {
        isDone
            ? Text(Image(systemName: "checkmark")).font(.system(size: 15, weight: .regular)).baselineOffset(3)
            : Text("")
    }

    private var spokenValue: String {
        if status.isFinished { return "Finished" }
        return [status.reading?.label, status.doneText ?? time?.text].compactMap(\.self).joined(separator: ", ")
    }

    private var openContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let reading = status.reading {
                ReadingTitle(reading: reading, chapterWord: chapterWord)
            } else {
                Text("You finished this plan.")
                    .font(.versedTitle(size: 30, relativeTo: .title2))
                    .foregroundStyle(.brand)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(status.isFinished ? status.periodText : (isDone ? "Read today" : time?.text ?? ""))
                    .font(.versedVerse(size: 16, relativeTo: .subheadline))
                    .foregroundStyle(.secondaryText)
                Spacer(minLength: 12)
                Button("Details", action: onDetails)
                    .buttonStyle(.plainWord)
                    .accessibilityLabel("Plan details, \(title)")
            }
            .padding(.top, 2)
            if !status.isFinished {
                readButton.padding(.top, 8)
            }
            Color.clear.frame(height: 22)
        }
    }

    @ViewBuilder
    private var readButton: some View {
        if isDone {
            Button(action: onRead) {
                Text(status.readAhead == nil ? "Read Again" : "Read Ahead").frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondary)
            .accessibilityIdentifier("Read \(title)")
        } else {
            Button(action: onRead) {
                Text(time?.hasStarted == true ? "Continue Reading" : "Start Reading").frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .accessibilityIdentifier("Read \(title)")
        }
    }
}

/// A reading's name set large: one book as big as the page allows, several set smaller together.
private struct ReadingTitle: View {
    let reading: ReadingPortion
    let chapterWord: String

    var body: some View {
        let books = reading.readingByBook
        VStack(alignment: .leading, spacing: books.count > 1 ? 6 : 0) {
            ForEach(books, id: \.self) { book in
                VStack(alignment: .leading, spacing: 0) {
                    Text(book.name)
                        .font(.versedTitle(size: nameSize(book, count: books.count), relativeTo: .largeTitle))
                        .foregroundStyle(.brand)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    if let chapters = chapterText(book) {
                        Text(chapters)
                            .font(.versedNumber(size: books.count > 1 ? 22 : 27, relativeTo: .title2))
                            .foregroundStyle(.brand)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reading.label)
    }

    /// As big as fits: short names fill the page, longer ones and groups of books step down.
    private func nameSize(_ book: BookReading, count: Int) -> CGFloat {
        switch count {
        case 1: book.name.count <= 11 ? 72 : 44
        case 2: 42
        default: 32
        }
    }

    /// "Chapter 32" for one chapter alone, or the list as printed: "1–3, 33–34, 36–37, 47".
    private func chapterText(_ book: BookReading) -> String? {
        guard !book.chapters.isEmpty else { return nil }
        if book.chapters.count == 1, book.chapters[0].allSatisfy(\.isNumber) {
            return "\(chapterWord) \(book.chapters[0])"
        }
        return book.chapters.joined(separator: ", ")
    }
}

#Preview {
    TodayView(library: try! ScriptureLibrary.loadBundled(), schedule: try! ReadingSchedule.loadBundled(), path: .constant([]))
        .environment(ReadingChrome())
        .modelContainer(for: VersedApp.storedModels, inMemory: true)
}
