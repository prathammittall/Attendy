import SwiftUI

struct CalendarTabView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var displayedMonth: Date = Date()
    @State private var showAddEvent = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let dayLabels = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        calendarHeader
                        calendarGrid
                        selectedDateSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddEvent = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Event")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(AppTheme.accentWarm)
                    }
                }
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventSheet(viewModel: viewModel)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .onAppear { viewModel.load() }
        }
    }

    // MARK: - Calendar Header

    private var calendarHeader: some View {
        HStack {
            Button {
                withAnimation { changeMonth(by: -1) }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            Text(monthYearString(displayedMonth))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            Button {
                withAnimation { changeMonth(by: 1) }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            let days = daysInMonth()
            let activity = viewModel.datesWithActivity(in: displayedMonth)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        let isSelected = calendar.isDate(date, inSameDayAs: viewModel.selectedDate)
                        let isToday = calendar.isDateInToday(date)
                        let key = dateKey(for: date)
                        let hasEntries = activity.entries.contains(key)
                        let hasEvents = activity.events.contains(key)

                        Button {
                            viewModel.selectedDate = date
                        } label: {
                            VStack(spacing: 3) {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                                    .foregroundStyle(
                                        isSelected ? AppTheme.textPrimary :
                                        isToday ? AppTheme.accent :
                                        AppTheme.textSecondary
                                    )
                                // indicator dots row
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(hasEntries ? AppTheme.accent : Color.clear)
                                        .frame(width: 4, height: 4)
                                    Circle()
                                        .fill(hasEvents ? AppTheme.accentWarm : Color.clear)
                                        .frame(width: 4, height: 4)
                                }
                            }
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                            .background(
                                isSelected ? AppTheme.accent.opacity(0.25) :
                                isToday ? AppTheme.accent.opacity(0.08) : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? AppTheme.accent.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(AppTheme.accent).frame(width: 6, height: 6)
                    Text("Attendance").font(.system(size: 10)).foregroundStyle(AppTheme.textTertiary)
                }
                HStack(spacing: 4) {
                    Circle().fill(AppTheme.accentWarm).frame(width: 6, height: 6)
                    Text("Event").font(.system(size: 10)).foregroundStyle(AppTheme.textTertiary)
                }
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }

    // MARK: - Selected Date Section

    private var selectedDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(fullDateString(viewModel.selectedDate))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                Spacer()
                Button {
                    showAddEvent = true
                } label: {
                    Label("Add Event", systemImage: "plus.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.accentWarm)
                }
            }
            .padding(.horizontal, 4)

            // Events for this day
            let dayEvents = viewModel.eventsForSelectedDate()
            if !dayEvents.isEmpty {
                VStack(spacing: 8) {
                    ForEach(dayEvents) { event in
                        EventCard(event: event) {
                            viewModel.deleteEvent(event)
                        }
                    }
                }
            }

            // Duty Leaves for this day
            let dayDLs = viewModel.dutyLeavesForSelectedDate()
            if !dayDLs.isEmpty {
                VStack(spacing: 8) {
                    ForEach(dayDLs) { dl in
                        DutyLeaveCard(dutyLeave: dl) {
                            viewModel.deleteDutyLeave(dl)
                        }
                    }
                }
            }

            // Attendance records for this day
            let dayEntries = viewModel.entriesForSelectedDate()
            if dayEntries.isEmpty && dayEvents.isEmpty && dayDLs.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.textTertiary)
                        Text("No records or events")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(AppTheme.separator, lineWidth: 1)
                )
            } else if !dayEntries.isEmpty {
                VStack(spacing: 8) {
                    ForEach(dayEntries, id: \.0.id) { (subject, status) in
                        HStack(spacing: 12) {
                            Image(systemName: status.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.statusColor(for: status))
                                .frame(width: 24)

                            Text(subject.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppTheme.textPrimary)

                            Spacer()

                            Text(status.label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppTheme.statusColor(for: status).opacity(0.8))
                                .clipShape(Capsule())
                        }
                        .padding(12)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                .stroke(AppTheme.separator, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func daysInMonth() -> [Date?] {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }

        var weekday = calendar.component(.weekday, from: firstDay)
        weekday = (weekday + 5) % 7

        var days: [Date?] = Array(repeating: nil, count: weekday)
        for day in range {
            var comp = components
            comp.day = day
            days.append(calendar.date(from: comp))
        }
        return days
    }

    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func fullDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: date)
    }

    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Event Card

struct EventCard: View {
    let event: CalendarEvent
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "star.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.accentWarm)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    if !event.remarks.isEmpty {
                        Text(event.remarks)
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.statusAbsent.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(AppTheme.accentWarm.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                .stroke(AppTheme.accentWarm.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Add Event Sheet

struct AddEventSheet: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var remarks = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 14) {
                    // Date label
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(AppTheme.accent)
                        Text(dateLabel)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 4)

                    TextField("Event title", text: $title)
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(13)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                .stroke(title.isEmpty ? AppTheme.separator : AppTheme.accentWarm.opacity(0.4), lineWidth: 1)
                        )

                    ZStack(alignment: .topLeading) {
                        if remarks.isEmpty {
                            Text("Remarks (optional)")
                                .font(.system(size: 15))
                                .foregroundStyle(AppTheme.textTertiary)
                                .padding(.top, 14)
                                .padding(.leading, 14)
                        }
                        TextEditor(text: $remarks)
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 80)
                            .padding(8)
                    }
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                            .stroke(AppTheme.separator, lineWidth: 1)
                    )

                    Button {
                        let trimmed = title.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        viewModel.addEvent(title: trimmed, remarks: remarks.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    } label: {
                        Text("Add Event")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(title.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.surface : AppTheme.accentWarm.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                    .stroke(title.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.separator : AppTheme.accentWarm.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: viewModel.selectedDate)
    }
}

// MARK: - Duty Leave Card

struct DutyLeaveCard: View {
    let dutyLeave: DutyLeave
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.accentSubtle)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(dutyLeave.eventName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("DL")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(AppTheme.accentSubtle.opacity(0.4))
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 6) {
                        Text(dutyLeave.type.label)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.accentSubtle)
                        if !dutyLeave.clubName.isEmpty {
                            Text("• \(dutyLeave.clubName)")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    if !dutyLeave.remarks.isEmpty {
                        Text(dutyLeave.remarks)
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.statusAbsent.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(AppTheme.accentSubtle.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                .stroke(AppTheme.accentSubtle.opacity(0.25), lineWidth: 1)
        )
    }
}
