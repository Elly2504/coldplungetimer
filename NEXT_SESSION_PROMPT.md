# IceDip — Cold Plunge Timer: Session 3 Continuation Prompt

## Who You Are
Senior iOS developer continuing work on IceDip, a cold plunge timer app. SwiftUI + SwiftData + MVVM with `@Observable`, iOS 17+, Swift 6.0.

## Project Setup
- **Location:** `/Volumes/T7SSD/MacMini/Projects/Coldplungetimer/`
- **Build:** XcodeGen → `xcodegen generate` → `xcodebuild build -scheme IceDip -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' -quiet`
- **NEVER modify `.pbxproj`** — edit `project.yml` and run `xcodegen generate`
- **Team ID:** `9B5THFVGW7` | **Bundle:** `com.icedip.app` | **Version:** 1.0.0

## Current State (3 commits on `main`, builds with zero warnings)
- `66d9df5` Initial commit
- `70171eb` Fix 17 bugs for App Store readiness
- `94431d0` Fix 12 remaining bugs and add Tier 1 enhancements

## What Was Done This Session (commit `94431d0`)

### 12 Bug Fixes (all verified, building clean)
**P1 Critical:**
- **Orphan cleanup** (`ContentView.swift:cleanupOrphanedSessions`): Now uses 1-hour cutoff via `Date(timeIntervalSinceNow: -3600)` in SwiftData `#Predicate` — only deletes stale incomplete sessions
- **Notification cancel** (`NotificationService.swift`): Added `cancelDailyReminder()` targeting only `"daily-reminder"` identifier. `SettingsView.swift` now calls this instead of `cancelPendingNotifications()` at lines 65 and 125
- **timeFormatted** (`TimerViewModel.swift:44`): Added `if showCompletion { return "0:00" }` guard to prevent "+0:00" flash on auto-complete

**P2 UX:**
- **Tab badge** (`ContentView.swift`): `TimerViewModel` ownership moved from `TimerView` to `ContentView` as `@State`. TimerView now accepts `@Bindable var viewModel: TimerViewModel`. Badge: `.badge(timerViewModel.isRunning ? 1 : 0)`
- **Completion view** (`TimerView.swift`): Large `session.durationFormatted` in `Theme.Fonts.timerDisplay` above "Plunge Complete!" text
- **Celebration animation** (`TimerView.swift`): `@State celebrationPulse` drives 2 pulsing `Circle` rings + shadow around checkmark, toggled via `.onChange(of: viewModel.showCompletion)`
- **Mood emojis** (`SessionCard.swift`): Replaced arrow icons with `moodEmoji()` before→after display. `moodEmoji()` extracted from TimerView to `Extensions.swift` as top-level function
- **Delete animation** (`HistoryView.swift`): `withAnimation { modelContext.delete(session) }` + `.transition(.opacity.combined(with: .slide))` + `.animation(.default, value: sessions.count)`

**P3 Polish:**
- **DateFormatter cache** (`Extensions.swift`): Private `Formatters` enum with `static let` cached formatters. Initially used `nonisolated(unsafe)` but removed it — Swift 6.0 on this Xcode treats `DateFormatter` as `Sendable`
- **Locale comments** (`ChartView.swift:54`, `StreakView.swift:203`): Documented `(weekday + 5) % 7` formula
- **Streak comment** (`StreakView.swift:185`): Clarified that 1-day streak for single session is correct behavior
- **NotificationService cleanup** (`NotificationService.swift`): Removed `@preconcurrency import`, removed all `nonisolated` keywords, converted `cancelTimerNotifications` to async `Task { await ... pendingNotificationRequests() }`

