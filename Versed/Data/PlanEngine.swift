import Foundation

/// Where a plan stands right now.
struct PlanStatus: Hashable, Sendable {
    /// This day's or week's reading, or `nil` once the whole plan has been read.
    let reading: ReadingPortion?
    /// Where the plan is in time: "Day 4 of 57", "Week 3 of 52", or "Nov 2–8".
    let periodText: String
    /// "Done today" or "Done this week" once this period's reading is finished, or `nil` until then.
    let doneText: String?
    /// The next reading for someone who wants to go ahead, once this period's reading is finished.
    let readAhead: ReadingPortion?
    /// How much of the plan has been read, from 0 to 1.
    let progress: Double

    var isFinished: Bool { reading == nil }

    /// What opens when the reader taps the plan: this period's reading, then whatever comes after it.
    var nextToOpen: ReadingPortion? {
        doneText == nil ? reading : readAhead ?? reading
    }
}

/// One line of a plan's "Coming Up" list.
struct UpcomingReading: Hashable, Sendable {
    let when: String
    let label: String
}

/// What a plan's setup screen says about the choices made so far.
struct PlanPreview: Hashable, Sendable {
    /// "About 3 chapters a day."
    let summary: String
    /// "Finishes Feb 3, 2027."
    let finish: String?
}

/// Works out each plan's reading from its choices and progress. Nothing is stored ahead of time,
/// so a missed day simply spreads across the days left, with no record of being behind.
struct PlanEngine: Sendable {
    let library: ScriptureLibrary
    let schedule: ReadingSchedule
    var dates = PlanCalendar()

    // MARK: - Names

    func title(of source: PlanSource) -> String {
        switch source {
        case .weeklySchedule: WeeklyCover.title
        case .volume(let id): library.volume(id: id)?.title ?? ""
        case .book(let id): library.book(id: id)?.name ?? ""
        }
    }

    /// The course a weekly plan is reading, such as "Old Testament 2026".
    func course(of source: PlanSource, today: Date = VersedApp.today) -> String? {
        guard case .weeklySchedule(let course) = source else { return nil }
        return course ?? schedule.currentWeek(on: today)?.course
    }

    /// Every course in the schedule, in order.
    var courses: [String] {
        schedule.weeks.reduce(into: []) { courses, week in
            if courses.last != week.course { courses.append(week.course) }
        }
    }

    // MARK: - Starting a plan

    func newPlan(source: PlanSource, pace: PlanPace, finish: Date?, today: Date = VersedApp.today) -> PlanState {
        var state = PlanState(
            id: UUID().uuidString,
            source: source,
            pace: pace,
            startDay: ReadingDay.key(for: today, calendar: dates.calendar),
            finishDay: finish.map { ReadingDay.key(for: $0, calendar: dates.calendar) }
        )
        state.periodKey = dates.periodKey(for: today, pace: pace)
        if case .weeklySchedule(course: nil) = source {
            state.trackedWeekID = schedule.currentWeek(on: today)?.id
        }
        return state
    }

    /// Moves a plan on to the current day or week. A new day takes its starting point from what's been
    /// read so far, and a plan following the calendar starts each new week fresh.
    func rolledForward(_ state: PlanState, today: Date = VersedApp.today) -> PlanState {
        var state = state
        let key = dates.periodKey(for: today, pace: state.pace)
        if case .weeklySchedule(course: nil) = state.source,
           let week = schedule.currentWeek(on: today), week.id != state.trackedWeekID {
            state.trackedWeekID = week.id
            state.unitsRead = 0
            state.periodStart = 0
            state.periodKey = key
        } else if state.periodKey != key {
            state.periodStart = state.unitsRead
            state.periodKey = key
        }
        return state
    }

