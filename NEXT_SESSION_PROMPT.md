# IceDip — Cold Plunge Timer: Session 7 Continuation Prompt

## Who You Are
Senior iOS developer continuing work on IceDip, a cold plunge timer app. SwiftUI + SwiftData + MVVM with `@Observable`, iOS 17+, Swift 6.0.

## Project Setup
- **Location:** `/Volumes/T7SSD/MacMini/Projects/Coldplungetimer/`
- **Build iOS:** `xcodegen generate && xcodebuild build -scheme IceDip -destination 'generic/platform=iOS' -quiet`
- **Build watchOS:** `xcrun --sdk watchos swiftc -typecheck -target arm64-apple-watchos10.0 -swift-version 6 <files>` (watchOS 26.2 platform not installed — use swiftc for verification)
- **Simulator:** `xcodebuild build -scheme IceDip -destination 'platform=iOS Simulator,id=D35A0E8C-0FF2-46DC-86EA-F9C263D01E1B' -quiet` then `xcrun simctl install ... && xcrun simctl launch ... com.icedip.app`
- **NEVER modify `.pbxproj`** — edit `project.yml` and run `xcodegen generate`
- **Team ID:** `9B5THFVGW7` | **Bundle:** `com.icedip.app` | **Version:** 1.0.0
- **Signing identity:** Apple Development: Yusuf Can Samiloglu (CM8U56F8SP)

## Current State (5 commits on `main` + uncommitted Sessions 5+6 changes, builds with zero warnings)
- `66d9df5` Initial commit
- `70171eb` Fix 17 bugs for App Store readiness
- `94431d0` Fix 12 remaining bugs and add Tier 1 enhancements
- `8d69a7d` Fix 2 bugs, add app icon, and share achievement feature
- `7c994c4` Add breathing exercise and weekly/monthly stats enhancements
- **UNCOMMITTED** Session 5: Widget support, HealthKit integration, App Store readiness fixes
- **UNCOMMITTED** Session 6: Apple Watch companion app, Ambient sound during plunge

## What Was Done in Session 6

### ENHANCE 8: Apple Watch Companion App — DONE
Standalone watchOS 10+ timer with zone display, WatchConnectivity for session sync.

- **New file:** `IceDipWatch/IceDipWatchApp.swift` — `@main` entry, creates/activates `WatchConnectivityService`, injects via `.environment()`.
- **New file:** `IceDipWatch/WatchContentView.swift` — Vertical paging `TabView` with `WatchTimerView` + `WatchStreakView`.
- **New file:** `IceDipWatch/Features/Timer/WatchTimerViewModel.swift` — `@MainActor @Observable` simplified timer. No SwiftData, no breathing, no notifications. Uses `WKExtendedRuntimeSession` to keep timer alive when wrist drops. On `stop()`: returns `WatchSessionData` if ≥5s. Background/foreground date catch-up pattern same as iOS `TimerViewModel`. WKHaptics for start/stop/zone transitions/completion.
- **New file:** `IceDipWatch/Features/Timer/WatchTimerView.swift` — Three states: setup (duration presets + Digital Crown), active (circular progress ring + zone color/icon + pause/stop), completion (checkmark + zone + done). Sends completed session via `connectivityService.sendSession()`.
- **New file:** `IceDipWatch/Features/Streak/WatchStreakView.swift` — Reads `connectivityService.streakData`: current streak (flame icon), best streak, sessions this week, last session date.
- **New file:** `IceDipWatch/Services/WatchConnectivityService.swift` — `@MainActor @Observable WCSessionDelegate`. `sendSession()` uses `transferUserInfo()` (queued, guaranteed). Receives streak data via `applicationContext`. Decodes `WatchStreakData` on activation and context updates.
- **New file:** `IceDipWatch/Info.plist` — `WKCompanionAppBundleIdentifier: com.icedip.app`. XcodeGen merges additional properties.
- **New file:** `IceDip/Shared/WatchSessionData.swift` — Two `Codable Sendable` structs: `WatchSessionData` (id, startTime, endTime, targetDuration, benefitZoneReached, waterTemp?) and `WatchStreakData` (currentStreak, bestStreak, sessionsThisWeek, lastSessionDate?). Compiled into both iOS and watchOS targets.
- **New file:** `IceDip/Services/PhoneConnectivityService.swift` — `@MainActor @Observable WCSessionDelegate`. Receives Watch sessions via `didReceiveUserInfo()`, decodes `WatchSessionData`, inserts as `PlungeSession` into SwiftData via `ModelContext`. `sendStreakUpdate()` encodes `WatchStreakData` and calls `updateApplicationContext()`.
- **IceDipApp.swift:** Added `@State private var phoneConnectivityService`, stored `container` as `let`, injects service + sets `modelContainer` + activates in `.onAppear`.
- **project.yml:** Added `watchOS: "10.0"` deployment target. New `IceDipWatch` target (type: application, platform: watchOS) sharing `BenefitZone.swift`, `Extensions.swift`, `Theme.swift`, `WatchSessionData.swift`. Separate `IceDipWatch` scheme. Watch is NOT embedded as iOS dependency (watchOS 10+ apps are independent).

