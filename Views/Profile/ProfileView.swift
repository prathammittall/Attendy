import SwiftUI

struct ProfileView: View {
    @AppStorage("minAttendanceThreshold") private var threshold: Double = 0.75

    // Slider operates on percentage (50...100)
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
                    VStack(spacing: 20) {
                        avatarHeader
                        attendanceSettingsCard
                        infoCard
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Avatar Header

    private var avatarHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1.5)
                    )
                Image(systemName: "person.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(AppTheme.accent)
            }
            Text("Student")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("Track your attendance goals")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.top, 8)
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
                // Big percentage display
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

                // Slider
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

                // Quick preset buttons
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

    private var thresholdColor: Color {
        AppTheme.percentageColor(threshold)
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