    /// Counts a page reached in `reading`. Reaching a chapter means the chapters before it have been
    /// read. `isClosingCard` means the whole reading has.
    func recordingProgress(
        _ state: PlanState,
        page itemID: FeedItem.ID,
        isClosingCard: Bool,
        in reading: ReadingPortion,
        today: Date = VersedApp.today
    ) -> PlanState {
        var state = rolledForward(state, today: today)
        // A feed left open past Sunday no longer belongs to the week the plan is on.
        if case .weeklySchedule(course: nil) = state.source, reading.weekID != state.trackedWeekID { return state }

        let reached: Int?
        if isClosingCard {
            reached = reading.firstUnit + reading.passages.count
        } else if let chapter = FeedItem.chapterID(of: itemID) {
            let verse = FeedItem.verseID(of: itemID)?.verse
            let index = reading.passages.firstIndex { passage in
                guard passage.bookID == chapter.bookID, passage.chapters.contains(chapter.chapter) else { return false }
                guard let verses = passage.verses, let verse else { return true }
                return verses.contains(verse)
            }
            reached = index.map { reading.firstUnit + $0 }
        } else {
            reached = nil
        }
        if let reached { state.unitsRead = max(state.unitsRead, reached) }
        return state
    }

    // MARK: - Where a plan stands

    func status(of state: PlanState, today: Date = VersedApp.today) -> PlanStatus {
        let state = rolledForward(state, today: today)
        switch state.source {
        case .weeklySchedule(course: nil): return calendarStatus(state, today: today)
        case .weeklySchedule(let course?): return ownPaceStatus(state, course: course)
        case .volume, .book: return deadlineStatus(state, today: today)
        }
    }

    func upcoming(for state: PlanState, limit: Int = 5, today: Date = VersedApp.today) -> [UpcomingReading] {
        let state = rolledForward(state, today: today)
        switch state.source {
        case .weeklySchedule(course: nil): return calendarUpcoming(state, limit: limit, today: today)
        case .weeklySchedule(let course?): return ownPaceUpcoming(state, course: course, limit: limit)
        case .volume, .book: return deadlineUpcoming(state, limit: limit, today: today)
        }
    }

    // MARK: - Chapters

    /// Every chapter in a book or volume, one passage each.
    func units(of source: PlanSource) -> [Passage] {
        let books: [Book]
        switch source {
        case .weeklySchedule: books = []
        case .volume(let id): books = library.volume(id: id)?.books ?? []
        case .book(let id): books = library.book(id: id).map { [$0] } ?? []
        }
        return books.flatMap { book in
            book.chapterCount > 0 ? (1...book.chapterCount).map { Passage(bookID: book.id, chapters: $0...$0) } : []
        }
    }

    /// A week's reading, one chapter or set of verses each. Passages with no text are left out.
    func units(of week: ReadingWeek) -> [Passage] {
        week.passages.flatMap { passage -> [Passage] in
            if passage.verses != nil { return [passage] }
            return passage.chapters.map { Passage(bookID: passage.bookID, chapters: $0...$0) }
        }
        .filter { weight(of: $0) > 0 }
    }

    private func weight(of passage: Passage) -> Int {
        guard let book = library.book(id: passage.bookID) else { return 0 }
        return passage.chapters.reduce(0) { total, chapter in
            let verses = book.verses(inChapter: chapter)
            return total + (passage.verses.map { range in verses.filter { range.contains($0.id.verse) }.count } ?? verses.count)
        }
    }

    private func weights(of units: some Sequence<Passage>) -> [Int] {
        units.map(weight(of:))
    }