### ENHANCE 11: Ambient Sound During Plunge — DONE
AVAudioPlayer with bundled ocean/rain loops. Toggle + picker in Settings.

- **New file:** `IceDip/Models/AmbientSound.swift` — Enum: `.ocean` ("Ocean Waves"), `.rain` ("Rain"). Properties: `id`, `displayName`, `fileName`. Conforms to `CaseIterable, Identifiable`.
- **New file:** `IceDip/Services/AmbientSoundService.swift` — `@MainActor @Observable`. `play(sound:)` loads `.wav` from Bundle, sets `numberOfLoops = -1`. `pause()`, `resume()`, `stop()`. Configures `AVAudioSession` category `.ambient` (mixes with other audio, respects silent switch).
- **New file:** `Scripts/generate_ambient_sounds.swift` — Generates `ocean.wav` and `rain.wav` programmatically using sine waves, amplitude modulation, and noise. Deterministic PRNG, crossfade for seamless loops. 15s duration, 44.1kHz mono. Run: `swift Scripts/generate_ambient_sounds.swift`.
- **New files:** `IceDip/Resources/Sounds/ocean.wav` + `rain.wav` — Generated ambient loop files.
- **UserPreferences.swift:** Added keys: `ambientSoundEnabled`, `selectedAmbientSound`.
- **IceDipApp.swift:** Added `@State private var ambientSoundService`, injected via `.environment()`.
- **TimerViewModel.swift:** Added `storedAmbientSoundService: AmbientSoundService?` and `pendingAmbientSound: AmbientSound?`. `beginSession()` and `start()` accept `ambientSoundService:` and `ambientSound:` params. `start()` calls `play()`, `pause()` calls `pause()`, `resume()` calls `resume()`, `stop()` and `reset()` call `stop()` and nil out.
- **TimerView.swift:** Added `@Environment(AmbientSoundService.self)`, `@AppStorage` for `ambientSoundEnabled` and `selectedAmbientSound`. Passes `ambientSoundService:` and `ambientSound:` to `beginSession()`.
- **SettingsView.swift:** Added "Ambient Sound" section after "Feedback": toggle "Play During Plunge" + conditional `Picker` for sound selection.

## What Was Tried But Didn't Work (All Sessions)

