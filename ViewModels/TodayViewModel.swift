import SwiftUI

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var todaySubjects: [IndexedSubject] = []
    @Published var entries: [UUID: AttendanceStatus] = [:]   // keyed by slotID
    @Published var dutyLeaves: [DutyLeave] = []
    @Published var subjects: [Subject] = []

    private let storage = LocalStorageManager.shared

    func load() {
        subjects = storage.loadSubjects()
        let timetable = storage.loadTimetable()
        let today = Weekday.today()
        let slots = timetable.slots(for: today)

        todaySubjects = slots.enumerated().compactMap { index, slot in
            guard let subject = subjects.first(where: { $0.id == slot.subjectID }) else { return nil }
            return IndexedSubject(index: index, subject: subject, slotID: slot.id)
        }

        // Load today's entries, keyed by slotID
        let allEntries = storage.loadEntries()
        let todayKey = todayDateKey()
        entries = [:]
        for entry in allEntries where entry.dateKey == todayKey {
            entries[entry.slotID] = entry.status
        }

        dutyLeaves = storage.loadDutyLeaves()
    }

    /// Duty leaves that apply to today
    var todayDutyLeaves: [DutyLeave] {
        let todayKey = todayDateKey()
        return dutyLeaves.filter { $0.coversDate(todayKey) }
    }

    /// Check if a subject slot is covered by a DL today
    func isDutyLeave(for item: IndexedSubject) -> Bool {
        let todayKey = todayDateKey()
        return dutyLeaves.contains { dl in
            dl.coversDate(todayKey) && (dl.type == .fullDay || dl.subjectIDs.contains(item.subject.id))
        }
    }

    func addDutyLeave(_ dl: DutyLeave) {
        dutyLeaves.append(dl)
        storage.saveDutyLeaves(dutyLeaves)
    }

    func deleteDutyLeave(_ dl: DutyLeave) {
        dutyLeaves.removeAll { $0.id == dl.id }
        storage.saveDutyLeaves(dutyLeaves)
    }

    func status(for item: IndexedSubject) -> AttendanceStatus {
        entries[item.slotID] ?? .clear
    }

    func setStatus(_ status: AttendanceStatus, for item: IndexedSubject) {
        withAnimation(.easeInOut(duration: 0.2)) {
            entries[item.slotID] = status
        }
        saveEntries()
    }

    private func saveEntries() {
        var allEntries = storage.loadEntries()
        let todayKey = todayDateKey()
        let trackedSlotIDs = Set(todaySubjects.map { $0.slotID })

        // Remove existing entries for today's tracked slots
        allEntries.removeAll { entry in
            entry.dateKey == todayKey && trackedSlotIDs.contains(entry.slotID)
        }

        // Save current state — only non-clear entries
        let today = Date()
        for item in todaySubjects {
            let status = entries[item.slotID] ?? .clear
            guard status != .clear else { continue }
            let entry = AttendanceEntry(subjectID: item.subject.id, slotID: item.slotID, date: today, status: status)
            allEntries.append(entry)
        }

        storage.saveEntries(allEntries)
    }

    private func todayDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}