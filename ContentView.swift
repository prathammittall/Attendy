import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }

            TimetableView()
                .tabItem {
                    Label("Timetable", systemImage: "calendar.day.timeline.left")
                }

            CalendarTabView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            SubjectsView()
                .tabItem {
                    Label("Subjects", systemImage: "book.closed")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
    }
}
