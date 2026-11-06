import Foundation
import SwiftData

/// How a plan's reading is handed out.
enum PlanPace: String, CaseIterable, Identifiable, Hashable, Sendable {
    case day
    case week

    var id: Self { self }

    var label: String {
        switch self {
        case .day: "Day"
        case .week: "Week"
        }
    }
}

/// What a plan reads.
enum PlanSource: Hashable, Identifiable, Sendable {
    /// The weekly schedule: one course such as "Old Testament 2026" from its first week,
    /// or, with no course, whichever week the calendar is on.
    case weeklySchedule(course: String?)
    case volume(Volume.ID)
    case book(Book.ID)

    /// Written to the phone, so these words can't change.
    var key: String {
        switch self {
        case .weeklySchedule(let course): "schedule:\(course ?? "")"
        case .volume(let id): "volume:\(id)"
        case .book(let id): "book:\(id)"
        }
    }

    var id: String { key }

    init?(key: String) {
        guard let divider = key.firstIndex(of: ":") else { return nil }
        let value = String(key[key.index(after: divider)...])
        switch key[..<divider] {
        case "schedule": self = .weeklySchedule(course: value.isEmpty ? nil : value)
        case "volume": self = .volume(value)
        case "book": self = .book(value)
        default: return nil
        }
    }

    var isWeeklySchedule: Bool {
        if case .weeklySchedule = self { true } else { false }
    }
}

/// A plan's choices and progress as plain values, so the pacing can be worked out and tested
/// without the database.
struct PlanState: Hashable, Sendable {
    var id: String
    var source: PlanSource
    var pace: PlanPace
    /// The first day, as "yyyy-MM-dd".
    var startDay: String
    /// The day to finish by, as "yyyy-MM-dd". Schedule plans have none.
    var finishDay: String?
    /// How many chapters have been read, counted from the start of the plan. A plan following the
    /// calendar counts from the start of the week it's on.
    var unitsRead = 0
    /// The day or week `periodStart` was noted for, as "yyyy-MM-dd".
    var periodKey = ""
    /// `unitsRead` when this day or week began, so the day's reading doesn't move as it's read.
    var periodStart = 0
    /// The schedule week a plan following the calendar is on.
    var trackedWeekID: ReadingWeek.ID?
}

/// One study plan, stored on the phone. Only the choices and a count of chapters read are stored;
/// each day's reading is worked out from them by `PlanEngine`.
@Model
final class ReadingPlan {
    @Attribute(.unique) var id: String
    var sourceKey: String
    var paceRaw: String
    var startDay: String
    var finishDay: String?
    var unitsRead: Int
    var periodKey: String
    var periodStart: Int
    var trackedWeekID: String?
    var createdAt: Date
    /// Where the reader moved this plan to on Today. Plans never moved follow in the order they were started.
    var sortOrder: Int?

    init(state: PlanState, createdAt: Date = .now) {
        id = state.id
        sourceKey = state.source.key
        paceRaw = state.pace.rawValue
        startDay = state.startDay
        finishDay = state.finishDay
        unitsRead = state.unitsRead
        periodKey = state.periodKey
        periodStart = state.periodStart
        trackedWeekID = state.trackedWeekID
        self.createdAt = createdAt
    }

    /// The order plans appear in on Today.
    static func comesFirst(_ first: ReadingPlan, _ second: ReadingPlan) -> Bool {
        switch (first.sortOrder, second.sortOrder) {
        case let (one?, two?) where one != two: one < two
        case (_?, nil): true
        case (nil, _?): false
        default: first.createdAt < second.createdAt
        }
    }

    var state: PlanState {
        get {
            PlanState(
                id: id,
                source: PlanSource(key: sourceKey) ?? .weeklySchedule(course: nil),
                pace: PlanPace(rawValue: paceRaw) ?? .day,
                startDay: startDay,
                finishDay: finishDay,
                unitsRead: unitsRead,
                periodKey: periodKey,
                periodStart: periodStart,
                trackedWeekID: trackedWeekID
            )
        }
        set {
            paceRaw = newValue.pace.rawValue
            finishDay = newValue.finishDay
            unitsRead = newValue.unitsRead
            periodKey = newValue.periodKey
            periodStart = newValue.periodStart
            trackedWeekID = newValue.trackedWeekID
        }
    }
}
