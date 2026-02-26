import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var entries: [AttendanceEntry] = []
    @Published var timetable: Timetable = Timetable()
    @Published var events: [CalendarEvent] = []
    @Published var dutyLeaves: [DutyLeave] = []

    private let storage = LocalStorageManager.shared

    func load() {
        subjects = storage.loadSubjects()
        entries = storage.loadEntries()
        timetable = storage.loadTimetable()
        events = storage.loadEvents()
        dutyLeaves = storage.loadDutyLeaves()
    }

    // MARK: - Overall Stats

    var totalSubjects: Int { subjects.count }

    var totalClassesTracked: Int {
        entries.filter { $0.status != .clear }.count
    }

    var totalPresent: Int {
        entries.filter { $0.status == .present }.count
    }

    var totalAbsent: Int {
        entries.filter { $0.status == .absent }.count
    }

    var totalOff: Int {
        entries.filter { $0.status == .off }.count
    }

    var totalDutyLeaves: Int {
        dutyLeaves.count
    }

    var totalEvents: Int {
        events.count
    }

    var overallAttendance: Double {
        let present = entries.filter { $0.status == .present }.count
        let absent = entries.filter { $0.status == .absent }.count
        let total = present + absent
        guard total > 0 else { return 0 }
        return Double(present) / Double(total)
    }

    // MARK: - Streaks

    var currentStreak: Int {
        guard !entries.isEmpty else { return 0 }

        let sorted = entries
            .filter { $0.status == .present || $0.status == .absent }
            .sorted { $0.date > $1.date }

        var streak = 0
        for entry in sorted {
            if entry.status == .present {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    var longestStreak: Int {
        guard !entries.isEmpty else { return 0 }

        let sorted = entries
            .filter { $0.status == .present || $0.status == .absent }
            .sorted { $0.date < $1.date }

        var longest = 0
        var current = 0
        for entry in sorted {
            if entry.status == .present {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
        }
        return longest
    }

    // MARK: - Days Active

    var uniqueDaysTracked: Int {
        Set(entries.map { $0.dateKey }).count
    }

    var daysSinceFirstEntry: Int {
        guard let earliest = entries.map({ $0.date }).min() else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: earliest, to: Date()).day ?? 0)
    }

    // MARK: - Best Subject

    var bestSubject: (name: String, percentage: Double)? {
        guard !subjects.isEmpty else { return nil }

        var best: (String, Double)? = nil
        for subject in subjects {
            let relevant = entries.filter {
                $0.subjectID == subject.id && ($0.status == .present || $0.status == .absent)
            }
            guard !relevant.isEmpty else { continue }
            let present = relevant.filter { $0.status == .present }.count
            let pct = Double(present) / Double(relevant.count)
            if best == nil || pct > best!.1 {
                best = (subject.name, pct)
            }
        }
        return best
    }

    var worstSubject: (name: String, percentage: Double)? {
        guard !subjects.isEmpty else { return nil }

        var worst: (String, Double)? = nil
        for subject in subjects {
            let relevant = entries.filter {
                $0.subjectID == subject.id && ($0.status == .present || $0.status == .absent)
            }
            guard !relevant.isEmpty else { continue }
            let present = relevant.filter { $0.status == .present }.count
            let pct = Double(present) / Double(relevant.count)
            if worst == nil || pct < worst!.1 {
                worst = (subject.name, pct)
            }
        }
        return worst
    }

    // MARK: - Timetable Stats

    var totalWeeklySlots: Int {
        Weekday.allCases.reduce(0) { $0 + timetable.slots(for: $1).count }
    }

    var activeDays: Int {
        Weekday.allCases.filter { !timetable.slots(for: $0).isEmpty }.count
    }

    // MARK: - Reset

    func resetAllAttendance() {
        entries = []
        storage.saveEntries(entries)
    }

    func resetEverything() {
        subjects = []
        entries = []
        timetable = Timetable()
        events = []
        dutyLeaves = []
        storage.saveSubjects(subjects)
        storage.saveEntries(entries)
        storage.saveTimetable(timetable)
        storage.saveEvents(events)
        storage.saveDutyLeaves(dutyLeaves)
    }
}
