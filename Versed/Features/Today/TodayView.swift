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
    /// Grows with the reader's text size, and stops where the other tabs' titles stop.
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 40.0
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

    /// Opening a plan moves the whole page, so it settles without the bounce buttons have.
    private static let openPlanAnimation = Animation.spring(duration: 0.38, bounce: 0)

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
                        .padding(.horizontal, Hardcover.margin)
                    if plans.isEmpty {
                        emptyState
                            .padding(.horizontal, Hardcover.margin)
                    } else {
                        planList
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .top, spacing: 0) {
                // The ribbon comes out from under this strip of paper, whose edge casts a faint shadow.
                // It also keeps anything from scrolling under the clock.
                Color.clear
                    .frame(height: 0)
                    .background {
                        PaperSurface().paperEdgeShadow(rise: 1)
                    }
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

    /// The title and date on the left, set level with the other tabs' titles, and the ribbon on the right.
    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.custom(Font.Bundled.title, fixedSize: min(titleSize, 46)))
                    .foregroundStyle(.brand)
                    .accessibilityAddTraits(.isHeader)
                SmallCapsLabel(VersedApp.today.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .accessibilityIdentifier("Today date")
            }
            .padding(.top, 55)
            Spacer(minLength: 0)
            StreakRibbon()
        }
    }

    private var planList: some View {
        let engine = engine
        return VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: 56)
            let ordered = orderedPlans
            ForEach(Array(ordered.enumerated()), id: \.element.id) { index, plan in
                let isOpen = openPlanID == plan.id
                // Each closed plan is ruled above and below, like a row in a table of contents.
                // The open band needs no line: its edges set it apart.
                if !isOpen, index == 0 || openPlanID != ordered[index - 1].id {
                    Rule.defined.padding(.horizontal, Hardcover.margin)
                }
                PlanSection(
                    title: engine.title(of: plan.state.source),
                    status: engine.status(of: plan.state),
                    time: engine.readingTime(of: plan.state),
                    chapterWord: engine.chapterWord(of: plan.state),
                    isOpen: isOpen,
                    onToggle: {
                        withAnimation(reduceMotion ? nil : Self.openPlanAnimation) {
                            openPlanID = isOpen ? nil : plan.id
                        }
                    },
                    onRead: { path.append(.reading(plan.id)) },
                    onDetails: { path.append(.details(plan.id)) }
                )
                // The open block's shadow falls on the plan below it.
                .zIndex(isOpen ? 1 : 0)
            }
            if let last = ordered.last, openPlanID != last.id {
                Rule.defined.padding(.horizontal, Hardcover.margin)
            }
            Color.clear.frame(height: 10)
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
            .padding(.horizontal, Hardcover.margin)
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
                .padding(.top, 60)
            Ledger {
                Button {
                    sheet = .setup(.weeklySchedule(course: nil))
                } label: {
                    LedgerRowLabel(title: WeeklyPlanName.title, detail: "Weekly schedule")
                }
                .buttonStyle(.ledgerRow)
                Button {
                    sheet = .setup(.volume("bofm"))
                } label: {
                    LedgerRowLabel(title: "Book of Mormon", detail: "At your pace")
                }
                .buttonStyle(.ledgerRow)
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
/// how long it takes and the way in. An open plan is a band of smooth navy across the page. Its
/// name steps down to a small label there, so the reading is the one big thing on it.
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
    private var ink: Color { isOpen ? .onCover : .brand }
    private var quietInk: Color { isOpen ? .onCover : .secondaryText }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    planName
                    if isDone {
                        GlyphView(.check, size: isOpen ? 11 : 15, lineWidth: 1.3)
                            .foregroundStyle(ink)
                    }
                    Spacer(minLength: 0)
                    GlyphView(.chevronForward, size: 13)
                        .foregroundStyle(quietInk)
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                }
                .padding(.top, isOpen ? 20 : 10)
                .padding(.bottom, isOpen ? 10 : 10)
                .frame(maxWidth: .infinity, minHeight: isOpen ? 52 : 68, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlanNameButtonStyle())
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
        .padding(.horizontal, Hardcover.margin)
        .background {
            ClothBand()
                .opacity(isOpen ? 1 : 0)
                // Solid almost at once when opening, so it never passes through a washed-out gray.
                .animation(isOpen ? .easeOut(duration: 0.1) : .easeIn(duration: 0.24), value: isOpen)
        }
    }

    /// Set large while closed, and as a small label above the reading while open.
    private var planName: some View {
        ZStack(alignment: .leading) {
            Text(title)
                .font(.versedTitle(size: 38, relativeTo: .title))
                .foregroundStyle(ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                // Gone almost at once when opening, so it never crosses the reading rising beneath it.
                .opacity(isOpen ? 0 : 1)
                .animation(isOpen ? .easeOut(duration: 0.08) : .easeIn(duration: 0.22).delay(0.1), value: isOpen)
                .frame(height: isOpen ? 0 : nil, alignment: .top)
                .clipped()
            SmallCapsLabel(title, color: .onCover)
                .opacity(isOpen ? 1 : 0)
                .animation(isOpen ? .easeIn(duration: 0.2).delay(0.1) : .easeOut(duration: 0.08), value: isOpen)
                .frame(height: isOpen ? nil : 0, alignment: .top)
                .clipped()
        }
    }

    private var spokenValue: String {
        [status.periodText, status.reading?.label ?? "You finished this plan.", status.doneText ?? time?.text]
            .compactMap(\.self)
            .joined(separator: ", ")
    }

    private var openContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let reading = status.reading {
                ReadingTitle(reading: reading, chapterWord: chapterWord, ink: ink)
            } else {
                Text("You finished this plan.")
                    .font(.versedTitle(size: 30, relativeTo: .title2))
                    .foregroundStyle(ink)
                    .stampedIntoCloth()
            }
            HStack(alignment: .firstTextBaseline) {
                Text(status.isFinished ? status.periodText : (isDone ? "Read today" : time?.text ?? ""))
                    .font(.versedVerse(size: 16, relativeTo: .subheadline))
                    .foregroundStyle(quietInk)
                Spacer(minLength: 12)
                Button("Details", action: onDetails)
                    .buttonStyle(PlainWordButtonStyle(ink: ink))
                    .accessibilityLabel("Plan details, \(title)")
            }
            .padding(.top, 6)
            if !status.isFinished {
                readButton.padding(.top, 10)
            }
            Color.clear.frame(height: 26)
        }
    }

    @ViewBuilder
    private var readButton: some View {
        if isDone {
            Button(action: onRead) {
                Text(status.readAhead == nil ? "Read Again" : "Read Ahead").frame(maxWidth: .infinity)
            }
            .buttonStyle(CoverSecondaryButtonStyle())
            .accessibilityIdentifier("Read \(title)")
        } else {
            Button(action: onRead) {
                Text(time?.hasStarted == true ? "Continue Reading" : "Start Reading").frame(maxWidth: .infinity)
            }
            .buttonStyle(CoverPrimaryButtonStyle())
            .accessibilityIdentifier("Read \(title)")
        }
    }
}