    /// "Jeremiah 31–33; 36; Lamentations 1", in the same form the schedule prints its readings.
    func label(for units: some Collection<Passage>) -> String {
        var books: [(bookID: String, parts: [String])] = []
        var run: ClosedRange<Int>?

        func closeRun() {
            guard let chapters = run else { return }
            books[books.count - 1].parts.append(rangeText(chapters))
            run = nil
        }

        for unit in units {
            if books.last?.bookID != unit.bookID {
                closeRun()
                books.append((unit.bookID, []))
            }
            if let verses = unit.verses {
                closeRun()
                books[books.count - 1].parts.append("\(unit.chapters.lowerBound):\(rangeText(verses))")
            } else if let chapters = run, unit.chapters.lowerBound == chapters.upperBound + 1 {
                run = chapters.lowerBound...unit.chapters.upperBound
            } else {
                closeRun()
                run = unit.chapters
            }
        }
        closeRun()

        return books.map { book in
            let name = library.book(id: book.bookID)?.referenceName ?? book.bookID
            return "\(name) \(book.parts.joined(separator: "; "))"
        }
        .joined(separator: "; ")
    }

    private func rangeText(_ range: ClosedRange<Int>) -> String {
        range.count == 1 ? "\(range.lowerBound)" : "\(range.lowerBound)–\(range.upperBound)"
    }

    // MARK: - Plans with a finish date

    private func deadlineStatus(_ state: PlanState, today: Date) -> PlanStatus {
        let units = units(of: state.source)
        let weights = weights(of: units)
        let progress = units.isEmpty ? 1 : Double(state.unitsRead) / Double(units.count)
        let periods = deadlinePeriods(state)
        let index = periods.lastIndex { $0.start <= dates.calendar.startOfDay(for: today) } ?? 0
        let word = state.pace == .day ? "Day" : "Week"
        let isPastFinish = isPast(finishOf: state, today: today)
        let periodText = isPastFinish ? "\(Int((progress * 100).rounded()))% read" : "\(word) \(index + 1) of \(periods.count)"

        guard state.unitsRead < units.count else {
            return PlanStatus(reading: nil, periodText: "Finished", doneText: nil, readAhead: nil, progress: 1)
        }

        let lengths = remainingLengths(state, from: index, unitsFrom: state.periodStart, weights: weights, today: today)
        let count = PlanPacer.nextCount(weights: weights[state.periodStart...], lengths: lengths)
        let chunk = state.periodStart..<state.periodStart + count
        let isDone = state.unitsRead >= chunk.upperBound

        let reading = deadlinePortion(
            state,
            units: units,
            range: chunk,
            heading: periodText,
            closingTitle: state.pace == .day ? ReadingPortion.endOfDay : ReadingPortion.endOfWeek
        )

        var readAhead: ReadingPortion?
        if isDone {
            let aheadLengths = remainingLengths(state, from: index + 1, unitsFrom: state.unitsRead, weights: weights, today: today)
            let aheadCount = PlanPacer.nextCount(weights: weights[state.unitsRead...], lengths: aheadLengths)
            readAhead = deadlinePortion(
                state,
                units: units,
                range: state.unitsRead..<state.unitsRead + aheadCount,
                heading: "Reading Ahead",
                closingTitle: ReadingPortion.endOfReading
            )
        }

        return PlanStatus(
            reading: reading,
            periodText: periodText,
            doneText: isDone ? (state.pace == .day ? "Done today" : "Done this week") : nil,
            readAhead: readAhead,
            progress: progress
        )
    }

    private func deadlineUpcoming(_ state: PlanState, limit: Int, today: Date) -> [UpcomingReading] {
        let units = units(of: state.source)
        guard state.unitsRead < units.count else { return [] }
        let weights = weights(of: units)
        let periods = deadlinePeriods(state)
        let index = (periods.lastIndex { $0.start <= dates.calendar.startOfDay(for: today) } ?? 0) + 1
        guard index < periods.count, state.unitsRead < weights.count else { return [] }

        // What's left after this period's reading, handed out across the periods after it.
        let current = PlanPacer.nextCount(
            weights: weights[state.periodStart...],
            lengths: remainingLengths(state, from: index - 1, unitsFrom: state.periodStart, weights: weights, today: today)
        )
        let start = max(state.unitsRead, state.periodStart + current)
        guard start < weights.count else { return [] }

        let later = Array(periods[index...])
        let chunks = PlanPacer.chunks(weights: Array(weights[start...]), lengths: later.map(\.length))
        return zip(later, chunks).prefix(limit).map { period, chunk in
            UpcomingReading(
                when: dates.shortDate(period.start, relativeTo: today),
                label: label(for: units[(start + chunk.lowerBound)..<(start + chunk.upperBound)])
            )
        }
    }

