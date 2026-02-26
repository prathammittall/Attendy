import Foundation

@MainActor
final class LocalStorageManager {
    static let shared = LocalStorageManager()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.outputFormatting = .prettyPrinted
        // Ensure storage directory exists
        try? FileManager.default.createDirectory(at: storageDirectory,
                                                  withIntermediateDirectories: true)
    }

    // MARK: - Storage directory

    private var storageDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AttendyData", isDirectory: true)
    }

    private func fileURL(named name: String) -> URL {
        storageDirectory.appendingPathComponent("\(name).json")
    }

    // MARK: - Generic save / load

    private func save<T: Encodable>(_ value: T, to name: String) {
        do {
            let data = try encoder.encode(value)
            try data.write(to: fileURL(named: name), options: .atomic)
        } catch {
            print("[Storage] Failed to save \(name): \(error)")
        }
    }

    private func load<T: Decodable>(_ type: T.Type, from name: String) -> T? {
        let url = fileURL(named: name)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(type, from: data)
        } catch {
            print("[Storage] Failed to load \(name): \(error)")
            return nil
        }
    }

    // MARK: - Subjects

    func saveSubjects(_ subjects: [Subject]) {
        save(subjects, to: "subjects")
    }

    func loadSubjects() -> [Subject] {
        load([Subject].self, from: "subjects") ?? []
    }

    // MARK: - Timetable

    func saveTimetable(_ timetable: Timetable) {
        save(timetable, to: "timetable")
    }

    func loadTimetable() -> Timetable {
        load(Timetable.self, from: "timetable") ?? Timetable()
    }

    // MARK: - Attendance Entries

    func saveEntries(_ entries: [AttendanceEntry]) {
        save(entries, to: "entries")
    }

    func loadEntries() -> [AttendanceEntry] {
        load([AttendanceEntry].self, from: "entries") ?? []
    }

    // MARK: - Calendar Events

    func saveEvents(_ events: [CalendarEvent]) {
        save(events, to: "events")
    }

    func loadEvents() -> [CalendarEvent] {
        load([CalendarEvent].self, from: "events") ?? []
    }

    // MARK: - Duty Leaves

    func saveDutyLeaves(_ dutyLeaves: [DutyLeave]) {
        save(dutyLeaves, to: "dutyLeaves")
    }

    func loadDutyLeaves() -> [DutyLeave] {
        load([DutyLeave].self, from: "dutyLeaves") ?? []
    }
}