### 3 Tier 1 Enhancements
- **Launch screen** (`project.yml`, `Info.plist`, `LaunchBackground.colorset`): Dark navy (#0A1628) background. Switched from `GENERATE_INFOPLIST_FILE` to explicit `Info.plist` with XcodeGen `info: path:` + `properties:` merge
- **Onboarding** (`OnboardingView.swift`, `UserPreferences.swift`, `ContentView.swift`): 3-page `TabView(.page)` gated by `@AppStorage("hasOnboarded")`. Pages: snowflake/brain/flame icons. "Get Started" button on page 3
- **Session notes** (`PlungeSession.swift`, `TimerViewModel.swift`, `TimerView.swift`, `SessionCard.swift`): Added `notes: String?` to model (SwiftData lightweight migration). `TextField` with `axis: .vertical` on completion screen. Displayed in SessionCard below zone/temp row

## What Was Tried But Didn't Work

1. **`nonisolated(unsafe)` on static DateFormatter**: Swift 6.0 with Xcode 26.2 treats `DateFormatter` as `Sendable`, so `nonisolated(unsafe)` generated warnings. Fix: just use plain `static let`.

2. **XcodeGen `info:` without `path:`**: Adding `info: properties: UILaunchScreen: ...` under the target without a `path` key fails with "Decoding failed at 'path': Nothing found". XcodeGen requires `info: path: <plist file>` when using the `info:` block. Fix: created explicit `IceDip/Resources/Info.plist` and referenced it via `info: path: IceDip/Resources/Info.plist`.

3. **`GENERATE_INFOPLIST_FILE` + explicit Info.plist**: These conflict. When switching to `info: path:` in XcodeGen, had to remove `GENERATE_INFOPLIST_FILE`, `INFOPLIST_GENERATION_MODE`, and all `INFOPLIST_KEY_*` build settings. The plist values now live in `Info.plist` directly + XcodeGen `properties:` merge.

4. **`var viewModel: TimerViewModel` without `@Bindable`**: Moving TimerViewModel ownership from `@State` in TimerView to `@State` in ContentView means TimerView receives it as a plain `var`. But `$viewModel.property` bindings require `@Bindable`. Fix: `@Bindable var viewModel: TimerViewModel`.

## Current File Structure (21 Swift files + resources)
```
IceDip/
├── App/
│   ├── IceDipApp.swift
│   └── ContentView.swift          # TabView + onboarding gate + orphan cleanup + tab badge
├── Features/
│   ├── Timer/
│   │   ├── TimerView.swift         # @Bindable viewModel, celebration animation, notes field
│   │   ├── TimerViewModel.swift    # @Observable, notes property, showCompletion guard
│   │   ├── BenefitZone.swift
│   │   ├── ZoneGradientBackground.swift
│   │   └── ZoneIndicatorView.swift
│   ├── History/
│   │   ├── HistoryView.swift       # Delete animation
│   │   ├── SessionCard.swift       # Mood emojis, notes display
│   │   └── ChartView.swift
│   ├── Streak/
│   │   └── StreakView.swift
│   ├── Settings/
│   │   └── SettingsView.swift      # cancelDailyReminder()
│   └── Onboarding/
│       └── OnboardingView.swift    # NEW: 3-page onboarding
├── Models/
│   ├── PlungeSession.swift         # notes: String? added
│   └── UserPreferences.swift       # hasOnboarded key added
├── Services/
│   ├── HapticService.swift
│   └── NotificationService.swift   # cancelDailyReminder(), no nonisolated
└── Shared/
    ├── Theme.swift
    ├── Extensions.swift            # Cached formatters, moodEmoji()
    └── Components/
        └── CircularTimerView.swift

IceDip/Resources/
├── Info.plist                      # NEW: explicit plist with UILaunchScreen
├── Assets.xcassets/
│   ├── AppIcon.appiconset/         # NO actual icon image — just Contents.json
│   ├── AccentColor.colorset/
│   └── LaunchBackground.colorset/  # NEW: #0A1628
└── PrivacyInfo.xcprivacy
```

## Priority Next Steps

### MUST-DO: App Icon (ENHANCE 1)
- `IceDip/Resources/Assets.xcassets/AppIcon.appiconset/` has `Contents.json` but NO 1024x1024 PNG
- Design direction: dark navy (#0A1628) background, ice crystal/snowflake in ice blue (#64D2FF), minimalist premium
- After adding image: `xcodegen generate` to pick up the asset

### Tier 2 Enhancements (Post-Launch High Value)
1. **Breathing Exercise** (ENHANCE 5): New `BreathingView` between setup and active timer, animated breath circle, toggle in Settings
2. **Weekly/Monthly Stats** (ENHANCE 6): Segmented control in HistoryView for Week/Month/All Time, avg duration trend, temp correlation, mood tracking over time, zone distribution
3. **Widget Support** (ENHANCE 7): WidgetKit target, App Group for shared SwiftData, streak/goal/status widgets
4. **Apple Watch** (ENHANCE 8): watchOS target, WatchConnectivity for session sync
5. **HealthKit** (ENHANCE 9): Log sessions as "Mind and Body" workouts, add capability to project.yml
6. **Share Achievement** (ENHANCE 10): Render styled SwiftUI view to UIImage on completion screen

### Tier 3 Nice-to-Have
7. **Ambient Sound** (ENHANCE 11): AVAudioPlayer with bundled ocean/rain audio
8. **Custom Zone Thresholds** (ENHANCE 12): Override BenefitZone time ranges in Settings
9. **Theme Toggle** (ENHANCE 13): Dark/Light/System picker in Settings
10. **Localization** (ENHANCE 14): Extract hardcoded strings to Localizable.strings
11. **iCloud Sync** (ENHANCE 15): SwiftData + CloudKit

### Known Issues to Watch
- `StreakView.dayLabel(for:)` at line 219 still creates a new `DateFormatter` each call (was missed in the caching pass — it's a private function, not a Date extension)
- The `celebrationPulse` animation uses `.repeatForever` which may cause issues if the view is reused without resetting state — currently mitigated by `.onChange(of: viewModel.showCompletion)` toggling it off
- `NotificationService.cancelTimerNotifications()` uses `Task { await ... }` fire-and-forget — timer notifications might not be cancelled before the next one is scheduled if `stop()` and `start()` are called in rapid succession (edge case)

## Implementation Rules (unchanged)
1. Build after each fix: `xcodebuild build -scheme IceDip -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' -quiet`
2. Run `xcodegen generate` first if new files/directories created
3. NEVER modify `.pbxproj` directly
4. SwiftUI + SwiftData + @Observable + MVVM architecture
5. Dark theme: `.preferredColorScheme(.dark)`
6. No third-party libraries
7. Swift 6.0 strict concurrency — zero warnings
8. Don't over-engineer

## Design Spec
- **Background:** #0A1628 | **Surface:** #111D2E | **Accent:** #64D2FF
- **Zone colors:** coldShock #FF6B35, adaptation #FFB800, dopamineZone #00E5FF, metabolicBoost #1565C0, deepResilience #B0BEC5
- **Timer font:** SF Mono 72pt light | **Headings:** SF Pro Rounded bold | **Body:** SF Pro Rounded
- **Aesthetic:** Dark, calm, premium — "luxury ice"