    private func deadlinePortion(_ state: PlanState, units: [Passage], range: Range<Int>, heading: String, closingTitle: String) -> ReadingPortion {
        let label = label(for: units[range])
        return ReadingPortion(
            id: "\(state.id)-\(range.lowerBound)-\(range.upperBound)",
            label: label,
            passages: Array(units[range]),
            heading: heading,
            spokenHeading: "\(heading), \(label)",
            closingTitle: range.upperBound >= units.count ? ReadingPortion.endOfPlan : closingTitle,
            firstUnit: range.lowerBound
        )
    }

    private func deadlinePeriods(_ state: PlanState) -> [PlanCalendar.Period] {
        let start = ReadingDay.date(forKey: state.startDay, calendar: dates.calendar) ?? .now
        let finish = state.finishDay.flatMap { ReadingDay.date(forKey: $0, calendar: dates.calendar) } ?? start
        return dates.periods(from: start, through: finish, pace: state.pace)
    }

    private func isPast(finishOf state: PlanState, today: Date) -> Bool {
        guard let finish = state.finishDay.flatMap({ ReadingDay.date(forKey: $0, calendar: dates.calendar) }) else { return false }
        return dates.calendar.startOfDay(for: today) > finish
    }

    /// The periods left to share the reading across. After the finish date the plan keeps its
    /// original pace instead of asking for everything at once.
    private func remainingLengths(_ state: PlanState, from index: Int, unitsFrom start: Int, weights: [Int], today: Date) -> [Int] {
        let periods = deadlinePeriods(state)
        if !isPast(finishOf: state, today: today), index < periods.count {
            return periods[index...].map(\.length)
        }
        let total = max(weights.reduce(0, +), 1)
        let left = weights[min(start, weights.count)...].reduce(0, +)
        let count = Int((Double(left) * Double(periods.count) / Double(total)).rounded(.up))
        return Array(repeating: 1, count: max(count, 1))
    }

    // MARK: - Following the calendar

    private func calendarStatus(_ state: PlanState, today: Date) -> PlanStatus {
        guard let week = schedule.currentWeek(on: today), let lastWeek = schedule.weeks.last, today < lastWeek.end else {
            return PlanStatus(reading: nil, periodText: "Finished", doneText: nil, readAhead: nil, progress: 1)
        }
        let units = units(of: week)
        let progress = units.isEmpty ? 1 : min(Double(state.unitsRead) / Double(units.count), 1)
        let dateText = week.dateRangeText(calendar: dates.calendar)

        guard state.pace == .day else {
            let isDone = state.unitsRead >= units.count
            return PlanStatus(
                reading: weekPortion(
                    state, week: week, units: units, range: 0..<units.count,
                    heading: "This Week · \(dateText)",
                    spokenHeading: "This Week, \(week.label), \(dateText)",
                    closingTitle: ReadingPortion.endOfWeek
                ),
                periodText: dateText,
                doneText: isDone ? "Done this week" : nil,
                readAhead: nil,
                progress: progress
            )
        }

        let dayIndex = min(max(dates.days(from: week.start, to: today), 0), 6)
        let heading = "Day \(dayIndex + 1) of 7"
        let weights = weights(of: units)
        let start = min(state.periodStart, units.count)
        let lengths = Array(repeating: 1, count: 7 - dayIndex)
        let count = PlanPacer.nextCount(weights: weights[start...], lengths: lengths)

        // With nothing left this week, the row shows the week's whole reading as done.
        let range = count == 0 ? 0..<units.count : start..<start + count
        let isDone = state.unitsRead >= range.upperBound
        let reading = weekPortion(state, week: week, units: units, range: range, heading: "\(heading) · \(dateText)", closingTitle: ReadingPortion.endOfDay)

        var readAhead: ReadingPortion?
        if isDone, state.unitsRead < units.count {
            let aheadCount = PlanPacer.nextCount(weights: weights[state.unitsRead...], lengths: Array(repeating: 1, count: max(6 - dayIndex, 1)))
            readAhead = weekPortion(state, week: week, units: units, range: state.unitsRead..<state.unitsRead + aheadCount, heading: "Reading Ahead", closingTitle: ReadingPortion.endOfReading)
        }

        return PlanStatus(
            reading: reading,
            periodText: heading,
            doneText: isDone ? (state.unitsRead >= units.count ? "Done this week" : "Done today") : nil,
            readAhead: readAhead,
            progress: progress
        )
    }

