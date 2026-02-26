import SwiftUI

@MainActor
final class SubjectsViewModel: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var entries: [AttendanceEntry] = []
    @Published var dutyLeaves: [DutyLeave] = []

    private let storage = LocalStorageManager.shared

    func load() {
        subjects = storage.loadSubjects()
        entries = storage.loadEntries()
        dutyLeaves = storage.loadDutyLeaves()
    }

    func addSubject(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let subject = Subject(name: trimmed)
        subjects.append(subject)
        storage.saveSubjects(subjects)
    }

    func deleteSubject(_ subject: Subject) {
        subjects.removeAll { $0.id == subject.id }
        storage.saveSubjects(subjects)

        // Also remove entries and timetable references
        entries.removeAll { $0.subjectID == subject.id }
        storage.saveEntries(entries)

        var timetable = storage.loadTimetable()
        for day in Weekday.allCases {
            var slots = timetable.slots(for: day)
            slots.removeAll { $0.subjectID == subject.id }
            timetable.setSlots(for: day, slots: slots)
        }
        storage.saveTimetable(timetable)
    }

    func totalClasses(for subject: Subject) -> Int {
        entries.filter { $0.subjectID == subject.id && $0.status != .clear }.count
    }

    func presentCount(for subject: Subject) -> Int {
        entries.filter { $0.subjectID == subject.id && $0.status == .present }.count
    }

    func absentCount(for subject: Subject) -> Int {
        entries.filter { $0.subjectID == subject.id && $0.status == .absent }.count
    }

    func offCount(for subject: Subject) -> Int {
        entries.filter { $0.subjectID == subject.id && $0.status == .off }.count
    }

    /// Returns the set of date keys where a duty leave applies to this subject,
    /// checking that the subject actually has a timetable slot on that weekday.
    private func dutyLeaveDateKeys(for subject: Subject) -> Set<String> {
        let timetable = storage.loadTimetable()
        var dlDates = Set<String>()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for dl in dutyLeaves {
            let allKeys = dl.dateKeys
            let isRelevant: Bool
            switch dl.type {
            case .fullDay:
                isRelevant = true
            case .perSubject:
                isRelevant = dl.subjectIDs.contains(subject.id)
            }
            guard isRelevant else { continue }

            for key in allKeys {
                if let date = formatter.date(from: key) {
                    let weekdayNum = Calendar.current.component(.weekday, from: date)
                    if let weekday = Weekday(rawValue: weekdayNum) {
                        if timetable.slots(for: weekday).contains(where: { $0.subjectID == subject.id }) {
                            dlDates.insert(key)
                        }
                    }
                }
            }
        }
        return dlDates
    }

    /// Number of duty leave days that apply to this subject
    func dutyLeaveCount(for subject: Subject) -> Int {
        dutyLeaveDateKeys(for: subject).count
    }

    func attendancePercentage(for subject: Subject) -> Double {
        let dlDates = dutyLeaveDateKeys(for: subject)
        // Exclude entries on DL dates to prevent double-counting
        let relevantEntries = entries.filter {
            $0.subjectID == subject.id &&
            ($0.status == .present || $0.status == .absent) &&
            !dlDates.contains($0.dateKey)
        }
        let dlCount = dlDates.count
        let present = relevantEntries.filter { $0.status == .present }.count + dlCount
        let total = relevantEntries.count + dlCount
        guard total > 0 else { return 0 }
        return Double(present) / Double(total)
    }

    /// Number of consecutive present classes needed to reach `threshold`.
    /// Returns nil if already at/above threshold or no data.
    func lecturesNeeded(for subject: Subject, threshold: Double) -> Int? {
        let dlDates = dutyLeaveDateKeys(for: subject)
        let relevantEntries = entries.filter {
            $0.subjectID == subject.id &&
            ($0.status == .present || $0.status == .absent) &&
            !dlDates.contains($0.dateKey)
        }
        let dlCount = dlDates.count
        let p = Double(relevantEntries.filter { $0.status == .present }.count + dlCount)
        let total = Double(relevantEntries.count + dlCount)
        guard total > 0 else { return nil }
        let current = p / total
        guard current < threshold else { return nil }
        // At 100% goal with any absence, recovery is impossible
        guard threshold < 1.0 else { return nil }
        let n = (threshold * total - p) / (1.0 - threshold)
        return Int(ceil(n))
    }

    /// Number of classes that can be missed while staying at/above `threshold`.
    /// Returns nil if below threshold or no data.
    func lecturesCanMiss(for subject: Subject, threshold: Double) -> Int? {
        let dlDates = dutyLeaveDateKeys(for: subject)
        let relevantEntries = entries.filter {
            $0.subjectID == subject.id &&
            ($0.status == .present || $0.status == .absent) &&
            !dlDates.contains($0.dateKey)
        }
        let dlCount = dlDates.count
        let p = Double(relevantEntries.filter { $0.status == .present }.count + dlCount)
        let total = Double(relevantEntries.count + dlCount)
        guard total > 0 else { return nil }
        let current = p / total
        guard current >= threshold else { return nil }
        guard threshold > 0 else { return nil }
        let n = (p - threshold * total) / threshold
        let result = Int(floor(n))
        return result >= 0 ? result : 0
    }
}
