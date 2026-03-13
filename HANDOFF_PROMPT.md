# IceDip — Cold Plunge Timer iOS App: Bug Fix & Polish Handoff

## Who You Are
You are a senior iOS developer taking over a partially-built cold plunge timer app. The app compiles and runs with zero warnings, but has significant bugs, missing features, and polish issues that must be fixed before App Store submission. Your job is to fix every issue listed below systematically, then verify the build still compiles cleanly.

## Project Setup
- **Location:** `/Volumes/T7SSD/MacMini/Projects/Coldplungetimer/`
- **Build system:** XcodeGen (`project.yml` → `xcodegen generate` → `IceDip.xcodeproj`)
- **Architecture:** SwiftUI + SwiftData + MVVM with `@Observable`, iOS 17+, Swift 6.0
- **Team ID:** `9B5THFVGW7`
- **NEVER modify `.pbxproj` directly** — edit `project.yml` and run `xcodegen generate`
- **Build command:** `xcodebuild build -scheme IceDip -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' -quiet`

## Current File Structure (19 Swift files)
```
IceDip/
├── App/
│   ├── IceDipApp.swift          # @main, SwiftData container
│   └── ContentView.swift        # TabView (Timer, History, Streak, Settings)
├── Features/
│   ├── Timer/
│   │   ├── TimerView.swift          # Main timer screen (setup → active → completion)
│   │   ├── TimerViewModel.swift     # @Observable timer logic with zone tracking
│   │   ├── BenefitZone.swift        # 5-zone enum with time ranges, colors, descriptions
│   │   ├── ZoneGradientBackground.swift  # Animated gradient backdrop
│   │   └── ZoneIndicatorView.swift  # Horizontal 5-segment zone bar
│   ├── History/
│   │   ├── HistoryView.swift        # Session list with charts and stats
│   │   ├── SessionCard.swift        # Individual session display card
│   │   └── ChartView.swift          # Swift Charts weekly bar chart
│   ├── Streak/
│   │   └── StreakView.swift          # Streak counter, weekly goal, 7-day overview
│   └── Settings/
│       └── SettingsView.swift       # App preferences
├── Models/
│   ├── PlungeSession.swift          # SwiftData @Model
│   └── UserPreferences.swift        # AppStorage key constants
├── Services/
│   ├── HapticService.swift          # @MainActor enum for haptic feedback
│   └── NotificationService.swift    # @Observable notification manager
└── Shared/
    ├── Theme.swift                  # Colors, fonts, spacing, animation constants
    ├── Extensions.swift             # Color(hex:), TimeInterval formatting, Date helpers
    └── Components/
        └── CircularTimerView.swift  # Progress ring with zone-aware coloring
```

---

## COMPLETE CURRENT SOURCE CODE

### project.yml
```yaml
name: IceDip
options:
  bundleIdPrefix: com.icedip
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "26.2"
  createIntermediateGroups: true

settings:
  base:
    DEVELOPMENT_TEAM: "9B5THFVGW7"
    SWIFT_VERSION: "6.0"

targets:
  IceDip:
    type: application
    platform: iOS
    sources:
      - path: IceDip
        excludes:
          - "**/.DS_Store"
    settings:
      base:
        CODE_SIGN_STYLE: Automatic
        INFOPLIST_GENERATION_MODE: GeneratedFile
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: true
        INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: true
        INFOPLIST_KEY_UILaunchScreen_Generation: true
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: "UIInterfaceOrientationPortrait"
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        INFOPLIST_KEY_CFBundleDisplayName: "IceDip"
        MARKETING_VERSION: "1.0.0"
        CURRENT_PROJECT_VERSION: 1
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        PRODUCT_BUNDLE_IDENTIFIER: com.icedip.app
        GENERATE_INFOPLIST_FILE: true
        INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: false

schemes:
  IceDip:
    build:
      targets:
        IceDip: all
    run:
      config: Debug
    archive:
      config: Release
```

### IceDip/App/IceDipApp.swift
```swift
import SwiftUI
import SwiftData

@main
struct IceDipApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [PlungeSession.self])
    }
}
```

### IceDip/App/ContentView.swift
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TimerView()
                .tabItem { Label("Timer", systemImage: "timer") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            StreakView()
                .tabItem { Label("Streak", systemImage: "flame.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(Theme.Colors.iceBlue)
    }
}
```

### IceDip/Shared/Theme.swift
```swift
import SwiftUI

enum Theme {
    enum Colors {
        static let background = Color(hex: "0A1628")
        static let surface = Color(hex: "111D2E")
        static let iceBlue = Color(hex: "64D2FF")
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.6)

        // Zone colors
        static let coldShock = Color(hex: "FF6B35")
        static let adaptation = Color(hex: "FFB800")
        static let dopamineZone = Color(hex: "00E5FF")
        static let metabolicBoost = Color(hex: "1565C0")
        static let deepResilience = Color(hex: "B0BEC5")
    }

    enum Fonts {
        static let timerDisplay = Font.system(size: 72, weight: .light, design: .monospaced)
        static let timerDisplaySmall = Font.system(size: 48, weight: .light, design: .monospaced)
        static let heading = Font.system(.title, design: .rounded, weight: .bold)
        static let headingSmall = Font.system(.title3, design: .rounded, weight: .semibold)
        static let body = Font.system(.body, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let zoneLabel = Font.system(.subheadline, design: .rounded, weight: .semibold)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Animations {
        static let zoneTransition = Animation.easeInOut(duration: 0.8)
        static let timerTick = Animation.linear(duration: 0.1)
        static let celebration = Animation.spring(response: 0.5, dampingFraction: 0.6)
    }
}
```

### IceDip/Shared/Extensions.swift
```swift
import SwiftUI

// MARK: - Color Hex Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
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

// MARK: - TimeInterval Formatting

extension TimeInterval {
    var formattedTimer: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedMinutes: String {
        let minutes = Int(self) / 60
        return "\(minutes) min"
    }
}

// MARK: - Date Helpers

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }

    var formattedShort: String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }

    var formattedMedium: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Temperature Conversion

