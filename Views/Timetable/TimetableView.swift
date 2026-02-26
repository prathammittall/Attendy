import SwiftUI

struct TimetableView: View {
    @StateObject private var viewModel = TimetableViewModel()
    @State private var showAddSubject = false

    private let weekdays: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Day picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(weekdays, id: \.self) { day in
                                DayPill(
                                    day: day,
                                    isSelected: viewModel.selectedDay == day,
                                    action: { viewModel.selectedDay = day }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    Rectangle()
                        .fill(AppTheme.separator)
                        .frame(height: 1)

                    // Subject list for selected day
                    let daySubjects = viewModel.subjectsForSelectedDay()
                    if daySubjects.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundStyle(AppTheme.accent.opacity(0.4))
                            Text("No subjects on \(viewModel.selectedDay.fullName)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                            if viewModel.subjects.isEmpty {
                                Text("Add subjects in the Subjects tab first")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(daySubjects) { item in
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(AppTheme.accentSecondary)
                                        .frame(width: 4, height: 32)

                                    Text(item.subject.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(AppTheme.textPrimary)

                                    Spacer()

                                    Button {
                                        withAnimation {
                                            viewModel.removeSubjectFromDay(at: item.index)
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle")
                                            .font(.system(size: 18))
                                            .foregroundStyle(AppTheme.statusAbsent)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 4)
                                .listRowBackground(AppTheme.card)
                                .listRowSeparatorTint(AppTheme.separator)
                            }
                            .onMove { source, dest in
                                viewModel.moveSubject(from: source, to: dest)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Timetable")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSubject = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .disabled(viewModel.availableSubjectsForSelectedDay().isEmpty)
                }
            }
            .sheet(isPresented: $showAddSubject) {
                AddSubjectToDay(viewModel: viewModel)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .onAppear { viewModel.load() }
        }
    }
}

// MARK: - Day Pill

struct DayPill: View {
    let day: Weekday
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(day.shortName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textTertiary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.accent.opacity(0.2) : AppTheme.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? AppTheme.accent.opacity(0.5) : AppTheme.separator, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Subject to Day Sheet

struct AddSubjectToDay: View {
    @ObservedObject var viewModel: TimetableViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                let available = viewModel.availableSubjectsForSelectedDay()
                if available.isEmpty {
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
                        ForEach(available) { subject in
                            Button {
                                withAnimation {
                                    viewModel.addSubjectToDay(subject)
                                }
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
            .navigationTitle("Add to \(viewModel.selectedDay.fullName)")
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
