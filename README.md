# Attendyy — Attendance Tracker & Goal Projector

**Track. Attend. Succeed.**

Attendyy is a sophisticated iOS attendance tracking application built with **SwiftUI** and **Swift 6**, designed to help students monitor their class attendance, set attendance goals, and make data-driven decisions about future classes. The app provides intelligent projections to answer critical questions: *"How many classes can I safely miss?" or "How many consecutive classes do I need to attend?"*

---

## 🎯 Key Features

### 1. **Subject Management**
- Add and manage multiple subjects/courses
- Track subjects individually with detailed statistics
- View comprehensive attendance breakdowns per subject
- Delete subjects and associated data with a single action

### 2. **Smart Timetable**
- Define your weekly timetable across all seven days
- Drag-and-drop reordering of classes for intuitive schedule management
- Add/remove subjects from specific days
- Quick reference view with Monday–Sunday breakdown

### 3. **Daily Attendance Tracking**
- Mark attendance status for today's classes with four intuitive states:
  - ✅ **Present** — Attended the class
  - ❌ **Absent** — Missed the class
  - 🌙 **Off** — Class was cancelled/holiday
  - ⚪ **Clear** — No record (default state)
- Responsive status buttons with real-time updates
- Visual indicators for duty leaves affecting today's schedule

### 4. **Attendance Goal & Projections**
Users can set a minimum attendance threshold (default 75%, adjustable 50–100%) and receive intelligent projections:

- **Below Goal**: *"Attend X more consecutive classes to reach your goal"*
- **Above Goal**: *"Can safely miss X classes while maintaining your goal"*
- **At Risk**: *"Next absence will drop below your goal threshold"*
- **Critical State**: Precise calculations when attendance is at or near the threshold

Projection calculations account for:
- Present and absent classes
- Duty leave days (both full-day and subject-specific)
- Off/holiday closures
- Dynamic threshold adjustments

### 5. **Calendar View**
- Monthly calendar with visual indicators:
  - 🔵 Attendance records (presence/absence)
  - 🟠 Event markers (custom notes and events)
- Select any date to view detailed records
- **Event Management**: Add custom notes (e.g., exam dates, announcements)
- **Delete events** with a single tap
- Visual legend distinguishing attendance from events
- Navigate between months with intuitive controls

### 6. **Duty Leave Tracking**
Manage duty leaves and co-curricular absences:
- Set **start and end dates** (inclusive, multi-day support)
- Choose leave type:
  - **Full Day**: Covers all scheduled subjects on those dates
  - **Per Subject**: Applies to specific selected subjects only
- Add event name, club/organizer, and remarks
- Automatic duty leave entries appear in the calendar
- Duty leaves count as "attended" in attendance percentage calculations
- View today's duty leaves at a glance in the Today tab

### 7. **Detailed Subject Analytics**
Tap any subject to view:
- **Attendance percentage** (large, color-coded display)
- **Statistics grid**:
  - Present count
  - Absent count
  - Duty leave count
  - Off/holiday count
  - Total tracked classes
- **Personalized projection card** based on your attendance goal
- **Delete subject** option with confirmation

### 8. **Profile & Analytics Dashboard**
- **Editable Student Profile**:
  - Tap-to-edit name with persistent storage
  - Avatar icon picker (6 icons: person, graduation cap, brain, star, book, pencil)
  - Animated gradient ring around avatar
  - "Active for X days" membership badge
- **Overall Attendance Ring**:
  - Animated circular progress indicator
  - Color-coded based on attendance health (green/orange/red)
  - Current vs Goal vs Status comparison bar
  - "On Track" / "At Risk" live status indicator
- **Comprehensive Stats Grid**:
  - Total subjects, present, absent counts
  - Holidays, duty leaves, events counts
  - Days tracked, weekly timetable slots
  - Each stat tile with unique icon and color
- **Attendance Streaks**:
  - Current streak counter with flame icon
  - Longest streak (personal best) with trophy icon
  - Active timetable days out of 7
  - Motivational streak messages (at 5+ classes)