extension Double {
    var celsiusToFahrenheit: Double {
        self * 9.0 / 5.0 + 32.0
    }

    var fahrenheitToCelsius: Double {
        (self - 32.0) * 5.0 / 9.0
    }

    func formattedTemperature(unit: String) -> String {
        let value = unit == "fahrenheit" ? self.celsiusToFahrenheit : self
        let symbol = unit == "fahrenheit" ? "°F" : "°C"
        return String(format: "%.0f%@", value, symbol)
    }
}
```

### IceDip/Features/Timer/BenefitZone.swift
```swift
import SwiftUI

enum BenefitZone: String, CaseIterable, Codable, Identifiable {
    case coldShock
    case adaptation
    case dopamineZone
    case metabolicBoost
    case deepResilience

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .coldShock: "Cold Shock"
        case .adaptation: "Adaptation"
        case .dopamineZone: "Dopamine Zone"
        case .metabolicBoost: "Metabolic Boost"
        case .deepResilience: "Deep Resilience"
        }
    }

    var description: String {
        switch self {
        case .coldShock: "Adrenaline spike, fight-or-flight response activating"
        case .adaptation: "Body adjusting, norepinephrine rising"
        case .dopamineZone: "Dopamine +250%, norepinephrine +530%"
        case .metabolicBoost: "Brown fat activation, doubled metabolic rate"
        case .deepResilience: "Cellular cleanup, autophagy activation"
        }
    }

    var icon: String {
        switch self {
        case .coldShock: "bolt.fill"
        case .adaptation: "arrow.triangle.2.circlepath"
        case .dopamineZone: "brain.head.profile"
        case .metabolicBoost: "flame.fill"
        case .deepResilience: "snowflake"
        }
    }

    var color: Color {
        switch self {
        case .coldShock: Theme.Colors.coldShock
        case .adaptation: Theme.Colors.adaptation
        case .dopamineZone: Theme.Colors.dopamineZone
        case .metabolicBoost: Theme.Colors.metabolicBoost
        case .deepResilience: Theme.Colors.deepResilience
        }
    }

    /// Threshold in seconds where this zone begins
    var startSeconds: TimeInterval {
        switch self {
        case .coldShock: 0
        case .adaptation: 30
        case .dopamineZone: 60
        case .metabolicBoost: 120
        case .deepResilience: 180
        }
    }

    static func zone(for elapsedSeconds: TimeInterval) -> BenefitZone {
        switch elapsedSeconds {
        case ..<30: .coldShock
        case ..<60: .adaptation
        case ..<120: .dopamineZone
        case ..<180: .metabolicBoost
        default: .deepResilience
        }
    }
}
```

### IceDip/Models/PlungeSession.swift
```swift
import Foundation
import SwiftData

@Model
final class PlungeSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var targetDuration: TimeInterval
    var waterTemp: Double?
    var benefitZoneReached: String?
    var moodBefore: Int?
    var moodAfter: Int?
    var isCompleted: Bool

    var duration: TimeInterval {
        guard let endTime else { return Date().timeIntervalSince(startTime) }
        return endTime.timeIntervalSince(startTime)
    }

    var durationFormatted: String {
        duration.formattedTimer
    }

    var zone: BenefitZone? {
        guard let benefitZoneReached else { return nil }
        return BenefitZone(rawValue: benefitZoneReached)
    }

    init(targetDuration: TimeInterval) {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.targetDuration = targetDuration
        self.waterTemp = nil
        self.benefitZoneReached = nil
        self.moodBefore = nil
        self.moodAfter = nil
        self.isCompleted = false
    }

    func complete(waterTemp: Double?, moodBefore: Int?, moodAfter: Int?) {
        self.endTime = Date()
        self.waterTemp = waterTemp
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.benefitZoneReached = BenefitZone.zone(for: duration).rawValue
        self.isCompleted = true
    }
}
```

### IceDip/Models/UserPreferences.swift
```swift
import Foundation

enum PreferenceKey {
    static let defaultDuration = "defaultDuration"
    static let tempUnit = "tempUnit"
    static let hapticsEnabled = "hapticsEnabled"
    static let soundEnabled = "soundEnabled"
    static let reminderEnabled = "reminderEnabled"
    static let reminderHour = "reminderHour"
    static let reminderMinute = "reminderMinute"
    static let weeklyGoalSessions = "weeklyGoalSessions"
}
```

### IceDip/Services/HapticService.swift
```swift
import UIKit