1. **`nonisolated(unsafe)` on static DateFormatter**: Swift 6.0/Xcode 26.2 treats `DateFormatter` as `Sendable`. Fix: plain `static let`.
2. **XcodeGen `info:` without `path:`**: Requires explicit `info: path: <plist>`.
3. **`GENERATE_INFOPLIST_FILE` + explicit Info.plist**: Conflict. Must remove all `INFOPLIST_KEY_*` build settings.
4. **`var viewModel: TimerViewModel` without `@Bindable`**: `$viewModel.property` requires `@Bindable`.
5. **Boot disk full during builds**: DerivedData on Macintosh HD fills volume. Fix: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`.
6. **`platform=iOS Simulator,name=iPhone 16,OS=18.5`**: Fix: use specific simulator UUID `D35A0E8C-0FF2-46DC-86EA-F9C263D01E1B`.
7. **`static var container` for ModelContainer**: Swift 6.0 strict concurrency flags `var` as non-safe. Fix: `static let`.
8. **`HKWorkout(activityType:start:end:...)` init**: Deprecated in iOS 17. Fix: use `HKWorkoutBuilder` instead.
9. **Code signing with new entitlements (App Groups + HealthKit)**: Provisioning profile doesn't include new capabilities until registered in Apple Developer Portal. Fix: build with `CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` for compilation verification.
10. **`@preconcurrency` on `WCSessionDelegate` conformance**: Swift 6.0/Xcode 26.2 says it has no effect. Fix: remove `@preconcurrency`, use `nonisolated func` for delegate methods and dispatch to `@MainActor` with `Task { @MainActor in ... }`.
11. **Embedding Watch app as iOS dependency in project.yml**: Fails with "watchOS 26.2 must be installed". Fix: watchOS 10+ apps are independent — do NOT add `IceDipWatch` as a dependency of the iOS target. Build via separate `IceDipWatch` scheme.
12. **`xcodebuild -destination 'generic/platform=watchOS'` for Watch builds**: Fails because watchOS 26.2 platform isn't fully installed (needs download from Xcode > Settings > Components). Fix: use `xcrun --sdk watchos swiftc -typecheck -target arm64-apple-watchos10.0 -swift-version 6 <files>` for compilation verification.

## Current File Structure (35 Swift files + resources)
```
IceDip/
├── App/
│   ├── IceDipApp.swift              # SharedModelContainer, 4 services injected (Notification, HealthKit, AmbientSound, PhoneConnectivity)
│   └── ContentView.swift            # TabView + onboarding gate + orphan cleanup + tab badge + HK auth check
├── Features/
│   ├── Timer/
│   │   ├── TimerView.swift          # @Bindable viewModel, breathing, ShareLink, HK + ambient sound, accessibility
│   │   ├── TimerViewModel.swift     # @Observable, breathing, async stop/tick, WidgetKit, HK save, ambient sound lifecycle
│   │   ├── BreathingView.swift      # Animated box breathing (3 cycles)
│   │   ├── ShareCardView.swift      # Styled share card rendered to UIImage
│   │   ├── BenefitZone.swift        # Zone enum, thresholds, colors, icons (SHARED with widget + watch)
│   │   ├── ZoneGradientBackground.swift
│   │   └── ZoneIndicatorView.swift
│   ├── History/
│   │   ├── HistoryView.swift        # Zone dist + mood trend + section headers
│   │   ├── SessionCard.swift        # Mood emojis, notes display
│   │   ├── ChartView.swift          # Week/Month/All picker with 3 data modes
│   │   └── ZoneDistributionView.swift
│   ├── Streak/
│   │   └── StreakView.swift          # Delegates to StreakCalculator
│   ├── Settings/
│   │   └── SettingsView.swift       # Timer, Units, Feedback, Ambient Sound, Notifications, Health, Goals, About
│   └── Onboarding/
│       └── OnboardingView.swift     # 3-page onboarding
├── Models/
│   ├── PlungeSession.swift          # @Model, notes: String?, zone computed property
│   ├── UserPreferences.swift        # All AppStorage keys incl. ambientSoundEnabled, selectedAmbientSound
│   └── AmbientSound.swift           # Enum: ocean, rain
├── Services/
│   ├── HapticService.swift          # Static methods for haptic feedback
│   ├── HealthKitService.swift       # @Observable, HKWorkoutBuilder, auth management
│   ├── NotificationService.swift    # async cancelTimerNotifications()
│   ├── AmbientSoundService.swift    # @Observable, AVAudioPlayer, play/pause/resume/stop
│   └── PhoneConnectivityService.swift # WCSessionDelegate, receives Watch sessions, sends streak updates
└── Shared/
    ├── Theme.swift                  # Colors, Fonts, Spacing, Animations (SHARED with widget + watch)
    ├── Extensions.swift             # Color(hex:), TimeInterval, Date, moodEmoji(), temp conversion (SHARED)
    ├── SharedModelContainer.swift   # App Group-aware ModelContainer (shared with widget)
    ├── StreakCalculator.swift        # Extracted streak/goal logic (shared with widget)
    ├── WatchSessionData.swift       # Codable structs for Watch↔Phone sync (SHARED with watch)
    └── Components/
        └── CircularTimerView.swift