/// The open plan's band: smooth navy with a catch of light along its top edge, a darker lower edge,
/// and the shadow of something lying on the page.
private struct ClothBand: View {
    var body: some View {
        ZStack {
            Color.cover.restingShadow(depth: 0.8)
            VStack(spacing: 0) {
                Rule(color: .white.opacity(0.12))
                Spacer(minLength: 0)
                Rule(color: .black.opacity(0.35))
            }
        }
    }
}

/// A plan's name: dims a little under the finger, on the page or on the cloth.
private struct PlanNameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .animation(configuration.isPressed ? .easeOut(duration: 0.05) : .easeOut(duration: 0.3), value: configuration.isPressed)
    }
}

/// A reading's name set large: one book as big as the page allows, several set smaller together.
private struct ReadingTitle: View {
    let reading: ReadingPortion
    let chapterWord: String
    let ink: Color

    var body: some View {
        let books = reading.readingByBook
        VStack(alignment: .leading, spacing: books.count > 1 ? 6 : 0) {
            ForEach(books, id: \.self) { book in
                VStack(alignment: .leading, spacing: 0) {
                    Text(book.name)
                        .font(.versedTitle(size: nameSize(book, count: books.count), relativeTo: .largeTitle))
                        .foregroundStyle(ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .stampedIntoCloth()
                    if let chapters = chapterText(book) {
                        Text(chapters)
                            .font(.versedNumber(size: books.count > 1 ? 24 : 28, relativeTo: .title2))
                            .foregroundStyle(ink)
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
        case 1: book.name.count <= 11 ? 72 : 48
        case 2: 46
        default: 34
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