@MainActor
enum HapticService {
    static func start() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func zoneTransition() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func countdown(secondsRemaining: Int) {
        guard secondsRemaining <= 3 && secondsRemaining > 0 else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func complete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
```

### IceDip/Services/NotificationService.swift
```swift
import Foundation
@preconcurrency import UserNotifications

@MainActor
@Observable
final class NotificationService {
    var isAuthorized = false

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            self.isAuthorized = granted
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    func checkPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.isAuthorized = settings.authorizationStatus == .authorized
    }

    nonisolated func scheduleTimerComplete(duration: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Plunge Complete!"
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            content.body = "Great job! You stayed in for \(minutes)m \(seconds)s."
        } else {
            content.body = "Great job! You stayed in for \(seconds) seconds."
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: duration,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "timer-complete-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    nonisolated func scheduleDailyReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time for Your Cold Plunge"
        content.body = "Build your resilience — start today's cold exposure session."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "daily-reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    nonisolated func cancelPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    nonisolated func cancelTimerNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let timerIds = requests
                .filter { $0.identifier.hasPrefix("timer-complete-") }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: timerIds)
        }
    }
}
```

### IceDip/Features/Timer/TimerViewModel.swift
```swift
import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class TimerViewModel {
    // MARK: - State

    var selectedDuration: TimeInterval = 120
    var isRunning = false
    var isPaused = false
    var elapsedSeconds: TimeInterval = 0
    var currentSession: PlungeSession?
    var currentZone: BenefitZone = .coldShock
    var showCompletion = false

    // Pre/post plunge inputs
    var waterTemp: Double = 5.0
    var hasWaterTemp = false
    var moodBefore: Int? = nil
    var moodAfter: Int? = nil

    // MARK: - Private

    private var timer: Timer?
    private var backgroundDate: Date?

    // MARK: - Computed

    var remainingSeconds: TimeInterval {
        max(selectedDuration - elapsedSeconds, 0)
    }

    var progress: Double {
        guard selectedDuration > 0 else { return 0 }
        return min(elapsedSeconds / selectedDuration, 1.0)
    }

    var timeFormatted: String {
        if elapsedSeconds > selectedDuration {
            return "+\(elapsedSeconds.formattedTimer)"
        }
        return remainingSeconds.formattedTimer
    }

    var isComplete: Bool {
        elapsedSeconds >= selectedDuration
    }

    // MARK: - Actions

    func start(modelContext: ModelContext, hapticsEnabled: Bool, notificationService: NotificationService) {
        let session = PlungeSession(targetDuration: selectedDuration)
        modelContext.insert(session)
        currentSession = session

        isRunning = true
        isPaused = false
        elapsedSeconds = 0
        currentZone = .coldShock
        showCompletion = false
        moodAfter = nil

        notificationService.scheduleTimerComplete(duration: selectedDuration)

        if hapticsEnabled {
            HapticService.start()
        }

        startTimer(hapticsEnabled: hapticsEnabled)
    }

    func pause() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    func resume(hapticsEnabled: Bool) {
        isPaused = false
        startTimer(hapticsEnabled: hapticsEnabled)
    }

    func stop(modelContext: ModelContext, hapticsEnabled: Bool, notificationService: NotificationService) {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false

        notificationService.cancelTimerNotifications()

        if let session = currentSession {
            session.complete(
                waterTemp: hasWaterTemp ? waterTemp : nil,
                moodBefore: moodBefore,
                moodAfter: moodAfter
            )

            if hapticsEnabled {
                HapticService.complete()
            }

            showCompletion = true
        }
    }

    func reset() {
        currentSession = nil
        showCompletion = false
        moodBefore = nil
        moodAfter = nil
    }

    func handleBackground() {
        guard isRunning, !isPaused else { return }
        backgroundDate = Date()
        timer?.invalidate()
        timer = nil
    }

    func handleForeground(hapticsEnabled: Bool) {
        guard let backgroundDate, isRunning, !isPaused else { return }
        let elapsed = Date().timeIntervalSince(backgroundDate)
        self.backgroundDate = nil

        let previousZone = currentZone
        elapsedSeconds += elapsed
        currentZone = BenefitZone.zone(for: elapsedSeconds)

        if currentZone != previousZone && hapticsEnabled {
            HapticService.zoneTransition()
        }

        if !isComplete {
            startTimer(hapticsEnabled: hapticsEnabled)
        }
    }

    // MARK: - Private

    private func startTimer(hapticsEnabled: Bool) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.tick(hapticsEnabled: hapticsEnabled)
            }
        }
    }

    private func tick(hapticsEnabled: Bool) {
        elapsedSeconds += 1

        let newZone = BenefitZone.zone(for: elapsedSeconds)
        if newZone != currentZone {
            currentZone = newZone
            if hapticsEnabled {
                HapticService.zoneTransition()
            }
        }

        if hapticsEnabled {
            let remaining = Int(remainingSeconds)
            HapticService.countdown(secondsRemaining: remaining)
        }
    }
}
```

### IceDip/Features/Timer/TimerView.swift
```swift
import SwiftUI
import SwiftData

