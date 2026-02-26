import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    @State private var showDutyLeaveSheet = false
    @State private var showAddExtraClassSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.todaySubjects.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            headerInfo

                            // Show today's duty leaves
                            if !viewModel.todayDutyLeaves.isEmpty {
                                todayDLSection
                            }

                            ForEach(viewModel.todaySubjects) { item in
                                let hasDL = viewModel.isDutyLeave(for: item)
                                SubjectAttendanceCard(
                                    subject: item.subject,
                                    status: viewModel.status(for: item),
                                    hasDutyLeave: hasDL,
                                    isExtra: item.isExtra,
                                    onStatusChange: { status in
                                        viewModel.setStatus(status, for: item)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 0) {
                        Text("A")
                            .font(.system(size: 26, weight: .black, design: .serif))
                            .foregroundStyle(AppTheme.accent)
                        Text("ttendy")
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showAddExtraClassSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Extra")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(AppTheme.accentSecondary)
                        }
                        .disabled(viewModel.subjects.isEmpty)

                        Button {
                            showDutyLeaveSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("DL")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(AppTheme.accentSubtle)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddExtraClassSheet) {
                AddExtraClassSheet(viewModel: viewModel)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showDutyLeaveSheet) {
                viewModel.load()  // refresh after adding DL
            } content: {
                AddDutyLeaveSheet(viewModel: viewModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear { viewModel.load() }
        }
    }

    private var headerInfo: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Weekday.today().fullName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                Text(formattedDate())
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Spacer()
            Text("\(viewModel.todaySubjects.count) subjects")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.accent.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.accent.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.accent.opacity(0.5))
            Text("No subjects today")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Set up your timetable to see\ntoday's subjects here")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Today DL Section

    private var todayDLSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.todayDutyLeaves) { dl in
                HStack(spacing: 10) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.accentSubtle)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(dl.eventName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        HStack(spacing: 6) {
                            Text(dl.type.label)
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.accentSubtle)
                            Text("•")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.textTertiary)
                            Text(dl.dateRangeLabel)
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.textSecondary)
                            if !dl.clubName.isEmpty {
                                Text("• \(dl.clubName)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }

                    Spacer()

                    Text("Duty Leave")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.accentSubtle.opacity(0.3))
                        .clipShape(Capsule())

                    Button {
                        viewModel.deleteDutyLeave(dl)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.statusAbsent.opacity(0.7))
                    }
                    .buttonStyle(.plain)
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
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: Date())
    }
}

// MARK: - Subject Attendance Card

struct SubjectAttendanceCard: View {
    let subject: Subject
    let status: AttendanceStatus
    let hasDutyLeave: Bool
    let isExtra: Bool
    let onStatusChange: (AttendanceStatus) -> Void

    init(subject: Subject, status: AttendanceStatus, hasDutyLeave: Bool, isExtra: Bool = false, onStatusChange: @escaping (AttendanceStatus) -> Void) {
        self.subject = subject
        self.status = status
        self.hasDutyLeave = hasDutyLeave
        self.isExtra = isExtra
        self.onStatusChange = onStatusChange
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(subject.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                if isExtra {
                    Text("Extra")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.accentSecondary.opacity(0.4))
                        .clipShape(Capsule())
                }

                if hasDutyLeave {
                    Text("Duty Leave")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.accentSubtle.opacity(0.4))
                        .clipShape(Capsule())
                }

                Spacer()
                Text(status.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.statusColor(for: status).opacity(0.8))
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                ForEach(AttendanceStatus.allCases, id: \.self) { s in
                    StatusButton(
                        status: s,
                        isSelected: status == s,
                        action: { onStatusChange(s) }
                    )
                }
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(
                    status == .present ? AppTheme.statusPresent.opacity(0.3) :
                    status == .absent ? AppTheme.statusAbsent.opacity(0.3) :
                    AppTheme.separator,
                    lineWidth: 1
                )
        )
    }
}

