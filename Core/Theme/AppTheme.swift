import SwiftUI

enum AppTheme {
    // Backgrounds
    static let background = Color(hex: "#101010")
    static let surface = Color(hex: "#1A1A1A")
    static let card = Color(hex: "#1E1E1E")
    static let cardElevated = Color(hex: "#252525")

    // Text
    static let textPrimary = Color(hex: "#E0E0E0")
    static let textSecondary = Color(hex: "#9A9A9A")
    static let textTertiary = Color(hex: "#5A5A5A")

    // Accent colors — muted but with character
    static let accent = Color(hex: "#5E81AC")        // steel blue
    static let accentSecondary = Color(hex: "#7BA88E") // sage green
    static let accentWarm = Color(hex: "#BF916E")     // muted copper
    static let accentSubtle = Color(hex: "#8B7EB8")   // dusty lavender

    static let separator = Color(hex: "#2A2A2A")

    // Status colors — rich but not bright
    static let statusPresent = Color(hex: "#5B8A5B")
    static let statusAbsent = Color(hex: "#A06060")
    static let statusOff = Color(hex: "#8A8A5C")
    static let statusClear = Color(hex: "#3E3E3E")

    // Corners
    static let cornerRadius: CGFloat = 14
    static let cornerRadiusSmall: CGFloat = 10

    static func statusColor(for status: AttendanceStatus) -> Color {
        switch status {
        case .present: return statusPresent
        case .absent: return statusAbsent
        case .off: return statusOff
        case .clear: return statusClear
        }
    }

    // Attendance percentage color — green to amber to red
    static func percentageColor(_ pct: Double) -> Color {
        if pct >= 0.75 { return accentSecondary }
        if pct >= 0.50 { return accentWarm }
        return statusAbsent
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
