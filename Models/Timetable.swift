import Foundation

enum Weekday: Int, Codable, CaseIterable, Hashable, Comparable {
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    case sunday = 1

    var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }

    var fullName: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }

    static func today() -> Weekday {
        let weekdayNumber = Calendar.current.component(.weekday, from: Date())
        return Weekday(rawValue: weekdayNumber) ?? .monday
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        let order: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
        let lhsIndex = order.firstIndex(of: lhs) ?? 0
        let rhsIndex = order.firstIndex(of: rhs) ?? 0
        return lhsIndex < rhsIndex
    }
}

// A single slot in the timetable — has its own unique ID so duplicate subjects
// on the same day can be told apart.
struct TimetableSlot: Codable, Identifiable, Hashable {
    var id: UUID
    var subjectID: UUID

    init(subjectID: UUID) {
        self.id = UUID()
        self.subjectID = subjectID
    }
}

struct Timetable: Codable {
    var schedule: [String: [TimetableSlot]]

    init() {
        schedule = [:]
    }

    func slots(for day: Weekday) -> [TimetableSlot] {
        schedule["\(day.rawValue)"] ?? []
    }

    func subjectIDs(for day: Weekday) -> [UUID] {
        slots(for: day).map { $0.subjectID }
    }

    mutating func setSlots(for day: Weekday, slots: [TimetableSlot]) {
        schedule["\(day.rawValue)"] = slots
    }
}