struct StatusButton: View {
    let status: AttendanceStatus
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: status.icon)
                    .font(.system(size: 18))
                Text(status.label)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textTertiary)
            .background(isSelected ? AppTheme.statusColor(for: status) : AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                    .stroke(isSelected ? AppTheme.statusColor(for: status) : AppTheme.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Duty Leave Sheet

struct AddDutyLeaveSheet: View {
    @ObservedObject var viewModel: TodayViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var eventName = ""
    @State private var leaveType: DutyLeaveType = .fullDay
    @State private var clubName = ""
    @State private var remarks = ""
    @State private var selectedSubjectIDs: Set<UUID> = []
    @State private var startDate = Date()
    @State private var endDate = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Date range picker
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Event Dates")
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("From")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(AppTheme.textTertiary)
                                    DatePicker("", selection: $startDate, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .tint(AppTheme.accentSubtle)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                        .onChange(of: startDate) { newVal in
                                            if endDate < newVal { endDate = newVal }
                                        }
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                        .stroke(AppTheme.separator, lineWidth: 1)
                                )

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppTheme.textTertiary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("To")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(AppTheme.textTertiary)
                                    DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .tint(AppTheme.accentSubtle)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                        .stroke(AppTheme.separator, lineWidth: 1)
                                )
                            }

                            // Day count
                            let days = dayCount
                            if days > 1 {
                                Text("\(days) days")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.accentSubtle)
                                    .padding(.top, 2)
                            }
                        }

                        // Event name
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Event Name *")
                            styledTextField("e.g. Tech Fest, Workshop...", text: $eventName)
                        }

                        // DL Type picker
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Leave Type")
                            HStack(spacing: 10) {
                                ForEach(DutyLeaveType.allCases, id: \.self) { type in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            leaveType = type
                                        }
                                    } label: {
                                        Text(type.label)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(leaveType == type ? AppTheme.textPrimary : AppTheme.textSecondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(leaveType == type ? AppTheme.accentSubtle.opacity(0.25) : AppTheme.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(leaveType == type ? AppTheme.accentSubtle.opacity(0.5) : AppTheme.separator, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }

                        // Subject selection (only for per-subject)
                        if leaveType == .perSubject {
                            VStack(alignment: .leading, spacing: 8) {
                                sectionLabel("Select Subjects")
                                if viewModel.subjects.isEmpty {
                                    Text("No subjects available")
                                        .font(.system(size: 13))
                                        .foregroundStyle(AppTheme.textTertiary)
                                        .padding(12)
                                } else {
                                    VStack(spacing: 6) {
                                        ForEach(viewModel.subjects) { subject in
                                            Button {
                                                if selectedSubjectIDs.contains(subject.id) {
                                                    selectedSubjectIDs.remove(subject.id)
                                                } else {
                                                    selectedSubjectIDs.insert(subject.id)
                                                }
                                            } label: {
                                                HStack(spacing: 10) {
                                                    Image(systemName: selectedSubjectIDs.contains(subject.id) ? "checkmark.circle.fill" : "circle")
                                                        .font(.system(size: 18))
                                                        .foregroundStyle(selectedSubjectIDs.contains(subject.id) ? AppTheme.accentSubtle : AppTheme.textTertiary)

                                                    Text(subject.name)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundStyle(AppTheme.textPrimary)

                                                    Spacer()
                                                }
                                                .padding(10)
                                                .background(selectedSubjectIDs.contains(subject.id) ? AppTheme.accentSubtle.opacity(0.1) : AppTheme.card)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(selectedSubjectIDs.contains(subject.id) ? AppTheme.accentSubtle.opacity(0.3) : AppTheme.separator, lineWidth: 1)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Club name (optional)
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Club / Organiser (Optional)")
                            styledTextField("e.g. Coding Club, IEEE...", text: $clubName)
                        }

                        // Remarks (optional)
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("Remarks (Optional)")
                            ZStack(alignment: .topLeading) {
                                if remarks.isEmpty {
                                    Text("Any additional notes...")
                                        .font(.system(size: 14))
                                        .foregroundStyle(AppTheme.textTertiary)
                                        .padding(.top, 14)
                                        .padding(.leading, 14)
                                }
                                TextEditor(text: $remarks)
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 60)
                                    .padding(8)
                            }
                            .background(AppTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                    .stroke(AppTheme.separator, lineWidth: 1)
                            )
                        }

                        // Add button
                        Button {
                            addDutyLeave()
                        } label: {
                            Text("Add Duty Leave")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(canSave ? AppTheme.accentSubtle.opacity(0.25) : AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                        .stroke(canSave ? AppTheme.accentSubtle.opacity(0.5) : AppTheme.separator, lineWidth: 1)
                                )
                        }
                        .disabled(!canSave)

                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Duty Leave")
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

    private var canSave: Bool {
        let trimmed = eventName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        if leaveType == .perSubject && selectedSubjectIDs.isEmpty { return false }
        return true
    }

    private func addDutyLeave() {
        let dl = DutyLeave(
            startDate: startDate,
            endDate: endDate,
            eventName: eventName.trimmingCharacters(in: .whitespaces),
            type: leaveType,
            clubName: clubName.trimmingCharacters(in: .whitespaces),
            remarks: remarks.trimmingCharacters(in: .whitespacesAndNewlines),
            subjectIDs: leaveType == .perSubject ? Array(selectedSubjectIDs) : []
        )
        viewModel.addDutyLeave(dl)
        dismiss()
    }

    private var dayCount: Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startDate)
        let end = cal.startOfDay(for: endDate)
        return max(1, (cal.dateComponents([.day], from: start, to: end).day ?? 0) + 1)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppTheme.textSecondary)
            .textCase(.uppercase)
            .tracking(0.4)
    }

    private func styledTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 14))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(13)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )
    }
}

// MARK: - Add Extra Class Sheet

struct AddExtraClassSheet: View {
    @ObservedObject var viewModel: TodayViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.subjects.isEmpty {
                    VStack(spacing: 12) {
                        Text("No subjects yet")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("Add subjects in the Subjects tab first")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                } else {
                    List {
                        ForEach(viewModel.subjects) { subject in
                            Button {
                                withAnimation {
                                    viewModel.addExtraClass(subject)
                                }
                                dismiss()
                            } label: {
                                HStack {
                                    Text(subject.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(AppTheme.accentSecondary)
                                }
                            }
                            .listRowBackground(AppTheme.card)
                            .listRowSeparatorTint(AppTheme.separator)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Add Extra Class")
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
}
