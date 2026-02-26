import SwiftUI

// Wraps a timetable slot so ForEach can safely handle the same subject appearing
// multiple times — slotID is unique per slot even for duplicate subjects.
struct IndexedSubject: Identifiable {
    let index: Int
    let subject: Subject
    let slotID: UUID        // the slot's own UUID
    var id: UUID { slotID }
}

@MainActor
final class TimetableViewModel: ObservableObject {
    @Published var subjects: [Subject] = []
    @Published var timetable: Timetable = Timetable()
    @Published var selectedDay: Weekday = .monday

    private let storage = LocalStorageManager.shared

    func load() {
        subjects = storage.loadSubjects()
        timetable = storage.loadTimetable()
    }

    func subjectsForSelectedDay() -> [IndexedSubject] {
        let slots = timetable.slots(for: selectedDay)
        return slots.enumerated().compactMap { index, slot in
            guard let subject = subjects.first(where: { $0.id == slot.subjectID }) else { return nil }
            return IndexedSubject(index: index, subject: subject, slotID: slot.id)
        }
    }

    func availableSubjectsForSelectedDay() -> [Subject] {
        return subjects
    }

    func addSubjectToDay(_ subject: Subject) {
        var slots = timetable.slots(for: selectedDay)
        slots.append(TimetableSlot(subjectID: subject.id))
        timetable.setSlots(for: selectedDay, slots: slots)
        storage.saveTimetable(timetable)
    }

    func removeSubjectFromDay(at index: Int) {
        var slots = timetable.slots(for: selectedDay)
        guard index >= 0 && index < slots.count else { return }
        slots.remove(at: index)
        timetable.setSlots(for: selectedDay, slots: slots)
        storage.saveTimetable(timetable)
    }

    func moveSubject(from source: IndexSet, to destination: Int) {
        var slots = timetable.slots(for: selectedDay)
        slots.move(fromOffsets: source, toOffset: destination)
        timetable.setSlots(for: selectedDay, slots: slots)
        storage.saveTimetable(timetable)
    }
}
