import SwiftUI

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var entries: [AttendanceEntry] = []
    @Published var subjects: [Subject] = []
    @Published var timetable: Timetable = Timetable()
    @Published var events: [CalendarEvent] = []
    @Published var dutyLeaves: [DutyLeave] = []

    // Date attendance marking
    @Published var dateAttendanceItems: [IndexedSubject] = []
    @Published var dateAttendanceEntries: [UUID: AttendanceStatus] = [:]

    private let storage = LocalStorageManager.shared

    func load() {
        subjects = storage.loadSubjects()
        entries = storage.loadEntries()
        timetable = storage.loadTimetable()
        events = storage.loadEvents()
        dutyLeaves = storage.loadDutyLeaves()
    }

    var selectedDateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }

    func entriesForSelectedDate() -> [(Subject, AttendanceStatus)] {
        let dayEntries = entries.filter { $0.dateKey == selectedDateKey }
        var results: [(Subject, AttendanceStatus)] = []
        for entry in dayEntries {
            if let subject = subjects.first(where: { $0.id == entry.subjectID }) {
                results.append((subject, entry.status))
            }
        }
        return results
    }

    func eventsForSelectedDate() -> [CalendarEvent] {
        events.filter { $0.dateKey == selectedDateKey }
    }

    func addEvent(title: String, remarks: String) {
        let event = CalendarEvent(date: selectedDate, title: title, remarks: remarks)
        events.append(event)
        storage.saveEvents(events)
    }

    func deleteEvent(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
        storage.saveEvents(events)
    }

    // MARK: - Duty Leaves

    func dutyLeavesForSelectedDate() -> [DutyLeave] {
        dutyLeaves.filter { $0.coversDate(selectedDateKey) }
    }

    func addDutyLeave(_ dl: DutyLeave) {
        dutyLeaves.append(dl)
        storage.saveDutyLeaves(dutyLeaves)

        // Auto-create a calendar event for the DL (on start date)
        var eventRemarks = "Duty Leave (\(dl.type.label))"
        if !dl.clubName.isEmpty {
            eventRemarks += " \u{2022} \(dl.clubName)"
        }
        eventRemarks += "\n\(dl.dateRangeLabel)"
        if !dl.remarks.isEmpty {
            eventRemarks += "\n\(dl.remarks)"
        }
        let event = CalendarEvent(date: dl.startDate, title: "\u{1F393} \(dl.eventName)", remarks: eventRemarks)
        events.append(event)
        storage.saveEvents(events)
    }

    func deleteDutyLeave(_ dl: DutyLeave) {
        dutyLeaves.removeAll { $0.id == dl.id }
        storage.saveDutyLeaves(dutyLeaves)
    }

    func datesWithActivity(in month: Date) -> (entries: Set<String>, events: Set<String>) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)

        let entryDates = Set(entries.compactMap { entry -> String? in
            let ec = calendar.dateComponents([.year, .month], from: entry.date)
            return (ec.year == components.year && ec.month == components.month) ? entry.dateKey : nil
        })

        let eventDates = Set(events.compactMap { event -> String? in
            let ec = calendar.dateComponents([.year, .month], from: event.date)
            return (ec.year == components.year && ec.month == components.month) ? event.dateKey : nil
        })

        return (entryDates, eventDates)
    }

    // Keep old method for any existing callers
    func datesWithEntries(in month: Date) -> Set<String> {
        datesWithActivity(in: month).entries
    }

    func weekday(for date: Date) -> Weekday {
        let weekdayNumber = Calendar.current.component(.weekday, from: date)
        return Weekday(rawValue: weekdayNumber) ?? .monday
    }

    // MARK: - Date Attendance Marking

    func loadDateAttendance() {
        let weekdayNum = Calendar.current.component(.weekday, from: selectedDate)
        guard let weekday = Weekday(rawValue: weekdayNum) else { return }

        let slots = timetable.slots(for: weekday)
        dateAttendanceItems = slots.enumerated().compactMap { index, slot in
            guard let subject = subjects.first(where: { $0.id == slot.subjectID }) else { return nil }
            return IndexedSubject(index: index, subject: subject, slotID: slot.id)
        }

        let dk = selectedDateKey
        let timetableSlotIDs = Set(dateAttendanceItems.map { $0.slotID })
        dateAttendanceEntries = [:]

        for entry in entries where entry.dateKey == dk {
            dateAttendanceEntries[entry.slotID] = entry.status
            // Reconstruct extra classes
            if !timetableSlotIDs.contains(entry.slotID),
               let subject = subjects.first(where: { $0.id == entry.subjectID }) {
                dateAttendanceItems.append(IndexedSubject(
                    index: dateAttendanceItems.count,
                    subject: subject,
                    slotID: entry.slotID,
                    isExtra: true
                ))
            }
        }
    }

    func setDateAttendanceStatus(_ status: AttendanceStatus, for item: IndexedSubject) {
        if item.isExtra && status == .clear {
            withAnimation(.easeInOut(duration: 0.2)) {
                dateAttendanceItems.removeAll { $0.slotID == item.slotID }
                dateAttendanceEntries.removeValue(forKey: item.slotID)
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                dateAttendanceEntries[item.slotID] = status
            }
        }
        saveDateAttendance()
    }

    func addExtraClassForDate(_ subject: Subject) {
        let slotID = UUID()
        let newItem = IndexedSubject(
            index: dateAttendanceItems.count,
            subject: subject,
            slotID: slotID,
            isExtra: true
        )
        dateAttendanceItems.append(newItem)
        dateAttendanceEntries[slotID] = .present
        saveDateAttendance()
    }

    func isDutyLeaveForDate(subjectID: UUID) -> Bool {
        let dk = selectedDateKey
        return dutyLeaves.contains { dl in
            dl.coversDate(dk) && (dl.type == .fullDay || dl.subjectIDs.contains(subjectID))
        }
    }

    private func saveDateAttendance() {
        var allEntries = storage.loadEntries()
        let dk = selectedDateKey

        // Remove ALL entries for this date, then re-add current state
        allEntries.removeAll { $0.dateKey == dk }

        for item in dateAttendanceItems {
            let status = dateAttendanceEntries[item.slotID] ?? .clear
            guard status != .clear else { continue }
            let entry = AttendanceEntry(
                subjectID: item.subject.id,
                slotID: item.slotID,
                date: selectedDate,
                status: status
            )
            allEntries.append(entry)
        }

        storage.saveEntries(allEntries)
        entries = allEntries
    }
}