- **Subject Spotlight**:
  - Best subject with highest attendance %
  - Worst subject ("Needs Work") with lowest attendance %
  - Side-by-side comparison cards
- **Attendance Goal Configuration**:
  - Slider control (50–100%, step of 1%)
  - Quick preset buttons (65%, 75%, 85%, 100%)
  - Live percentage display with color coding
  - Persistent storage via `@AppStorage`
- **Data Management**:
  - Local storage summary (entries, subjects, events count)
  - Reset Attendance Only (keeps subjects & timetable)
  - Reset Everything (full data wipe with confirmation alerts)
- **How It Works** section with streak tips
- **App Info Footer** with branding and version

### 9. **Responsive UI**
- **Dark theme** optimized for extended use
- **Color-coded feedback**:
  - Green for safe attendance
  - Orange for warnings
  - Red for at-risk status
  - Blue accents for interactive elements
- **Smooth animations** and transitions
- **Haptic feedback** on status changes (via animation)

---

## 🏗️ Architecture & Technical Highlights

### **Project Structure**
```
Attendyy.swiftpm/
├── AttendyApp.swift              # App entry point with splash screen
├── ContentView.swift             # Main TabView with 5 tabs
├── Info.plist
├── Package.swift                 # Swift Package manifest
│
├── Core/
│   ├── Storage/
│   │   └── LocalStorageManager.swift    # Persistent JSON-based storage
│   └── Theme/
│       └── AppTheme.swift               # Centralized design system
│
├── Models/
│   ├── AttendanceEntry.swift     # Daily attendance record
│   ├── CalendarEvent.swift       # Custom events/notes
│   ├── DutyLeave.swift           # Duty leave records
│   ├── Subject.swift             # Subject/course model
│   └── Timetable.swift           # Weekly schedule structure
│
├── ViewModels/
│   ├── CalendarViewModel.swift   # Calendar + events logic
│   ├── ProfileViewModel.swift    # Profile stats, streaks & data management
│   ├── SubjectsViewModel.swift   # Subject management + analytics
│   ├── TimetableViewModel.swift  # Timetable CRUD operations
│   └── TodayViewModel.swift      # Today's view + duty leaves
│
└── Views/
    ├── Today/
    │   └── TodayView.swift       # Daily tracker + duty leave sheet
    ├── Timetable/
    │   └── TimetableView.swift   # Weekly schedule + day picker
    ├── Calendar/
    │   └── CalendarTabView.swift # Monthly calendar + events
    ├── Subjects/
    │   └── SubjectsView.swift    # Subject list + detail sheet
    └── Profile/
        └── ProfileView.swift     # Analytics dashboard + settings + data management
```

### **Technical Stack**
- **Language**: Swift 6 with concurrency safety
- **Framework**: SwiftUI (iOS 16+)
- **Storage**: Local JSON files via `LocalStorageManager`
- **Architecture**: MVVM with `@StateObject` + `@ObservedObject`
- **Concurrency**: `@MainActor` annotation for thread-safe singleton patterns
- **Data Persistence**: Codable models with automatic JSONEncoder/JSONDecoder
- **State Management**: `@Published` properties with reactive updates across tabs

### **Key Design Decisions**

1. **LocalStorageManager @MainActor**
   - Ensures thread-safe access to file operations
   - Swift 6 compliant with full concurrency checking
   - Singleton pattern for app-wide data access

2. **MVVM Pattern**
   - Each tab has dedicated ViewModel managing business logic
   - ViewModels handle calculations (attendance %, projections)
   - Views remain lightweight and focused on presentation

3. **Attendance Percentage Calculation**
   ```swift
   percentage = (present + duty_leaves) / (present + absent + duty_leaves)
   ```
   - Duty leaves count as "present" but don't override manual entries
   - Off/holiday days excluded from calculations

4. **Projection Algorithm**
   - Current percentage vs. goal threshold comparison
   - Solves for: *How many consecutive classes to reach goal?*
   - Prevents impossible targets (e.g., 100% goal with existing absences)

5. **Duty Leave Scope Handling**
   - Full-day: Matches all subjects in timetable for those dates
   - Per-subject: Only applies to explicitly selected subjects
   - Multi-day support with inclusive date ranges