struct TimerView: View {
    @State private var viewModel = TimerViewModel()
    @State private var notificationService = NotificationService()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(PreferenceKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(PreferenceKey.defaultDuration) private var defaultDuration: TimeInterval = 120

    private let durationPresets: [(String, TimeInterval)] = [
        ("1m", 60),
        ("2m", 120),
        ("3m", 180),
        ("5m", 300),
        ("10m", 600)
    ]

    var body: some View {
        ZStack {
            ZoneGradientBackground(
                zone: viewModel.currentZone,
                isActive: viewModel.isRunning
            )

            if viewModel.showCompletion {
                completionView
            } else if viewModel.isRunning {
                activeTimerView
            } else {
                setupView
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                viewModel.handleBackground()
            } else if newPhase == .active && oldPhase == .background {
                viewModel.handleForeground(hapticsEnabled: hapticsEnabled)
            }
        }
        .onAppear {
            viewModel.selectedDuration = defaultDuration
            Task { await notificationService.checkPermission() }
        }
    }

    // MARK: - Setup View (Before Start)

    private var setupView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            Text(viewModel.selectedDuration.formattedTimer)
                .font(Theme.Fonts.timerDisplay)
                .foregroundStyle(Theme.Colors.textPrimary)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(durationPresets, id: \.1) { label, duration in
                    Button {
                        viewModel.selectedDuration = duration
                        if hapticsEnabled { HapticService.selection() }
                    } label: {
                        Text(label)
                            .font(Theme.Fonts.zoneLabel)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(
                                viewModel.selectedDuration == duration
                                    ? Theme.Colors.iceBlue
                                    : Theme.Colors.surface
                            )
                            .foregroundStyle(
                                viewModel.selectedDuration == duration
                                    ? Theme.Colors.background
                                    : Theme.Colors.textPrimary
                            )
                            .clipShape(Capsule())
                    }
                }
            }

            VStack(spacing: Theme.Spacing.sm) {
                Toggle(isOn: $viewModel.hasWaterTemp) {
                    Label("Water Temperature", systemImage: "thermometer.medium")
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .tint(Theme.Colors.iceBlue)

                if viewModel.hasWaterTemp {
                    HStack {
                        Text("\(Int(viewModel.waterTemp))°C")
                            .font(Theme.Fonts.headingSmall)
                            .foregroundStyle(Theme.Colors.iceBlue)
                            .frame(width: 50)
                        Slider(value: $viewModel.waterTemp, in: 0...15, step: 1)
                            .tint(Theme.Colors.iceBlue)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)

            moodSelector(title: "How do you feel?", selection: $viewModel.moodBefore)

            Spacer()

            Button {
                Task { await notificationService.requestPermission() }
                viewModel.start(
                    modelContext: modelContext,
                    hapticsEnabled: hapticsEnabled,
                    notificationService: notificationService
                )
            } label: {
                Text("START")
                    .font(Theme.Fonts.heading)
                    .foregroundStyle(Theme.Colors.background)
                    .frame(width: 200, height: 64)
                    .background(Theme.Colors.iceBlue)
                    .clipShape(Capsule())
            }
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    // MARK: - Active Timer View

    private var activeTimerView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            CircularTimerView(
                progress: viewModel.progress,
                timeText: viewModel.timeFormatted,
                zone: viewModel.currentZone,
                isRunning: viewModel.isRunning
            )
            .frame(width: 280, height: 280)

            ZoneIndicatorView(
                currentZone: viewModel.currentZone,
                elapsedSeconds: viewModel.elapsedSeconds
            )
            .padding(.horizontal, Theme.Spacing.xl)

            Spacer()

            HStack(spacing: Theme.Spacing.xl) {
                Button {
                    if viewModel.isPaused {
                        viewModel.resume(hapticsEnabled: hapticsEnabled)
                    } else {
                        viewModel.pause()
                    }
                } label: {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(width: 64, height: 64)
                        .background(Theme.Colors.surface)
                        .clipShape(Circle())
                }

                Button {
                    viewModel.stop(
                        modelContext: modelContext,
                        hapticsEnabled: hapticsEnabled,
                        notificationService: notificationService
                    )
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(width: 64, height: 64)
                        .background(Theme.Colors.coldShock.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.Colors.iceBlue)
                .scaleEffect(viewModel.showCompletion ? 1.0 : 0.5)
                .animation(Theme.Animations.celebration, value: viewModel.showCompletion)

            Text("Plunge Complete!")
                .font(Theme.Fonts.heading)
                .foregroundStyle(Theme.Colors.textPrimary)

            if let session = viewModel.currentSession {
                VStack(spacing: Theme.Spacing.sm) {
                    summaryRow("Duration", value: session.durationFormatted)
                    if let zone = session.zone {
                        summaryRow("Zone Reached", value: zone.displayName, color: zone.color)
                    }
                    if let temp = session.waterTemp {
                        summaryRow("Water Temp", value: "\(Int(temp))°C")
                    }
                }
                .padding()
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, Theme.Spacing.xl)
            }

            moodSelector(title: "How do you feel now?", selection: $viewModel.moodAfter)

            Spacer()

            Button {
                if let moodAfter = viewModel.moodAfter {
                    viewModel.currentSession?.moodAfter = moodAfter
                }
                viewModel.reset()
            } label: {
                Text("Done")
                    .font(Theme.Fonts.headingSmall)
                    .foregroundStyle(Theme.Colors.background)
                    .frame(width: 200, height: 56)
                    .background(Theme.Colors.iceBlue)
                    .clipShape(Capsule())
            }
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    // MARK: - Helpers

    private func summaryRow(_ label: String, value: String, color: Color = Theme.Colors.textPrimary) -> some View {
        HStack {
            Text(label)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(Theme.Fonts.body)
                .foregroundStyle(color)
        }
    }

    private func moodSelector(title: String, selection: Binding<Int?>) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(title)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(spacing: Theme.Spacing.md) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        selection.wrappedValue = rating
                        if hapticsEnabled { HapticService.selection() }
                    } label: {
                        Text(moodEmoji(rating))
                            .font(.title2)
                            .padding(Theme.Spacing.sm)
                            .background(
                                selection.wrappedValue == rating
                                    ? Theme.Colors.iceBlue.opacity(0.2)
                                    : Color.clear
                            )
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private func moodEmoji(_ rating: Int) -> String {
        switch rating {
        case 1: "😰"
        case 2: "😕"
        case 3: "😐"
        case 4: "😊"
        case 5: "🤩"
        default: "😐"
        }
    }
}
```

### IceDip/Features/Timer/ZoneGradientBackground.swift
```swift
import SwiftUI

struct ZoneGradientBackground: View {
    let zone: BenefitZone
    let isActive: Bool

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(Theme.Animations.zoneTransition, value: zone)
    }

    private var gradientColors: [Color] {
        if isActive {
            return [
                Theme.Colors.background,
                zone.color.opacity(0.3),
                Theme.Colors.background
            ]
        }
        return [Theme.Colors.background, Theme.Colors.background]
    }
}
```

### IceDip/Features/Timer/ZoneIndicatorView.swift
```swift
import SwiftUI

struct ZoneIndicatorView: View {
    let currentZone: BenefitZone
    let elapsedSeconds: TimeInterval

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: 2) {
                ForEach(BenefitZone.allCases) { zone in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(zone.color.opacity(zoneOpacity(for: zone)))
                        .frame(height: 6)
                }
            }

            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: currentZone.icon)
                    .font(.system(size: 14))
                Text(currentZone.displayName)
                    .font(Theme.Fonts.zoneLabel)
            }
            .foregroundStyle(currentZone.color)