IceDipWatch/
├── IceDipWatchApp.swift             # @main, WatchConnectivityService injected
├── WatchContentView.swift           # Vertical TabView: Timer + Streak
├── Features/
│   ├── Timer/
│   │   ├── WatchTimerView.swift     # Setup/active/completion states, circular progress
│   │   └── WatchTimerViewModel.swift # @Observable, WKExtendedRuntimeSession, standalone timer
│   └── Streak/
│       └── WatchStreakView.swift     # Streak display from connectivity data
├── Services/
│   └── WatchConnectivityService.swift # WCSessionDelegate, sends sessions, receives streak
└── Info.plist                       # WKCompanionAppBundleIdentifier

IceDipWidget/
├── IceDipWidgetBundle.swift         # @main widget entry point
├── IceDipWidget.swift               # PlungeEntry, PlungeTimelineProvider, IceDipWidget
├── IceDipWidgetEntryView.swift      # SmallWidgetView + MediumWidgetView
├── IceDipWidget.entitlements        # App Group
└── Info.plist                       # WidgetKit extension point

Scripts/
├── generate_icon.swift              # CoreGraphics icon generator
└── generate_ambient_sounds.swift    # Generates ocean.wav + rain.wav

IceDip/Resources/
├── Info.plist                       # UILaunchScreen, HealthKit usage descriptions, orientations
├── IceDip.entitlements              # App Group + HealthKit
├── Sounds/
│   ├── ocean.wav                    # 15s ambient loop (generated)
│   └── rain.wav                     # 15s ambient loop (generated)
├── Assets.xcassets/
│   ├── AppIcon.appiconset/          # AppIcon.png (1024x1024 universal snowflake)
│   ├── AccentColor.colorset/
│   └── LaunchBackground.colorset/   # #0A1628
└── PrivacyInfo.xcprivacy
```

## Key Architectural Decisions
- **Shared SwiftData via App Group**: `SharedModelContainer` provides single `ModelContainer` at `group.com.icedip.app/IceDip.store`. Used by both main app and widget extension.
- **StreakCalculator as shared logic**: Struct taking `[PlungeSession]`, reused by `StreakView` and widget `PlungeTimelineProvider`.
- **Service injection pattern**: All services (`NotificationService`, `HealthKitService`, `AmbientSoundService`, `PhoneConnectivityService`) are `@MainActor @Observable`, created as `@State` in `IceDipApp`, injected via `.environment()`. Optional services stored in ViewModel during session lifecycle.
- **Watch architecture**: Standalone timer (not phone-dependent). No SwiftData on Watch. `WatchTimerViewModel` is a simplified version of iOS `TimerViewModel`. `WKExtendedRuntimeSession` keeps timer alive. Sessions sync via `transferUserInfo()` (guaranteed delivery), streak data via `updateApplicationContext()` (latest state).
- **Watch NOT embedded in iOS**: watchOS 10+ apps are independent. Separate `IceDipWatch` scheme, not a dependency of the iOS target.
- **Ambient sound**: `AVAudioPlayer` with `.ambient` category (mixes with other audio, respects silent switch). Loops infinitely. Lifecycle tied to timer: play on start, pause on pause, resume on resume, stop on stop/reset.
- **Widget timeline**: Refreshes every 2 hours + `WidgetCenter.shared.reloadAllTimelines()` on session complete.
- **TimerViewModel ownership**: Owned by `ContentView` as `@State`, passed to `TimerView` as `@Bindable`.
- **Deferred start pattern**: `beginSession()` stores all params (incl. services) in pending vars during breathing, `breathingComplete()` calls `start()`.

## Remaining Known Issues
- **PhoneConnectivityService doesn't call `sendStreakUpdate()` anywhere yet**: After inserting a Watch session, it should compute streak and send update. Also, after any local session completion in `TimerViewModel.stop()`, streak should be pushed to Watch. This needs wiring.
- **WatchTimerView auto-completes but `stop()` result isn't sent**: When `tick()` calls `stop()` internally on auto-complete, the returned `WatchSessionData` is discarded. The `stop()` in `tick()` should send the session via connectivity service.
- **No Watch app icon**: `IceDipWatch/` needs an `Assets.xcassets` with watch icon.
- **celebrationPulse `.repeatForever`** (`TimerView.swift`): Safe — view conditionally rendered.
- **Hard-coded zone thresholds** (`BenefitZone.swift`): Duplication risk between `startSeconds` and `zone(for:)`.
- **ChartView English weekday names**: Hard-coded, not localized.
- **App icon is programmatic**: May want professionally designed icon for App Store.
- **Code signing**: App Groups + HealthKit capabilities must be registered in Apple Developer Portal.
- **Generated ambient sounds**: Basic sine/noise — may want higher quality audio files for production.

## Priority Next Steps

### Critical Fixes (from Session 6)
1. **Wire `PhoneConnectivityService.sendStreakUpdate()`**: After `insertSession()` completes, compute streak using `StreakCalculator` and call `sendStreakUpdate()`. Also call it from `TimerViewModel.stop()` after session completion.
2. **Fix Watch auto-complete session send**: In `WatchTimerViewModel.tick()`, when `stop()` is called on auto-complete, the returned `WatchSessionData` needs to be sent via connectivity service. The ViewModel needs a reference to `WatchConnectivityService`.
3. **Add Watch app icon**: Create `IceDipWatch/Assets.xcassets/AppIcon.appiconset/` with watch-sized icon (1024x1024 single asset for watchOS 10+).

### Tier 3 Nice-to-Have
4. **Custom Zone Thresholds** (ENHANCE 12): Override BenefitZone time ranges in Settings
5. **Theme Toggle** (ENHANCE 13): Dark/Light/System picker in Settings
6. **Localization** (ENHANCE 14): Extract hardcoded strings to Localizable.strings
7. **iCloud Sync** (ENHANCE 15): SwiftData + CloudKit for cross-device data

### Quality Improvements
- Refactor `BenefitZone.zone(for:)` to derive from `startSeconds` (eliminate threshold duplication)
- Localize ChartView weekday labels
- Add SwiftData `VersionedSchema` + `SchemaMigrationPlan` for future-proofing
- Replace generated ambient audio with higher-quality loops
- Consider professionally designed app icon

### App Store Submission Checklist
- [ ] Register App Groups + HealthKit capabilities in Apple Developer Portal
- [ ] Install watchOS 26.2 platform from Xcode > Settings > Components
- [ ] Build and sign on physical device (iOS + watchOS)
- [ ] Test widget on device (add from home screen)
- [ ] Test HealthKit flow on device (Simulator doesn't support HealthKit)
- [ ] Test Watch↔Phone session sync on real devices
- [ ] App Store Connect: screenshots, description, keywords, privacy policy URL
- [ ] Archive and upload via Xcode Organizer

## Design Spec
- **Background:** #0A1628 | **Surface:** #111D2E | **Accent:** #64D2FF
- **Zone colors:** coldShock #FF6B35, adaptation #FFB800, dopamineZone #00E5FF, metabolicBoost #1565C0, deepResilience #B0BEC5
- **Timer font:** SF Mono 72pt light | **Headings:** SF Pro Rounded bold | **Body:** SF Pro Rounded
- **Watch timer font:** SF Mono 28pt light | **Watch heading:** SF Pro Rounded title3 bold
- **Aesthetic:** Dark, calm, premium — "luxury ice"

## Implementation Rules (unchanged)
1. Build: `xcodegen generate && xcodebuild build -scheme IceDip -destination 'generic/platform=iOS' -quiet`
2. Watch verify: `xcrun --sdk watchos swiftc -typecheck -target arm64-apple-watchos10.0 -swift-version 6 <files>`
3. Run `xcodegen generate` first if new files/directories created
4. NEVER modify `.pbxproj` directly
5. SwiftUI + SwiftData + @Observable + MVVM architecture
6. Dark theme: `.preferredColorScheme(.dark)`
7. No third-party libraries
8. Swift 6.0 strict concurrency — zero warnings
9. Don't over-engineer
10. For compilation-only verification (no signing): append `CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO`
11. Simulator UUID for iPhone 16 Pro (iOS 18.4): `D35A0E8C-0FF2-46DC-86EA-F9C263D01E1B`
