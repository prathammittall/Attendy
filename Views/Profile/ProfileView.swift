import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @AppStorage("minAttendanceThreshold") private var threshold: Double = 0.75
    @AppStorage("studentName") private var studentName: String = "Student"

    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showResetAttendanceAlert = false
    @State private var showResetAllAlert = false
    @State private var ringAnimation: CGFloat = 0
    @State private var selectedAvatarIcon: String = "person.fill"

    private let avatarIcons = [
        "person.fill", "graduationcap.fill", "brain.head.profile",
        "star.fill", "book.fill", "pencil.and.ruler.fill"
    ]

    private var thresholdPercent: Binding<Double> {
        Binding(
            get: { threshold * 100 },
            set: { threshold = $0 / 100 }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        avatarHeader
                        overallAttendanceRing
                        quickStatsGrid
                        streaksCard
                        bestWorstCard
                        attendanceSettingsCard
                        dataManagementCard
                        infoCard
                        appInfoFooter
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                viewModel.load()
                withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                    ringAnimation = CGFloat(viewModel.overallAttendance)
                }
            }
            .alert("Reset Attendance", isPresented: $showResetAttendanceAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    viewModel.resetAllAttendance()
                    withAnimation { ringAnimation = 0 }
                }
            } message: {
                Text("This will delete all attendance records but keep your subjects and timetable. This cannot be undone.")
            }
            .alert("Reset Everything", isPresented: $showResetAllAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    viewModel.resetEverything()
                    withAnimation { ringAnimation = 0 }
                }
            } message: {
                Text("This will permanently delete ALL data including subjects, timetable, attendance, events, and duty leaves. This cannot be undone.")
            }
        }
    }

    // MARK: - Avatar Header

    private var avatarHeader: some View {
        VStack(spacing: 14) {
            // Avatar with animated gradient ring
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                AppTheme.accent,
                                AppTheme.accentSubtle,
                                AppTheme.accentSecondary,
                                AppTheme.accentWarm,
                                AppTheme.accent
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 96, height: 96)

                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 86, height: 86)

                Image(systemName: selectedAvatarIcon)
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.accent)
            }

            // Avatar icon picker
            HStack(spacing: 10) {
                ForEach(avatarIcons, id: \.self) { icon in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedAvatarIcon = icon
                        }
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundStyle(selectedAvatarIcon == icon ? AppTheme.accent : AppTheme.textTertiary)
                            .frame(width: 30, height: 30)
                            .background(selectedAvatarIcon == icon ? AppTheme.accent.opacity(0.15) : Color.clear)
                            .clipShape(Circle())
                    }
                }
            }

            // Editable name
            if isEditingName {
                HStack(spacing: 8) {
                    TextField("Your name", text: $editedName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1)
                        )

                    Button {
                        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            studentName = trimmed
                        }
                        withAnimation { isEditingName = false }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.accentSecondary)
                    }
                }
                .padding(.horizontal, 40)
            } else {
                Button {
                    editedName = studentName
                    withAnimation { isEditingName = true }
                } label: {
                    HStack(spacing: 6) {
                        Text(studentName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }

            // Membership badge
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 11))
                if viewModel.daysSinceFirstEntry > 0 {
                    Text("Active for \(viewModel.daysSinceFirstEntry) day\(viewModel.daysSinceFirstEntry == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .medium))
                } else {
                    Text("Just getting started")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .foregroundStyle(AppTheme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(AppTheme.accent.opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(.top, 8)
    }

    // MARK: - Overall Attendance Ring

    private var overallAttendanceRing: some View {
        VStack(spacing: 14) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(AppTheme.surface, lineWidth: 12)
                    .frame(width: 140, height: 140)

                // Progress ring
                Circle()
                    .trim(from: 0, to: ringAnimation)
                    .stroke(
                        AngularGradient(
                            colors: [attendanceRingColor.opacity(0.5), attendanceRingColor],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * viewModel.overallAttendance)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                // Center text
                VStack(spacing: 2) {
                    if viewModel.totalClassesTracked > 0 {
                        Text("\(Int(viewModel.overallAttendance * 100))")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(attendanceRingColor)
                        Text("percent")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    } else {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.textTertiary)
                        Text("No data")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }

            Text("Overall Attendance")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            // Attendance vs Goal comparison
            if viewModel.totalClassesTracked > 0 {
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("Current")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                        Text("\(Int(viewModel.overallAttendance * 100))%")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(attendanceRingColor)
                    }

                    Rectangle()
                        .fill(AppTheme.separator)
                        .frame(width: 1, height: 28)

                    VStack(spacing: 2) {
                        Text("Goal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                        Text("\(Int(threshold * 100))%")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(thresholdColor)
                    }

                    Rectangle()
                        .fill(AppTheme.separator)
                        .frame(width: 1, height: 28)

                    VStack(spacing: 2) {
                        Text("Status")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                        Text(viewModel.overallAttendance >= threshold ? "On Track" : "At Risk")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(viewModel.overallAttendance >= threshold ? AppTheme.accentSecondary : AppTheme.statusAbsent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                        .stroke(AppTheme.separator, lineWidth: 1)
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }

    // MARK: - Quick Stats Grid

    private var quickStatsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Your Numbers", systemImage: "number.square")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ProfileStatTile(icon: "book.closed.fill", label: "Subjects", value: "\(viewModel.totalSubjects)", color: AppTheme.accent)
                ProfileStatTile(icon: "checkmark.circle.fill", label: "Present", value: "\(viewModel.totalPresent)", color: AppTheme.statusPresent)
                ProfileStatTile(icon: "xmark.circle.fill", label: "Absent", value: "\(viewModel.totalAbsent)", color: AppTheme.statusAbsent)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ProfileStatTile(icon: "moon.circle.fill", label: "Holidays", value: "\(viewModel.totalOff)", color: AppTheme.statusOff)
                ProfileStatTile(icon: "doc.text.fill", label: "Duty Leaves", value: "\(viewModel.totalDutyLeaves)", color: AppTheme.accentSubtle)
                ProfileStatTile(icon: "star.fill", label: "Events", value: "\(viewModel.totalEvents)", color: AppTheme.accentWarm)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ProfileStatTile(icon: "calendar", label: "Days Tracked", value: "\(viewModel.uniqueDaysTracked)", color: AppTheme.accent)
                ProfileStatTile(icon: "clock.fill", label: "Weekly Slots", value: "\(viewModel.totalWeeklySlots)", color: AppTheme.accentSecondary)
            }
        }
        .padding(18)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }

    // MARK: - Streaks Card

    private var streaksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Streaks", systemImage: "flame.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: 14) {
                // Current streak
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentWarm.opacity(0.15))
                            .frame(width: 56, height: 56)
                        VStack(spacing: 0) {
                            Text("\(viewModel.currentStreak)")
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.accentWarm)
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.accentWarm.opacity(0.7))
                        }
                    }
                    Text("Current")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                        .stroke(AppTheme.accentWarm.opacity(0.2), lineWidth: 1)
                )

                // Longest streak
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentSecondary.opacity(0.15))
                            .frame(width: 56, height: 56)
                        VStack(spacing: 0) {
                            Text("\(viewModel.longestStreak)")
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.accentSecondary)
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.accentSecondary.opacity(0.7))
                        }
                    }
                    Text("Best")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                        .stroke(AppTheme.accentSecondary.opacity(0.2), lineWidth: 1)
                )

                // Active days in timetable
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.15))
                            .frame(width: 56, height: 56)
                        VStack(spacing: 0) {
                            Text("\(viewModel.activeDays)")
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.accent)
                            Text("/7")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppTheme.accent.opacity(0.7))
                        }
                    }
                    Text("Active Days")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                        .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                )
            }

            if viewModel.currentStreak >= 5 {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                    Text("Amazing! You're on a \(viewModel.currentStreak)-class streak!")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(AppTheme.accentWarm)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(AppTheme.accentWarm.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(18)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }

    // MARK: - Best / Worst Subject Card

    @ViewBuilder
    private var bestWorstCard: some View {
        if viewModel.bestSubject != nil || viewModel.worstSubject != nil {
            VStack(alignment: .leading, spacing: 14) {
                Label("Subject Spotlight", systemImage: "sparkle.magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                HStack(spacing: 12) {
                    if let best = viewModel.bestSubject {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.accentSecondary)
                                Text("Best")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(AppTheme.accentSecondary)
                                    .textCase(.uppercase)
                                    .tracking(0.4)
                            }
                            Text(best.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)
                            Text("\(Int(best.percentage * 100))%")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.accentSecondary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.accentSecondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                .stroke(AppTheme.accentSecondary.opacity(0.2), lineWidth: 1)
                        )
                    }

                    if let worst = viewModel.worstSubject {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.statusAbsent)
                                Text("Needs Work")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(AppTheme.statusAbsent)
                                    .textCase(.uppercase)
                                    .tracking(0.4)
                            }
                            Text(worst.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)
                            Text("\(Int(worst.percentage * 100))%")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundStyle(AppTheme.statusAbsent)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.statusAbsent.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                .stroke(AppTheme.statusAbsent.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(18)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )
        }
    }

    // MARK: - Attendance Settings Card

    private var attendanceSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Attendance Goal", systemImage: "target")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(spacing: 12) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(Int(threshold * 100))")
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundStyle(thresholdColor)
                    Text("%")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(thresholdColor.opacity(0.8))
                    Spacer()
                    Text("Minimum")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTertiary)
                }

                VStack(spacing: 6) {
                    Slider(value: thresholdPercent, in: 50...100, step: 1)
                        .tint(thresholdColor)

                    HStack {
                        Text("50%")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textTertiary)
                        Spacer()
                        Text("75%")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textTertiary)
                        Spacer()
                        Text("100%")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }

                HStack(spacing: 10) {
                    ForEach([65, 75, 85, 100], id: \.self) { preset in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                threshold = Double(preset) / 100
                            }
                        } label: {
                            Text("\(preset)%")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Int(threshold * 100) == preset ? AppTheme.textPrimary : AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Int(threshold * 100) == preset ? thresholdColor.opacity(0.25) : AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Int(threshold * 100) == preset ? thresholdColor.opacity(0.5) : AppTheme.separator, lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }

    // MARK: - Data Management Card

    private var dataManagementCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Data Management", systemImage: "externaldrive.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            // Storage info
            HStack(spacing: 12) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Local Storage")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("\(viewModel.totalClassesTracked) entries • \(viewModel.totalSubjects) subjects • \(viewModel.totalEvents) events")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                Spacer()
            }
            .padding(12)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))

            // Reset attendance
            Button {
                showResetAttendanceAlert = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.accentWarm)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset Attendance Only")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Clears attendance records. Keeps subjects & timetable.")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(12)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
            }
            .buttonStyle(.plain)

            // Reset everything
            Button {
                showResetAllAlert = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.statusAbsent)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset Everything")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.statusAbsent)
                        Text("Permanently deletes all app data.")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(12)
                .background(AppTheme.statusAbsent.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                        .stroke(AppTheme.statusAbsent.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How it works", systemImage: "info.circle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: 10) {
                InfoRow(
                    icon: "checkmark.circle",
                    color: AppTheme.statusPresent,
                    text: "If you're above the goal, the app tells you how many classes you can safely miss."
                )
                InfoRow(
                    icon: "arrow.up.circle",
                    color: AppTheme.accent,
                    text: "If you're below the goal, the app tells you exactly how many consecutive classes you need to attend to recover."
                )
                InfoRow(
                    icon: "flame",
                    color: AppTheme.accentWarm,
                    text: "Keep your attendance streak going! The longer your streak, the better your buffer."
                )
                InfoRow(
                    icon: "chart.bar",
                    color: AppTheme.accentSubtle,
                    text: "Open any subject in the Subjects tab to see your personalized projection."
                )
            }
        }
        .padding(18)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }

    // MARK: - App Info Footer

    private var appInfoFooter: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                Text("A")
                    .font(.system(size: 20, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.accent)
                Text("ttendy")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Text("Track. Attend. Succeed.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textTertiary)

            Text("Version 1.0 • Built with SwiftUI")
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textTertiary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Helpers

    private var thresholdColor: Color {
        AppTheme.percentageColor(threshold)
    }

    private var attendanceRingColor: Color {
        AppTheme.percentageColor(viewModel.overallAttendance)
    }
}

// MARK: - Profile Stat Tile

private struct ProfileStatTile: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
