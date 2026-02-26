import Foundation

enum AttendanceStatus: String, Codable, CaseIterable, Hashable {
    case clear
    case present
    case absent
    case off

    var label: String {
        switch self {
        case .clear: return "Clear"
        case .present: return "Present"
        case .absent: return "Absent"
        case .off: return "Off"
        }
    }

    var icon: String {
        switch self {
        case .clear: return "minus.circle"
        case .present: return "checkmark.circle.fill"
        case .absent: return "xmark.circle.fill"
        case .off: return "moon.circle.fill"
        }
    }
}

struct AttendanceEntry: Codable, Identifiable, Hashable {
    var id: UUID
    var subjectID: UUID
    var slotID: UUID        // unique per timetable slot — allows same subject twice on a day
    var date: Date
    var status: AttendanceStatus

    init(id: UUID = UUID(), subjectID: UUID, slotID: UUID, date: Date = Date(), status: AttendanceStatus) {
        self.id = id
        self.subjectID = subjectID
        self.slotID = slotID
        self.date = date
        self.status = status
    }

    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
