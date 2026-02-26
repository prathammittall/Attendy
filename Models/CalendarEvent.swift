import Foundation

struct CalendarEvent: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var title: String
    var remarks: String

    init(id: UUID = UUID(), date: Date = Date(), title: String, remarks: String = "") {
        self.id = id
        self.date = date
        self.title = title
        self.remarks = remarks
    }

    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
