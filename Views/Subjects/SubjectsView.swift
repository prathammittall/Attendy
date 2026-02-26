import SwiftUI

struct SubjectsView: View {
    @StateObject private var viewModel = SubjectsViewModel()
    @AppStorage("minAttendanceThreshold") private var threshold: Double = 0.75
    @State private var showAddSheet = false
    @State private var selectedSubject: Subject?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.subjects.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(viewModel.subjects) { subject in
                            Button {
                                selectedSubject = subject
                            } label: {
                                SubjectRow(subject: subject, viewModel: viewModel)
                            }
                            .listRowBackground(AppTheme.card)
                            .listRowSeparatorTint(AppTheme.separator)
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                viewModel.deleteSubject(viewModel.subjects[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Subjects")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddSubjectSheet(viewModel: viewModel)
                    .presentationDetents([.height(200)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedSubject) { subject in
                SubjectDetailSheet(subject: subject, viewModel: viewModel, threshold: threshold)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear { viewModel.load() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.accent.opacity(0.5))
            Text("No subjects yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Add your subjects to get started")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary)

            Button {
                showAddSheet = true
            } label: {
                Text("Add Subject")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(AppTheme.accent.opacity(0.2))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Subject Row

struct SubjectRow: View {
    let subject: Subject
    let viewModel: SubjectsViewModel
    @AppStorage("minAttendanceThreshold") private var threshold: Double = 0.75

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3)
                .fill(AppTheme.accentSubtle)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(subject.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                let total = viewModel.totalClasses(for: subject)
                if total == 0 {
                    Text("No records")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textTertiary)
                } else {
                    projectionLabel
                }
            }

            Spacer()

            let pct = viewModel.attendancePercentage(for: subject)
            if viewModel.totalClasses(for: subject) > 0 {
                Text("\(Int(pct * 100))%")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.percentageColor(pct))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var projectionLabel: some View {
        if let needed = viewModel.lecturesNeeded(for: subject, threshold: threshold) {
            Label("Attend \(needed) more to reach \(Int(threshold * 100))%", systemImage: "arrow.up.circle")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.statusAbsent)
        } else if let canMiss = viewModel.lecturesCanMiss(for: subject, threshold: threshold) {
            if canMiss == 0 {
                Label("1 absence will drop below \(Int(threshold * 100))%", systemImage: "exclamationmark.circle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.accentWarm)
            } else {
                Label("Can safely miss \(canMiss) \(canMiss == 1 ? "class" : "classes")", systemImage: "checkmark.circle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.accentSecondary)
            }
        } else {
            let total = viewModel.totalClasses(for: subject)
            Text("\(total) classes tracked")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.textTertiary)
        }
    }
}

// MARK: - Add Subject Sheet

struct AddSubjectSheet: View {
    @ObservedObject var viewModel: SubjectsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 16) {
                    TextField("Subject name", text: $name)
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(14)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                .stroke(AppTheme.separator, lineWidth: 1)
                        )

                    Button {
                        viewModel.addSubject(name: name)
                        dismiss()
                    } label: {
                        Text("Add")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.surface : AppTheme.accent.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                    .stroke(name.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.separator : AppTheme.accent.opacity(0.4), lineWidth: 1)
                            )
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("New Subject")
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

// MARK: - Subject Detail Sheet

struct SubjectDetailSheet: View {
    let subject: Subject
    let viewModel: SubjectsViewModel
    let threshold: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Attendance percentage
                    let pct = viewModel.attendancePercentage(for: subject)
                    VStack(spacing: 8) {
                        Text("\(Int(pct * 100))%")
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.percentageColor(pct))
                        Text("Attendance")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.top, 8)

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        StatTile(label: "Present", value: "\(viewModel.presentCount(for: subject))", color: AppTheme.statusPresent)
                        StatTile(label: "Absent", value: "\(viewModel.absentCount(for: subject))", color: AppTheme.statusAbsent)
                        StatTile(label: "Duty Leave", value: "\(viewModel.dutyLeaveCount(for: subject))", color: AppTheme.accentSubtle)
                    }
                    .padding(.horizontal, 20)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        StatTile(label: "Off / Holiday", value: "\(viewModel.offCount(for: subject))", color: AppTheme.statusOff)
                        StatTile(label: "Total Tracked", value: "\(viewModel.totalClasses(for: subject))", color: AppTheme.accent)
                    }
                    .padding(.horizontal, 20)

                    // Projection card
                    AttendanceProjectionCard(subject: subject, viewModel: viewModel, threshold: threshold)
                        .padding(.horizontal, 20)

                    // Delete
                    Button(role: .destructive) {
                        viewModel.deleteSubject(subject)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Subject")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.statusAbsent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.statusAbsent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle(subject.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }
}

// MARK: - Attendance Projection Card

struct AttendanceProjectionCard: View {
    let subject: Subject
    let viewModel: SubjectsViewModel
    let threshold: Double

    var body: some View {
        let pct = viewModel.attendancePercentage(for: subject)
        let total = viewModel.totalClasses(for: subject)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.accentWarm)
                Text("Attendance Goal — \(Int(threshold * 100))%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.4)
            }

            if total == 0 {
                Text("No attendance data yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textTertiary)
            } else if let needed = viewModel.lecturesNeeded(for: subject, threshold: threshold) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.statusAbsent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Attend \(needed) more \(needed == 1 ? "class" : "classes")")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("You are at \(Int(pct * 100))%. You need to attend \(needed) consecutive \(needed == 1 ? "class" : "classes") without any absence to reach \(Int(threshold * 100))%.")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else if let canMiss = viewModel.lecturesCanMiss(for: subject, threshold: threshold) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: canMiss == 0 ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(canMiss == 0 ? AppTheme.accentWarm : AppTheme.statusPresent)
                    VStack(alignment: .leading, spacing: 4) {
                        if canMiss == 0 {
                            Text("Next absence risks your goal")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("You are at \(Int(pct * 100))% but have too few classes recorded. Missing just 1 will drop you below \(Int(threshold * 100))%. Keep attending to build a buffer.")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("Can safely miss \(canMiss) \(canMiss == 1 ? "class" : "classes")")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("You are at \(Int(pct * 100))%. You can afford to miss \(canMiss) more \(canMiss == 1 ? "class" : "classes") and still stay at or above \(Int(threshold * 100))%.")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                .stroke(AppTheme.accentWarm.opacity(0.35), lineWidth: 1)
        )
    }
}

struct StatTile: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