---

## 🎨 Design System

### **Color Palette** (Dark Theme)
- **Background**: `#101010` (pure black)
- **Surface**: `#1A1A1A` (dark gray)
- **Cards**: `#1E1E1E` → `#252525` (layered elevation)
- **Primary Accent**: `#5E81AC` (muted blue)
- **Secondary Accents**: `#7BA88E` (sage), `#8B7EB8` (purple), `#BF916E` (warm)
- **Status Colors**:
  - Present: `#5B8A5B` (green)
  - Absent: `#A06060` (red)
  - Off/Holiday: `#8A8A5C` (yellow)
- **Text**: `#E0E0E0` primary, `#9A9A9A` secondary, `#5A5A5A` tertiary

### **Typography**
- System fonts with semantic weights
- Serif design for app branding (Attendyy logo)
- Monospaced for numeric displays (percentages, counts)

### **Component Library**
- Reusable cards with consistent borders and shadows
- Status buttons with toggle states
- Capsule badges for labels
- Animated transitions for state changes
- Rounded rectangles with corner radius: 14 (primary), 10 (secondary)

---

## 📊 Data Models

### **AttendanceEntry**
```swift
struct AttendanceEntry: Codable, Identifiable
- id: UUID
- subjectID: UUID          // Link to Subject
- slotID: UUID             // Link to Timetable slot
- date: Date               // When this entry was recorded
- status: AttendanceStatus // Present, Absent, Off, or Clear
```

### **Subject**
```swift
struct Subject: Codable, Identifiable
- id: UUID
- name: String
```

### **Timetable**
```swift
struct Timetable: Codable
- schedule: [String: [TimetableSlot]]  // Keyed by weekday (1–7)

struct TimetableSlot: Codable, Identifiable
- id: UUID
- subjectID: UUID
```

### **CalendarEvent**
```swift
struct CalendarEvent: Codable, Identifiable
- id: UUID
- date: Date
- title: String
- remarks: String
```

### **DutyLeave**
```swift
struct DutyLeave: Codable, Identifiable
- id: UUID
- startDate, endDate: Date
- eventName: String
- type: DutyLeaveType          // .fullDay or .perSubject
- clubName: String             // Optional organizer
- remarks: String              // Optional notes
- subjectIDs: [UUID]           // For .perSubject type
```

---

## 🔄 Data Flow & State Management

### **Initialization Flow**
1. **App Launch** → `AttendyApp` shows splash screen (2.2s)
2. **Splash Animation** → Logo scaling, rotating ring, bouncing dots
3. **Main Content** → `ContentView` with TabView renders
4. **Tab Selection** → Corresponding ViewModel's `load()` called
5. **Data Load** → `LocalStorageManager.shared` reads JSON files

### **Storage Path**
- Base: `Documents/AttendyData/`
- Files:
  - `subjects.json`
  - `timetable.json`
  - `entries.json`
  - `events.json`
  - `dutyLeaves.json`

### **Cross-Tab Communication**
- Each tab has independent ViewModel
- `LocalStorageManager.shared` ensures single source of truth
- Manual `viewModel.load()` after add/delete operations
- Sheet dismissals trigger refresh via `onAppear` handlers

---

## ✨ Advanced Features

### **Smart Projections**
The app uses mathematical projections to answer attendance questions:

**Example 1: Below Goal**
- Current: 8 present, 2 absent → 80% (6 more needed)
- Goal: 75%
- Formula: `n = (threshold × total - present) / (1 - threshold)`
- Result: "Attend 2 more consecutive classes"

**Example 2: Above Goal**
- Current: 15 present, 3 absent → 83.3%
- Goal: 75%
- Formula: `n = (present - threshold × total) / threshold`
- Result: "Can safely miss 2 classes"

### **Duty Leave Integration**
- No manual duty leave entry in daily tracker
- Automatically counted in attendance percentages
- Visual indicators in calendars
- Prevents double-counting with manual entries

### **Multi-Day Calendar Rendering**
- Inclusive date range handling (e.g., Feb 25–27 = 3 days)
- Correct month boundaries
- Leap year handling via `Calendar.component`