    private func calendarUpcoming(_ state: PlanState, limit: Int, today: Date) -> [UpcomingReading] {
        schedule.weeks.filter { $0.start > today }.prefix(limit).map {
            UpcomingReading(when: $0.dateRangeText(calendar: dates.calendar), label: $0.label)
        }
    }

    /// Part of a week. Keeps the schedule's own words when the whole week is read at once, or when the
    /// week is made of scattered verses, whose references would be too long to show ("Christmas").
    private func weekPortion(_ state: PlanState, week: ReadingWeek, units: [Passage], range: Range<Int>, heading: String, spokenHeading: String? = nil, closingTitle: String, offset: Int = 0) -> ReadingPortion {
        let slice = units[range]
        let usesWeekLabel = range.count == units.count || slice.contains { $0.verses != nil }
        let label = usesWeekLabel ? week.label : label(for: slice)
        return ReadingPortion(
            id: "\(state.id)-\(week.id)-\(range.lowerBound)-\(range.upperBound)",
            label: label,
            passages: Array(slice),
            heading: heading,
            spokenHeading: spokenHeading ?? "\(heading), \(label)",
            closingTitle: closingTitle,
            lessonURL: week.lessonURL,
            weekID: week.id,
            firstUnit: offset + range.lowerBound
        )
    }

    // MARK: - A course at the reader's own pace

    /// A course's weeks with where each one starts in the course's list of chapters.
    private func courseWeeks(_ course: String) -> [(week: ReadingWeek, units: [Passage], offset: Int)] {
        var offset = 0
        return schedule.weeks.filter { $0.course == course }.map { week in
            let units = units(of: week)
            defer { offset += units.count }
            return (week, units, offset)
        }
    }

    private func ownPaceStatus(_ state: PlanState, course: String) -> PlanStatus {
        let weeks = courseWeeks(course)
        let total = weeks.reduce(0) { $0 + $1.units.count }
        guard state.unitsRead < total else {
            return PlanStatus(reading: nil, periodText: "Finished", doneText: nil, readAhead: nil, progress: 1)
        }
        let progress = total == 0 ? 1 : Double(state.unitsRead) / Double(total)

        let current = ownPacePortion(state, weeks: weeks, at: state.periodStart, heading: nil)
        let end = current.portion.firstUnit + current.portion.passages.count
        let isDone = state.unitsRead >= end
        let readAhead = isDone ? ownPacePortion(state, weeks: weeks, at: state.unitsRead, heading: "Reading Ahead").portion : nil

        return PlanStatus(
            reading: current.portion,
            periodText: current.periodText,
            doneText: isDone ? (state.pace == .day ? "Done today" : "Done this week") : nil,
            readAhead: readAhead,
            progress: progress
        )
    }

