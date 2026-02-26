import Foundation

enum DutyLeaveType: String, Codable, CaseIterable, Hashable {
    case fullDay = "fullDay"
    case perSubject = "perSubject"

    var label: String {
        switch self {
        case .fullDay: return "Full Day"
        case .perSubject: return "Selected Subjects"
        }
    }
}

struct DutyLeave: Codable, Identifiable, Hashable {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var eventName: String
    var type: DutyLeaveType
    var clubName: String          // optional — can be empty
    var remarks: String           // optional — can be empty
    var subjectIDs: [UUID]        // only used when type == .perSubject; empty for fullDay

    init(id: UUID = UUID(),
         startDate: Date = Date(),
         endDate: Date = Date(),
         eventName: String,
         type: DutyLeaveType,
         clubName: String = "",
         remarks: String = "",
         subjectIDs: [UUID] = []) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.eventName = eventName
        self.type = type
        self.clubName = clubName
        self.remarks = remarks
        self.subjectIDs = subjectIDs
    }

    /// All yyyy-MM-dd keys covered by this duty leave
    var dateKeys: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        var keys: [String] = []
        var current = start
        while current <= end {
            keys.append(formatter.string(from: current))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return keys
    }

    /// Check if a specific date falls within this duty leave range
    func coversDate(_ dateKey: String) -> Bool {
        dateKeys.contains(dateKey)
    }

    /// Human-readable date range label
    var dateRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        let calendar = Calendar.current
        if calendar.isDate(startDate, inSameDayAs: endDate) {
            return formatter.string(from: startDate)
        }
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }
}