### **Dynamic Goal Adjustment**
- Threshold changes instantly update all displays
- Persistence via `@AppStorage`
- Affects all existing subject projections retroactively

---

## 🚀 Getting Started

### **Requirements**
- iOS 16.0 or later
- Xcode 16+ with Swift 6 support
- iPhone or iPad (landscape supported on iPad)

### **Installation**
1. Open `Attendyy.swiftpm` in Xcode
2. Target: `iOS 16.0+`
3. Build and run on simulator or device

### **First Time Setup**
1. **Profile Tab** → Set your attendance goal (default 75%)
2. **Subjects Tab** → Add your courses (e.g., "Mathematics", "Physics")
3. **Timetable Tab** → Assign subjects to days of the week
4. **Today Tab** → Mark attendance for today's classes
5. **Calendar Tab** → View your attendance history and add event notes

---

## 📱 UI/UX Highlights

### **Splash Screen**
- 2.2-second animated intro
- Rotating ring with gradient colors
- Checkmark icon scaling
- Bouncing loading dots
- Smooth fade-out transition

### **Tab Navigation**
- 5-tab interface (Today, Timetable, Calendar, Subjects, Profile)
- Persistent tab state during session
- Dark color scheme throughout
- Accent color highlights for interactive elements

### **List Interactions**
- Swipe to delete subjects (with confirmation)
- Drag-and-drop to reorder timetable
- Button-based actions for clarity
- Color-coded status and metrics

### **Sheet Presentations**
- Add Subject (height-constrained)
- Subject Detail (medium/large)
- Add Event (medium)
- Add Duty Leave (large, scrollable)
- Add Subject to Timetable (medium)

---

## 🔐 Data Safety & Persistence

- **Local-Only Storage**: No cloud or network requests
- **Atomic Writes**: File operations use `.atomic` option
- **Automatic Backup**: JSON files persist across app restarts
- **Error Handling**: Graceful fallbacks for corrupted files
- **No Sensitive Data**: Only attendance and schedule records

---

## 🎓 SwiftUI Challenge Demonstration

This app showcases advanced SwiftUI concepts:

✅ **Complex State Management**: Multiple `@Published` properties with interdependencies  
✅ **Custom Views & Layouts**: Grid layouts, LazyVGrid, custom Capsules, rounded rectangles  
✅ **Navigation**: TabView, NavigationStack, sheets with custom detents  
✅ **Data Binding**: Two-way bindings, `@ObservedObject`, `@AppStorage`  
✅ **Animations**: Spring animations, opacity transitions, scaling effects  
✅ **MVVM Architecture**: Clean separation of concerns with ViewModels  
✅ **Swift 6 Concurrency**: `@MainActor` for thread-safe patterns  
✅ **Responsive Design**: Adaptive layouts for iPhone and iPad  
✅ **Custom Design System**: Centralized AppTheme for consistent styling  
✅ **Complex Calculations**: Projection algorithms, date range logic  
✅ **Comprehensive List Views**: Edit, delete, reorder operations (onMove, onDelete)  
✅ **Local Data Persistence**: Codable models with JSONEncoder/Decoder  

---

## 📈 Future Enhancements

- **iCloud Sync**: Backup and sync attendance across devices
- **Notifications**: Reminders for classes and attendance milestones
- **Statistics**: Charts and graphs for attendance trends
- **Semester View**: Organize subjects by semester/term
- **Class Duration**: Track actual class hours vs. count
- **Excused Absences**: Distinguish between absences and excused leaves
- **Export Reports**: PDF or CSV export of attendance records
- **Themes**: Light mode and custom color schemes
- **Siri Integration**: Voice-activated attendance marking

---

## 📄 License

This project was created as a SwiftUI challenge submission. All code is original and demonstrates modern Swift and SwiftUI best practices.

---

## 🙌 Credits

**App Name**: Attendyy (Attend + Y for Student)  
**Tagline**: Track. Attend. Succeed.  
**Built With**: SwiftUI, Swift 6, MVVM  
**Year**: 2026

---

**Last Updated**: February 26, 2026