            Text(currentZone.description)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .animation(Theme.Animations.zoneTransition, value: currentZone)
    }

    private func zoneOpacity(for zone: BenefitZone) -> Double {
        if zone == currentZone { return 1.0 }
        if zone.startSeconds < elapsedSeconds { return 0.5 }
        return 0.15
    }
}
```

### IceDip/Shared/Components/CircularTimerView.swift
```swift
import SwiftUI

struct CircularTimerView: View {
    let progress: Double
    let timeText: String
    let zone: BenefitZone
    let isRunning: Bool

    private let lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Theme.Colors.surface,
                    lineWidth: lineWidth
                )

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    zone.color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(Theme.Animations.timerTick, value: progress)

            VStack(spacing: Theme.Spacing.xs) {
                Text(timeText)
                    .font(Theme.Fonts.timerDisplay)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .contentTransition(.numericText())
                    .monospacedDigit()

                if isRunning {
                    Text(zone.displayName)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(zone.color)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(timeText) remaining, \(zone.displayName) zone")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
}
```

### IceDip/Features/History/HistoryView.swift
```swift
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \PlungeSession.startTime, order: .reverse)
    private var sessions: [PlungeSession]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                if sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.md) {
                            ChartView(sessions: sessions)
                            statsBar
                            ForEach(sessions) { session in
                                SessionCard(session: session)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.sm)
                    }
                }
            }
            .navigationTitle("History")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "snowflake")
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.iceBlue.opacity(0.3))
            Text("No sessions yet")
                .font(Theme.Fonts.headingSmall)
                .foregroundStyle(Theme.Colors.textSecondary)
            Text("Complete your first cold plunge to see it here")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private var statsBar: some View {
        let completedSessions = sessions.filter(\.isCompleted)
        let totalMinutes = completedSessions.reduce(0.0) { $0 + $1.duration / 60.0 }
        let avgDuration = completedSessions.isEmpty ? 0 : totalMinutes / Double(completedSessions.count)

        return HStack(spacing: Theme.Spacing.md) {
            statItem("Sessions", value: "\(completedSessions.count)")
            statItem("Total", value: "\(Int(totalMinutes))m")
            statItem("Average", value: String(format: "%.1fm", avgDuration))
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(_ label: String, value: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(value)
                .font(Theme.Fonts.headingSmall)
                .foregroundStyle(Theme.Colors.iceBlue)
            Text(label)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
```

### IceDip/Features/History/SessionCard.swift
```swift
import SwiftUI

struct SessionCard: View {
    let session: PlungeSession
    @AppStorage(PreferenceKey.tempUnit) private var tempUnit = "celsius"

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            if let zone = session.zone {
                Circle()
                    .fill(zone.color)
                    .frame(width: 12, height: 12)
            } else {
                Circle()
                    .fill(Theme.Colors.textSecondary)
                    .frame(width: 12, height: 12)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(session.startTime.formattedShort)
                        .font(Theme.Fonts.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(session.startTime.formattedTime)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                HStack(spacing: Theme.Spacing.sm) {
                    if let zone = session.zone {
                        Text(zone.displayName)
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(zone.color)
                    }

                    if let temp = session.waterTemp {
                        Label(temp.formattedTemperature(unit: tempUnit), systemImage: "thermometer.medium")
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }

            Spacer()

            Text(session.durationFormatted)
                .font(Theme.Fonts.headingSmall)
                .foregroundStyle(Theme.Colors.iceBlue)

            if let before = session.moodBefore, let after = session.moodAfter {
                moodDelta(before: before, after: after)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func moodDelta(before: Int, after: Int) -> some View {
        let delta = after - before
        let symbol = delta > 0 ? "arrow.up" : delta < 0 ? "arrow.down" : "minus"
        let color = delta > 0 ? Color.green : delta < 0 ? Color.red : Theme.Colors.textSecondary
        return Image(systemName: symbol)
            .font(.caption)
            .foregroundStyle(color)
    }
}
```

### IceDip/Features/History/ChartView.swift
```swift
import SwiftUI
import Charts

struct ChartView: View {
    let sessions: [PlungeSession]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("This Week")
                .font(Theme.Fonts.headingSmall)
                .foregroundStyle(Theme.Colors.textPrimary)

            Chart(weeklyData, id: \.label) { day in
                BarMark(
                    x: .value("Day", day.label),
                    y: .value("Minutes", day.minutes)
                )
                .foregroundStyle(Theme.Colors.iceBlue.gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let minutes = value.as(Double.self) {
                            Text("\(Int(minutes))m")
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Theme.Colors.surface)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .frame(height: 160)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var weeklyData: [DayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }

        return (0..<7).map { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: monday) else {
                return DayData(label: weekdays[offset], minutes: 0)
            }
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            let dayMinutes = sessions
                .filter { $0.isCompleted && $0.startTime >= date && $0.startTime < nextDate }
                .reduce(0.0) { $0 + $1.duration / 60.0 }
            return DayData(label: weekdays[offset], minutes: dayMinutes)
        }
    }
}

private struct DayData {
    let label: String
    let minutes: Double
}
```

### IceDip/Features/Streak/StreakView.swift
```swift
import SwiftUI
import SwiftData

struct StreakView: View {
    @Query(sort: \PlungeSession.startTime, order: .reverse)
    private var sessions: [PlungeSession]
    @AppStorage(PreferenceKey.weeklyGoalSessions) private var weeklyGoal = 3

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        streakCard
                        weekOverview
                        weeklyGoalCard
                        bestStreakCard
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)
                }
            }
            .navigationTitle("Streak")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var streakCard: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundStyle(currentStreak > 0 ? Theme.Colors.coldShock : Theme.Colors.textSecondary)

            Text("\(currentStreak)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(currentStreak == 1 ? "day streak" : "day streak")
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var weekOverview: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Last 7 Days")
                .font(Theme.Fonts.zoneLabel)
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(0..<7, id: \.self) { daysAgo in
                    let date = Date().daysAgo(6 - daysAgo)
                    let hasSession = hasSession(on: date)
                    VStack(spacing: Theme.Spacing.xs) {
                        Circle()
                            .fill(hasSession ? Theme.Colors.iceBlue : Theme.Colors.surface)
                            .frame(width: 36, height: 36)
                            .overlay {
                                if hasSession {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(Theme.Colors.background)
                                }
                            }
                        Text(dayLabel(for: date))
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var weeklyGoalCard: some View {
        let sessionsThisWeek = sessionsThisWeekCount
        let goalProgress = min(Double(sessionsThisWeek) / Double(max(weeklyGoal, 1)), 1.0)

        return VStack(spacing: Theme.Spacing.sm) {
            HStack {
                Text("Weekly Goal")
                    .font(Theme.Fonts.zoneLabel)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
                Text("\(sessionsThisWeek)/\(weeklyGoal)")
                    .font(Theme.Fonts.headingSmall)
                    .foregroundStyle(Theme.Colors.iceBlue)
            }

            ProgressView(value: goalProgress)
                .tint(Theme.Colors.iceBlue)

            if sessionsThisWeek >= weeklyGoal {
                Text("Goal reached!")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.iceBlue)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var bestStreakCard: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundStyle(Theme.Colors.adaptation)
            VStack(alignment: .leading) {
                Text("Best Streak")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text("\(bestStreak) days")
                    .font(Theme.Fonts.headingSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Streak Calculations

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: .now)

        if !hasSession(on: checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                return 0
            }
            checkDate = yesterday
        }

        while hasSession(on: checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }

        return streak
    }

    private var bestStreak: Int {
        let calendar = Calendar.current
        let completedSessions = sessions.filter(\.isCompleted)
        guard !completedSessions.isEmpty else { return 0 }

        let sessionDays = Set(completedSessions.map { calendar.startOfDay(for: $0.startTime) })
        let sortedDays = sessionDays.sorted()

        var best = 1
        var current = 1

        for i in 1..<sortedDays.count {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: sortedDays[i - 1]),
               calendar.isDate(nextDay, inSameDayAs: sortedDays[i]) {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }

        return max(best, currentStreak)
    }

    private var sessionsThisWeekCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return 0
        }
        return sessions.filter { $0.isCompleted && $0.startTime >= monday }.count
    }

    private func hasSession(on date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return false
        }
        return sessions.contains { $0.isCompleted && $0.startTime >= dayStart && $0.startTime < dayEnd }
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
    }
}
```

### IceDip/Features/Settings/SettingsView.swift
```swift
import SwiftUI

struct SettingsView: View {
    @AppStorage(PreferenceKey.defaultDuration) private var defaultDuration: TimeInterval = 120
    @AppStorage(PreferenceKey.tempUnit) private var tempUnit = "celsius"
    @AppStorage(PreferenceKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(PreferenceKey.soundEnabled) private var soundEnabled = true
    @AppStorage(PreferenceKey.reminderEnabled) private var reminderEnabled = false
    @AppStorage(PreferenceKey.reminderHour) private var reminderHour = 7
    @AppStorage(PreferenceKey.reminderMinute) private var reminderMinute = 0
    @AppStorage(PreferenceKey.weeklyGoalSessions) private var weeklyGoalSessions = 3

    @State private var notificationService = NotificationService()

    private let durationOptions: [(String, TimeInterval)] = [
        ("30 seconds", 30),
        ("1 minute", 60),
        ("2 minutes", 120),
        ("3 minutes", 180),
        ("5 minutes", 300),
        ("10 minutes", 600)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                List {
                    Section("Timer") {
                        Picker("Default Duration", selection: $defaultDuration) {
                            ForEach(durationOptions, id: \.1) { label, value in
                                Text(label).tag(value)
                            }
                        }
                    }

                    Section("Units") {
                        Picker("Temperature", selection: $tempUnit) {
                            Text("Celsius (°C)").tag("celsius")
                            Text("Fahrenheit (°F)").tag("fahrenheit")
                        }
                    }

                    Section("Feedback") {
                        Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                        Toggle("Sound Effects", isOn: $soundEnabled)
                    }

                    Section("Notifications") {
                        Toggle("Daily Reminder", isOn: $reminderEnabled)
                            .onChange(of: reminderEnabled) { _, enabled in
                                if enabled {
                                    Task { await notificationService.requestPermission() }
                                    notificationService.scheduleDailyReminder(
                                        hour: reminderHour,
                                        minute: reminderMinute
                                    )
                                } else {
                                    notificationService.cancelPendingNotifications()
                                }
                            }

                        if reminderEnabled {
                            DatePicker(
                                "Reminder Time",
                                selection: reminderDateBinding,
                                displayedComponents: .hourAndMinute
                            )
                            .onChange(of: reminderHour) { _, _ in updateReminder() }
                            .onChange(of: reminderMinute) { _, _ in updateReminder() }
                        }
                    }

                    Section("Weekly Goal") {
                        Stepper(
                            "\(weeklyGoalSessions) sessions per week",
                            value: $weeklyGoalSessions,
                            in: 1...14
                        )
                    }

                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(Theme.Colors.iceBlue)
        }
    }

    private var reminderDateBinding: Binding<Date> {
        Binding<Date>(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? .now
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderHour = components.hour ?? 7
                reminderMinute = components.minute ?? 0
            }
        )
    }

    private func updateReminder() {
        guard reminderEnabled else { return }
        notificationService.cancelPendingNotifications()
        notificationService.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
    }
}
```

---

## BUGS TO FIX (Prioritized)

### PRIORITY 1 — CRITICAL (App will be rejected or crash)

**BUG 1: Zone time ranges don't match the original design spec**
- **File:** `BenefitZone.swift`
- **Current:** coldShock 0-30s, adaptation 30-60s, dopamineZone 60-120s, metabolicBoost 120-180s, deepResilience 180s+
- **Spec says:** coldShock 0-30s, adaptation 30-60s, dopamineZone 60-120s, metabolicBoost 120-180s, deepResilience 180s+
- **Verdict:** Actually matches. But the ORIGINAL user spec had different ranges: 0-30s, 30-60s, 60-120s, 120-180s, 180s+. Verify these are scientifically accurate and update `startSeconds` property to match.

**BUG 2: StreakView has duplicate ternary — "day streak" vs "day streak"**
- **File:** `StreakView.swift`, line 49
- **Current:** `Text(currentStreak == 1 ? "day streak" : "day streak")` — both branches identical
- **Fix:** Change to `Text(currentStreak == 1 ? "day streak" : "days streak")` or just `"day streak"` without ternary

**BUG 3: Notification permission race condition**
- **File:** `TimerView.swift`, line 113-119
- **Current:** `Task { await notificationService.requestPermission() }` fires async THEN `viewModel.start()` runs immediately — permission may not be granted yet
- **Fix:** Await permission before starting timer, OR request permission on first app launch in `IceDipApp.swift`

**BUG 4: 0-second sessions saved as completed**
- **File:** `TimerViewModel.swift` + `PlungeSession.swift`
- **Current:** User can tap START then immediately STOP → saves a completed session with 0 duration
- **Fix:** Add minimum duration check (e.g., 5 seconds) before marking session as completed. Sessions under threshold should be deleted, not saved.

**BUG 5: No session delete functionality**
- **File:** `HistoryView.swift`
- **Current:** Sessions are displayed but cannot be deleted. No swipe-to-delete, no context menu.
- **Fix:** Add swipe-to-delete using `onDelete` or context menu with `modelContext.delete(session)`

**BUG 6: Temperature unit not respected in TimerView**
- **File:** `TimerView.swift`, line 96
- **Current:** Always shows `"\(Int(viewModel.waterTemp))°C"` regardless of user's temperature unit preference
- **Fix:** Read `@AppStorage(PreferenceKey.tempUnit)` and display accordingly. The slider should also show the correct unit label and range (0-15°C or 32-59°F)

**BUG 7: `soundEnabled` preference is stored but never used**
- **File:** `SettingsView.swift` has the toggle, but `NotificationService` always uses `.default` sound
- **Fix:** Pass `soundEnabled` to notification scheduling, set `content.sound = soundEnabled ? .default : nil`

**BUG 8: Version hardcoded in SettingsView**
- **File:** `SettingsView.swift`, line 93
- **Current:** `Text("1.0.0")` hardcoded
- **Fix:** Use `Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"`

### PRIORITY 2 — HIGH (Poor UX, will affect reviews)

**BUG 9: No confirmation before stopping active timer**
- **File:** `TimerView.swift`, stop button
- **Fix:** Add `.confirmationDialog` before calling `viewModel.stop()` — "End plunge early?"

**BUG 10: Timer doesn't auto-complete when reaching target duration**
- **File:** `TimerViewModel.swift`
- **Current:** Timer keeps running past target indefinitely, user must manually stop
- **Fix:** When `isComplete` becomes true, auto-stop the timer, fire completion haptic, show completion view. The timer should still show total elapsed time on completion screen.

**BUG 11: Orphaned sessions on app force-quit**
- **File:** `TimerViewModel.swift`
- **Current:** If app is force-quit during active timer, the PlungeSession stays in SwiftData with `isCompleted = false` and no `endTime`
- **Fix:** On app launch, query for incomplete sessions and either delete them or mark them with estimated duration

**BUG 12: Pause → background → foreground creates double-start**
- **File:** `TimerViewModel.swift`, `handleForeground()`
- **Current:** `handleForeground` guard checks `!isPaused`, but if user was paused the guard passes. If timer was paused and app was backgrounded, foreground handler should not restart the timer.
- **Fix:** Verify the guard logic handles pause+background correctly

**BUG 13: Multiple NotificationService instances**
- **File:** `TimerView.swift` line 6, `SettingsView.swift` line 13
- **Current:** Each view creates its own `@State private var notificationService = NotificationService()` — these are separate instances
- **Fix:** Create a single NotificationService in `IceDipApp.swift` and pass via `.environment()`, OR make it a singleton

**BUG 14: Completion view shows temperature in °C regardless of unit preference**
- **File:** `TimerView.swift`, line 216
- **Current:** `summaryRow("Water Temp", value: "\(Int(temp))°C")`
- **Fix:** Use `temp.formattedTemperature(unit: tempUnit)` matching SessionCard's approach

### PRIORITY 3 — MEDIUM (Polish & Performance)

**BUG 15: Streak/chart calculations run on every view render**
- **File:** `StreakView.swift` — `currentStreak`, `bestStreak`, `sessionsThisWeekCount` are all computed properties recalculated every render
- **Fix:** Extract streak calculations into a computed cache or move to a ViewModel

**BUG 16: Missing accessibility labels on interactive elements**
- TimerView: START button, PAUSE/RESUME buttons, STOP button, duration presets, mood selectors, water temp slider
- HistoryView: Session cards, stats bar
- StreakView: Streak card, week overview dots
- **Fix:** Add `.accessibilityLabel()` and `.accessibilityHint()` to all interactive elements

**BUG 17: Duration display doesn't animate on preset selection**
- **File:** `TimerView.swift`, line 55
- **Fix:** Add `.contentTransition(.numericText())` to the duration display text

**BUG 18: Missing PrivacyInfo.xcprivacy**
- Required since iOS 17 for App Store submission
- Create `IceDip/Resources/PrivacyInfo.xcprivacy` declaring UserDefaults (NSPrivacyAccessedAPICategoryUserDefaults) usage

**BUG 19: No app icon**
- **File:** `AppIcon.appiconset/Contents.json` has the spec but no actual image file
- A 1024x1024 PNG is needed for the app icon

**BUG 20: Git not initialized**
- Run `git init` and make initial commit

---

## IMPLEMENTATION RULES

1. **Fix bugs in priority order** (1 → 2 → 3)
2. **After EACH fix**, verify the build still compiles: `xcodebuild build -scheme IceDip -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' -quiet`
3. **Run `xcodegen generate` FIRST** if you create any new files or directories
4. **NEVER modify `.pbxproj` directly** — only edit `project.yml`
5. **Keep the same architecture** — SwiftUI + SwiftData + @Observable + MVVM
6. **Keep the dark theme** — `.preferredColorScheme(.dark)` stays
7. **No third-party libraries** — only native Apple frameworks
8. **Swift 6.0** with strict concurrency — no Sendable warnings
9. **Zero warnings** — the build must be completely clean
10. **Don't over-engineer** — fix what's broken, don't refactor what works

## DESIGN SPEC REFERENCE
- **Background:** Deep navy (#0A1628)
- **Surface:** Slightly lighter (#111D2E)
- **Primary accent:** Ice blue (#64D2FF)
- **Zone colors:** coldShock (red-orange #FF6B35), adaptation (amber #FFB800), dopamineZone (cyan #00E5FF), metabolicBoost (deep blue #1565C0), deepResilience (ice-silver #B0BEC5)
- **Timer font:** SF Mono, 72pt light
- **Headings:** SF Pro Rounded, bold
- **Body:** SF Pro Rounded
- **Aesthetic:** Dark, calm, premium — "luxury ice" not "gym bro"