    private func ownPaceUpcoming(_ state: PlanState, course: String, limit: Int) -> [UpcomingReading] {
        let weeks = courseWeeks(course)
        let total = weeks.reduce(0) { $0 + $1.units.count }
        var result: [UpcomingReading] = []
        let current = ownPacePortion(state, weeks: weeks, at: min(state.periodStart, max(total - 1, 0)), heading: nil).portion
        var next = max(current.firstUnit + current.passages.count, state.unitsRead)
        while next < total, result.count < limit {
            let item = ownPacePortion(state, weeks: weeks, at: next, heading: nil)
            result.append(UpcomingReading(when: item.periodText, label: item.portion.label))
            next = item.portion.firstUnit + item.portion.passages.count
        }
        return result
    }

    /// The reading holding chapter `unit`: its whole week, or that week's share of a day.
    private func ownPacePortion(
        _ state: PlanState,
        weeks: [(week: ReadingWeek, units: [Passage], offset: Int)],
        at unit: Int,
        heading: String?
    ) -> (portion: ReadingPortion, periodText: String) {
        let index = weeks.lastIndex { $0.offset <= unit && !$0.units.isEmpty } ?? 0
        let (week, units, offset) = weeks[index]
        let weekText = "Week \(index + 1) of \(weeks.count)"

        guard state.pace == .day else {
            let portion = weekPortion(state, week: week, units: units, range: 0..<units.count, heading: heading ?? weekText, closingTitle: heading == nil ? ReadingPortion.endOfWeek : ReadingPortion.endOfReading, offset: offset)
            return (portion, weekText)
        }

        let chunks = PlanPacer.chunks(weights: weights(of: units), lengths: Array(repeating: 1, count: 7))
        let dayIndex = chunks.firstIndex { $0.contains(unit - offset) } ?? 0
        let text = "Week \(index + 1), Day \(dayIndex + 1)"
        let portion = weekPortion(state, week: week, units: units, range: chunks[dayIndex], heading: heading ?? text, closingTitle: heading == nil ? ReadingPortion.endOfDay : ReadingPortion.endOfReading, offset: offset)
        return (portion, text)
    }

    // MARK: - Previewing a plan

    func preview(source: PlanSource, pace: PlanPace, finish: Date?, today: Date = VersedApp.today) -> PlanPreview {
        switch source {
        case .weeklySchedule(course: nil):
            return PlanPreview(
                summary: pace == .week
                    ? "A new reading each Monday, on the same dates as the schedule."
                    : "Each week’s chapters, shared across its days.",
                finish: nil
            )
        case .weeklySchedule(let course?):
            let count = schedule.weeks.filter { $0.course == course }.count
            return PlanPreview(
                summary: pace == .week
                    ? "\(count) weeks at your own pace. Week 1 starts now, and a week waits until you finish it."
                    : "\(count) weeks at your own pace, with each week shared across seven days. Week 1 starts now.",
                finish: nil
            )
        case .volume, .book:
            let units = units(of: source)
            let finish = finish ?? today
            let periods = dates.periods(from: today, through: finish, pace: pace)
            let chunks = PlanPacer.chunks(weights: weights(of: units), lengths: periods.map(\.length))
            let average = Int((Double(units.count) / Double(max(chunks.count, 1))).rounded())
            let word = unitWord(for: source, count: average)
            let lastPeriod = chunks.isEmpty ? nil : periods[chunks.count - 1]
            let lastDay = lastPeriod.flatMap { dates.calendar.date(byAdding: .day, value: $0.length - 1, to: $0.start) }
            return PlanPreview(
                summary: "About \(average) \(word) a \(pace.label.lowercased()).",
                finish: lastDay.map { "Finishes \(dates.shortDate($0, relativeTo: today))." }
            )
        }
    }

    private func unitWord(for source: PlanSource, count: Int) -> String {
        var word = "chapter"
        if case .book(let id) = source, let label = library.book(id: id)?.chapterLabel { word = label.lowercased() }
        if case .volume(let id) = source, let books = library.volume(id: id)?.books, books.count == 1, let label = books[0].chapterLabel { word = label.lowercased() }
        return count == 1 ? word : word + "s"
    }
}
