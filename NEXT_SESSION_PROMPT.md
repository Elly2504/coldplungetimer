# IceDip — Cold Plunge Timer: Session 14 Continuation Prompt

## Who You Are
Senior iOS developer continuing work on IceDip, a cold plunge timer app. SwiftUI + SwiftData + MVVM with `@Observable`, iOS 17+, Swift 6.0. Session 13 added three post-launch features: widget adaptive theming, Shortcuts/Siri integration, and Watch complication. The app is feature-complete and App Store submission-ready — this session focuses on strengthening the new features, localization, accessibility, or submission.

## Project Setup
- **Location:** `/Volumes/T7SSD/MacMini/Projects/Coldplungetimer/`
- **Build iOS:** `xcodegen generate && xcodebuild build -scheme IceDip -destination 'generic/platform=iOS' -quiet`
- **Build watchOS:** `xcrun --sdk watchos swiftc -typecheck -target arm64-apple-watchos10.0 -swift-version 6 <files>` (watchOS 26.2 platform not installed — use swiftc for verification)
- **Simulator:** `xcodebuild build -scheme IceDip -destination 'platform=iOS Simulator,id=D35A0E8C-0FF2-46DC-86EA-F9C263D01E1B' -quiet` then `xcrun simctl install ... && xcrun simctl launch ... com.icedip.app`
- **NEVER modify `.pbxproj`** — edit `project.yml` and run `xcodegen generate`
- **Team ID:** `9B5THFVGW7` | **Bundle:** `com.icedip.app` | **Version:** 1.0.0
- **Signing identity:** Apple Development: Yusuf Can Samiloglu (CM8U56F8SP)

## Current State (18 commits on `main`, all committed, builds with zero warnings)
- `66d9df5` Initial commit
- `70171eb` Fix 17 bugs for App Store readiness
- `94431d0` Fix 12 remaining bugs and add Tier 1 enhancements
- `8d69a7d` Fix 2 bugs, add app icon, and share achievement feature
- `7c994c4` Add breathing exercise and weekly/monthly stats enhancements
- `f0c91a1` Add widget, Watch app, HealthKit, ambient sound, and connectivity fixes
- `88e9e7f` Update continuation prompt for Session 8
- `b42160f` Refactor BenefitZone, localize weekdays, and add SwiftData schema versioning
- `ac8575c` Add localization, theme toggle, custom zone thresholds, and iCloud sync
- `77c2ef6` Update continuation prompt for Session 9
- `2aeaee7` Update continuation prompt for Session 9
- `f5b65d2` Add light mode polish, locale-aware formatters, and Turkish localization
- `374b659` Update continuation prompt for Session 10
- `d92cc56` Fix App Store blockers, add error handling, and localize into 4 new languages
- `04d63e3` Update continuation prompt for Session 11
- `ad87c20` Add privacy manifests for extensions, replace print with os.Logger, and localize notifications
- `c64d6ea` Update continuation prompt for Session 12
- `01f2186` Add widget adaptive theming, Shortcuts/Siri integration, and Watch complication

## What Was Done in Session 13

### 1. Widget Adaptive Theming — DONE
- **Created:** `IceDipWidget/Assets.xcassets/` with 5 theme color sets (ThemeBackground, ThemeSurface, ThemeIceBlue, ThemeTextPrimary, ThemeTextSecondary) — copied from `IceDipWatch/Assets.xcassets/`
- **Modified:** `IceDipWidget/IceDipWidgetEntryView.swift` — replaced all hardcoded hex colors with `Theme.Colors.*` references
- Widget now respects system light/dark mode automatically via named color assets
- `Theme.swift` was already compiled into widget target (project.yml line 66) — only needed the color asset catalog
- No project.yml changes required — `path: IceDipWidget` auto-includes new Assets.xcassets

### 2. Shortcuts/Siri Integration — DONE
- **Created:** `IceDip/Intents/StartPlungeIntent.swift` — `AppIntent` with `openAppWhenRun = true`, sets `pendingShortcutStart` flag in UserDefaults
- **Created:** `IceDip/Intents/IceDipShortcuts.swift` — `AppShortcutsProvider` with 4 Siri phrases ("Start my cold plunge in IceDip", etc.)
- **Modified:** `IceDip/App/ContentView.swift`:
  - Added `@State private var selectedTab = 0` with `TabView(selection:)` binding and `.tag()` on each tab
  - Added `@AppStorage("pendingShortcutStart")` flag observer
  - Added `startFromShortcut()` method: sets tab to Timer, reads user's saved `defaultDuration` preference, calls `timerViewModel.beginSession(...)` with all saved preferences
  - Handles both cold launch (via `.task`) and warm launch (via `.onChange(of: pendingShortcutStart)`)
- No project.yml changes — AppIntents framework is built-in at iOS 17+

### 3. Watch Complication (WidgetKit) — DONE
- **Created:** `IceDipWatch/Complications/` directory with 6 files:
  - `WatchComplicationProvider.swift` — `TimelineProvider` reading streak from `UserDefaults.standard`, refreshes at midnight
  - `WatchComplicationViews.swift` — 3 families: `.accessoryCircular` (flame + count), `.accessoryRectangular` (streak + sessions this week), `.accessoryInline` (label)
  - `IceDipWatchWidget.swift` — `Widget` config with `StaticConfiguration`, entry view switching on `widgetFamily`
  - `IceDipWatchWidgetBundle.swift` — `@main WidgetBundle`
  - `Info.plist` — `com.apple.widgetkit-extension` extension point
  - `PrivacyInfo.xcprivacy` — UserDefaults API (CA92.1)
- **Modified:** `IceDipWatch/Services/WatchConnectivityService.swift`:
  - Added `import WidgetKit`
  - Added `persistForComplication()` method: writes streak fields to UserDefaults + calls `WidgetCenter.shared.reloadAllTimelines()`
  - Called after `decodeStreakData()` succeeds
- **Modified:** `IceDipWatch/Features/Timer/WatchTimerViewModel.swift`:
  - Added `import WidgetKit`
  - In `stop()`: after `connectivityService?.sendSession()`, increments `complication_sessionsThisWeek` in UserDefaults and reloads timelines
- **Modified:** `project.yml`:
  - Added `IceDipWatchWidgetExtension` target (type: `app-extension`, platform: `watchOS`, bundle: `com.icedip.app.watchkitapp.widget`)
  - Sources: `IceDipWatch/Complications` + shared `IceDip/Shared/Extensions.swift`
  - Added `Complications` to IceDipWatch excludes (separate target)
  - Added `dependencies: [{target: IceDipWatchWidgetExtension, embed: true}]` to IceDipWatch
  - Added `IceDipWatchWidgetExtension: all` to IceDipWatch scheme

## What Was Tried But Didn't Work (All Sessions)

1. **`nonisolated(unsafe)` on static DateFormatter**: Swift 6.0/Xcode 26.2 treats `DateFormatter` as `Sendable`. Fix: plain `static let`.
2. **XcodeGen `info:` without `path:`**: Requires explicit `info: path: <plist>`.
3. **`GENERATE_INFOPLIST_FILE` + explicit Info.plist**: Conflict. Must remove all `INFOPLIST_KEY_*` build settings.
4. **`var viewModel: TimerViewModel` without `@Bindable`**: `$viewModel.property` requires `@Bindable`.
5. **Boot disk full during builds**: DerivedData on Macintosh HD fills volume. Fix: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`.
6. **`platform=iOS Simulator,name=iPhone 16,OS=18.5`**: Fix: use specific simulator UUID `D35A0E8C-0FF2-46DC-86EA-F9C263D01E1B`.
7. **`static var container` for ModelContainer**: Swift 6.0 strict concurrency flags `var` as non-safe. Fix: `static let`.
8. **`HKWorkout(activityType:start:end:...)` init**: Deprecated in iOS 17. Fix: use `HKWorkoutBuilder` instead.
9. **Code signing with new entitlements (App Groups + HealthKit + iCloud)**: Provisioning profile doesn't include new capabilities until registered in Apple Developer Portal. Fix: build with `CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` for compilation verification.
10. **`@preconcurrency` on `WCSessionDelegate` conformance**: Swift 6.0/Xcode 26.2 says it has no effect. Fix: remove `@preconcurrency`, use `nonisolated func` for delegate methods and dispatch to `@MainActor` with `Task { @MainActor in ... }`.
11. **Embedding Watch app as iOS dependency in project.yml**: Fails with "watchOS 26.2 must be installed". Fix: watchOS 10+ apps are independent — do NOT add `IceDipWatch` as a dependency of the iOS target. Build via separate `IceDipWatch` scheme.
12. **`xcodebuild -destination 'generic/platform=watchOS'` for Watch builds**: Fails because watchOS 26.2 platform isn't fully installed (needs download from Xcode > Settings > Components). Fix: use `xcrun --sdk watchos swiftc -typecheck -target arm64-apple-watchos10.0 -swift-version 6 <files>` for compilation verification.
13. **`static var versionIdentifier` in VersionedSchema**: Swift 6.0 strict concurrency flags `var` as non-safe. Fix: `static let versionIdentifier`.
14. **Session 9 audit suggested adding HealthKit/CloudKit to `NSPrivacyAccessedAPITypes`**: These are NOT required reason APIs. The valid categories are only: FileTimestamp, SystemBootTime, DiskSpace, ActiveKeyboards, UserDefaults. Fix: declare health data collection in `NSPrivacyCollectedDataTypes` instead.
15. **`nonisolated(unsafe)` on static Logger in `@MainActor` class**: Compiles but warns "unnecessary for a constant with Sendable type Logger". Fix: move decode+error-handling into `Task { @MainActor in }` block so logger access is in MainActor context (done in `PhoneConnectivityService.swift:44-53` `didReceiveUserInfo`). Do NOT use `nonisolated(unsafe)` on Logger — restructure the code instead.
16. **`static var title` / `static var description` / `static var openAppWhenRun` on AppIntent**: Swift 6.0 strict concurrency flags `var` as non-safe mutable state. Fix: `static let` for all three. Same lesson as #7/#13 — all static properties on structs must use `let`.

## Items NOT in Scope (Already Decided)

- **L1 (Network status awareness):** CloudKit handles offline gracefully. Not needed for v1.0.
- **L3 (Water temp range):** 0–15°C covers all practical scenarios. Salt water below 0°C is too niche.
- **L4 (Professional app icon):** Current programmatic snowflake works for launch. Can be swapped later without code changes.
- **L5 (Higher quality ambient sounds):** Requires sourcing royalty-free audio. Out of scope.
- **Unit tests / CI:** Premature for solo dev first submission. Can be added post-launch.
- **Watch entitlements:** Not needed — Watch uses WatchConnectivity only, no App Groups/HealthKit/iCloud.

## Session 14 — Strengthening & Enhancement Tasks

### Priority 1: Localize New Feature Strings
The Session 13 features added new user-facing strings that need localization into all 6 languages (en, tr, de, es, fr, ja):
1. **Shortcuts/Siri phrases** in `IceDip/Intents/IceDipShortcuts.swift` — 4 phrases + shortTitle + intent description. Add to `IceDip/Resources/Localizable.xcstrings`
2. **Watch complication strings** in `IceDipWatch/Complications/WatchComplicationViews.swift` — `"day streak"`, `"sessions this week"`. Add to `IceDipWatch/Localizable.xcstrings`
3. **Watch complication config** in `IceDipWatch/Complications/IceDipWatchWidget.swift` — `"IceDip Streak"`, `"Track your cold plunge streak."`. These are `LocalizedStringResource` — add to widget extension's string catalog or `IceDipWatch/Localizable.xcstrings`

### Priority 2: Shortcuts Feature Improvements
1. **Add optional duration parameter** to `StartPlungeIntent` — `@Parameter(title: "Duration") var duration: Measurement<UnitDuration>?` so users can say "Start a 3-minute cold plunge in IceDip"
2. **Add ambient sound passthrough** to `startFromShortcut()` in `ContentView.swift:63-76` — currently doesn't pass `ambientSoundService` or `phoneConnectivityService`. Missing: ambient sound won't play, Watch won't get streak update on stop
3. **`AmbientSoundService` and `PhoneConnectivityService` not injected** — `startFromShortcut()` needs `@Environment(AmbientSoundService.self)` and `@Environment(PhoneConnectivityService.self)` added to `ContentView`, then passed to `beginSession()`

### Priority 3: Watch Complication Improvements
1. **Deep link from complication** — tapping complication should open Watch app to Timer tab. Add `.widgetURL(URL(string: "icedip://timer"))` and handle in `WatchContentView.swift`
2. **Complication localization** — `WatchComplicationViews.swift` uses `String(localized:)` but the strings need actual translations added to `IceDipWatch/Localizable.xcstrings`
3. **Weekly reset of `complication_sessionsThisWeek`** — currently only incremented, never reset. When phone sends fresh streak data it resets, but if Watch is used standalone without phone, sessions count grows indefinitely. Consider resetting on Monday via timeline provider logic

### Priority 4: Accessibility Audit
1. **VoiceOver labels** — audit all views for `.accessibilityLabel`, `.accessibilityHint`, `.accessibilityValue`
2. **Dynamic Type** — verify all views scale properly with accessibility text sizes
3. **Widget accessibility** — add `.accessibilityLabel` to widget views

### Priority 5: Additional Post-Launch Features
1. **CSV/JSON export** of session history from Settings — `SettingsView.swift` already has Data section
2. **iPad layout** — currently portrait-optimized; could add sidebar/split view
3. **App Store submission** — archive, capability registration, App Store Connect metadata

## Current File Structure (41 Swift files + resources)
```
IceDip/
├── App/
│   ├── IceDipApp.swift              # SharedModelContainer, 4 services injected, dynamic colorScheme from @AppStorage
│   └── ContentView.swift            # TabView(selection:) + onboarding gate + orphan recovery + shortcut handler + tab badge
├── Features/
│   ├── Timer/
│   │   ├── TimerView.swift          # @Bindable viewModel, breathing, ShareLink, HK + ambient + connectivity + zoneThresholds, error alerts
│   │   ├── TimerViewModel.swift     # @Observable, zone thresholds, async stop/tick, WidgetKit, HK error surfacing, streak push, os.Logger
│   │   ├── BreathingView.swift      # Animated box breathing (3 cycles), String(localized:) labels
│   │   ├── ShareCardView.swift      # Styled share card rendered to UIImage (always dark-themed)
│   │   ├── BenefitZone.swift        # Zone enum, zone(for:thresholds:), String(localized:) names (SHARED with widget + watch)
│   │   ├── ZoneGradientBackground.swift
│   │   └── ZoneIndicatorView.swift  # Accepts optional ZoneThresholds
│   ├── History/
│   │   ├── HistoryView.swift        # Zone dist + mood trend + section headers
│   │   ├── SessionCard.swift        # Mood emojis, notes display
│   │   ├── ChartView.swift          # Week/Month/All picker (LocalizedStringKey), locale-aware weekday labels, empty guard
│   │   └── ZoneDistributionView.swift
│   ├── Streak/
│   │   └── StreakView.swift          # Delegates to StreakCalculator, "Day Streak" label
│   ├── Settings/
│   │   └── SettingsView.swift       # Appearance, Timer, Zone Thresholds, Units, Feedback, Ambient, Notifications, Health, Goals, Data (Delete All), About (Show Tutorial)
│   └── Onboarding/
│       └── OnboardingView.swift     # 3-page onboarding
├── Intents/
│   ├── StartPlungeIntent.swift      # AppIntent, openAppWhenRun, sets pendingShortcutStart flag
│   └── IceDipShortcuts.swift        # AppShortcutsProvider, 4 Siri phrases, snowflake icon
├── Models/
│   ├── PlungeSession.swift          # @Model, default values for CloudKit, complete(thresholds:)
│   ├── PlungeSessionSchemaV1.swift  # V1 + V2 VersionedSchema + lightweight migration plan (shared with widget)
│   ├── UserPreferences.swift        # 15 AppStorage keys incl. colorSchemePreference, zoneThresholds
│   ├── ZoneThresholds.swift         # Codable+RawRepresentable struct (SHARED with widget + watch)
│   └── AmbientSound.swift           # Enum: ocean, rain, String(localized:) display names
├── Services/
│   ├── HapticService.swift          # Static methods for haptic feedback
│   ├── HealthKitService.swift       # @Observable, HKWorkoutBuilder, auth management, saveWorkout throws, os.Logger
│   ├── NotificationService.swift    # async cancelTimerNotifications(), localized strings, cancel-before-schedule, os.Logger
│   ├── AmbientSoundService.swift    # @Observable, AVAudioPlayer, play/pause/resume/stop, playbackFailed flag
│   └── PhoneConnectivityService.swift # WCSessionDelegate, receives Watch sessions, sends streak updates, os.Logger
└── Shared/
    ├── Theme.swift                  # Adaptive Color("Theme*") + hex zone colors, Fonts, Spacing, Animations (SHARED)
    ├── Extensions.swift             # Color(hex:), TimeInterval, Date (locale-aware formatters), moodEmoji(), temp (SHARED)
    ├── SharedModelContainer.swift   # App Group + CloudKit (.automatic for app, .none for extensions), 4-tier fallback, os.Logger (SHARED with widget)
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
│   │   └── WatchTimerViewModel.swift # @Observable, WKExtendedRuntimeSession, standalone timer, WidgetKit reload on stop
│   └── Streak/
│       └── WatchStreakView.swift     # Streak display from connectivity data
├── Services/
│   └── WatchConnectivityService.swift # WCSessionDelegate, sends sessions, receives streak, persists to UserDefaults for complication, os.Logger
├── Complications/
│   ├── WatchComplicationProvider.swift  # TimelineProvider, reads streak from UserDefaults, refreshes at midnight
│   ├── WatchComplicationViews.swift     # CircularComplicationView + RectangularComplicationView + InlineComplicationView
│   ├── IceDipWatchWidget.swift          # Widget config, StaticConfiguration, 3 accessory families
│   ├── IceDipWatchWidgetBundle.swift    # @main WidgetBundle
│   ├── Info.plist                       # com.apple.widgetkit-extension
│   └── PrivacyInfo.xcprivacy           # UserDefaults API (CA92.1)
├── PrivacyInfo.xcprivacy            # Minimal privacy manifest (no APIs, no data collection)
├── Assets.xcassets/                 # Watch app icon + Theme* adaptive color assets
├── Localizable.xcstrings           # Watch localization catalog (10 strings, en + de + es + fr + ja + tr)
└── Info.plist                       # WKCompanionAppBundleIdentifier

IceDipWidget/
├── IceDipWidgetBundle.swift         # @main widget entry point
├── IceDipWidget.swift               # PlungeEntry, PlungeTimelineProvider, IceDipWidget
├── IceDipWidgetEntryView.swift      # SmallWidgetView + MediumWidgetView (adaptive Theme.Colors)
├── IceDipWidget.entitlements        # App Group: group.com.icedip.app
├── PrivacyInfo.xcprivacy            # UserDefaults API (CA92.1), no data collection
├── Assets.xcassets/                 # Theme* adaptive color assets (ThemeBackground, ThemeSurface, ThemeIceBlue, ThemeTextPrimary, ThemeTextSecondary)
├── Localizable.xcstrings           # Widget localization catalog (4 strings, en + de + es + fr + ja + tr)
└── Info.plist                       # WidgetKit extension point

Scripts/
├── generate_icon.swift              # CoreGraphics icon generator (print() OK here)
└── generate_ambient_sounds.swift    # Generates ocean.wav + rain.wav (print() OK here)

IceDip/Resources/
├── Info.plist                       # UILaunchScreen, HealthKit usage descriptions, orientations
├── IceDip.entitlements              # App Group + HealthKit + iCloud/CloudKit
├── Localizable.xcstrings           # Main app localization catalog (96+ strings, en + de + es + fr + ja + tr)
├── PrivacyInfo.xcprivacy            # UserDefaults API + HealthAndFitness data collection declared
├── Sounds/
│   ├── ocean.wav                    # 15s ambient loop (generated)
│   └── rain.wav                     # 15s ambient loop (generated)
└── Assets.xcassets/
    ├── AppIcon.appiconset/          # AppIcon.png (1024x1024 universal snowflake)
    ├── AccentColor.colorset/        # Adaptive: dark #64D2FF, light #0891B2
    ├── LaunchBackground.colorset/   # Adaptive: dark #0A1628, light #F0F5FA
    ├── ThemeBackground.colorset/    # dark: #0A1628, light: #F0F5FA
    ├── ThemeSurface.colorset/       # dark: #111D2E, light: #FFFFFF
    ├── ThemeIceBlue.colorset/       # dark: #64D2FF, light: #0891B2
    ├── ThemeTextPrimary.colorset/   # dark: white, light: #0F172A
    └── ThemeTextSecondary.colorset/ # dark: white@60%, light: #64748B

(APP_STORE_METADATA.md + REVIEW_NOTES.md at project root)
```

## Key Architectural Decisions
- **Shared SwiftData via App Group**: `SharedModelContainer` provides single `ModelContainer` at `group.com.icedip.app/IceDip.store`. CloudKit enabled for main app, disabled for extensions. V2 schema with migration plan. 4-tier fallback prevents crashes.
- **Adaptive theme colors**: 5 theme colors + AccentColor + LaunchBackground use asset catalogs with dark/light variants. Zone colors stay hardcoded hex (same both modes). Widget and Watch both have their own `Assets.xcassets` with identical theme color sets.
- **Custom zone thresholds**: `ZoneThresholds` struct stored as JSON in AppStorage via `RawRepresentable`. Read by TimerViewModel from UserDefaults. Mirrored to app group for widget. Watch uses defaults.
- **Localization**: `String(localized:)` for non-SwiftUI computed String properties and notification content. SwiftUI `Text()` literals auto-localize via `LocalizedStringKey`. `.xcstrings` catalogs populated with 96+ strings across 6 languages (en, tr, de, es, fr, ja). `SWIFT_EMIT_LOC_STRINGS: "YES"` on all targets.
- **Structured logging**: All production error handling uses `os.Logger` with subsystem `com.icedip.app` and per-service categories (Notifications, HealthKit, Connectivity, Timer, ModelContainer). Error descriptions use `privacy: .public` (no user data).
- **StreakCalculator as shared logic**: Struct taking `[PlungeSession]`, reused by StreakView, widget, PhoneConnectivityService, TimerViewModel.
- **Service injection pattern**: All services `@MainActor @Observable`, created as `@State` in `IceDipApp`, injected via `.environment()`.
- **Watch architecture**: Standalone timer, no SwiftData, no App Groups, no entitlements. Sessions sync via `transferUserInfo()`, streak via `updateApplicationContext()`. Complications read from `UserDefaults.standard` (shared between watch app and embedded widget extension without App Groups).
- **iCloud sync**: `cloudKitDatabase: .automatic` on ModelConfiguration. Last-writer-wins conflict resolution. Widget excluded via `.appex` bundle path check.
- **Privacy manifests**: All 4 targets have `PrivacyInfo.xcprivacy` — main app (UserDefaults + HealthAndFitness collection), iOS widget (UserDefaults), Watch (empty/minimal), Watch widget (UserDefaults).
- **GDPR compliance**: "Delete All Data" in Settings deletes all SwiftData sessions, resets 14 AppStorage keys, clears app group defaults, cancels notifications. Does NOT reset `hasOnboarded`.
- **Shortcuts architecture**: `StartPlungeIntent` sets `pendingShortcutStart` flag in UserDefaults → `ContentView` observes via `@AppStorage` → calls `startFromShortcut()` which reads all preferences from UserDefaults and calls `timerViewModel.beginSession()`. Handles both cold launch (`.task`) and warm launch (`.onChange`).
- **Watch complication data flow**: Phone sends streak via `updateApplicationContext()` → `WatchConnectivityService.decodeStreakData()` persists to `UserDefaults.standard` + calls `WidgetCenter.shared.reloadAllTimelines()` → `WatchComplicationProvider.fetchEntry()` reads from UserDefaults.

## project.yml (current — 4 targets, 2 schemes)
```yaml
targets:
  IceDip:          # iOS app, embeds IceDipWidgetExtension
  IceDipWidgetExtension:  # iOS widget (App Group, SwiftData, Theme, StreakCalculator)
  IceDipWatch:     # watchOS app, excludes Complications/, embeds IceDipWatchWidgetExtension
  IceDipWatchWidgetExtension:  # watchOS complication widget (Extensions.swift shared)

schemes:
  IceDip:          # builds IceDip + IceDipWidgetExtension
  IceDipWatch:     # builds IceDipWatch + IceDipWatchWidgetExtension
```

## Design Spec
- **Dark — Background:** #0A1628 | **Surface:** #111D2E | **Accent:** #64D2FF
- **Light — Background:** #F0F5FA | **Surface:** #FFFFFF | **Accent:** #0891B2
- **Zone colors (both modes):** coldShock #FF6B35, adaptation #FFB800, dopamineZone #00E5FF, metabolicBoost #1565C0, deepResilience #B0BEC5
- **Timer font:** SF Mono 72pt light | **Headings:** SF Pro Rounded bold | **Body:** SF Pro Rounded
- **Watch timer font:** SF Mono 28pt light | **Watch heading:** SF Pro Rounded title3 bold
- **Aesthetic:** Dark, calm, premium — "luxury ice"

## Implementation Rules (unchanged)
1. Build: `xcodegen generate && xcodebuild build -scheme IceDip -destination 'generic/platform=iOS' -quiet`
2. Watch verify: `xcrun --sdk watchos swiftc -typecheck -target arm64-apple-watchos10.0 -swift-version 6 <files>`
3. Run `xcodegen generate` first if new files/directories created
4. NEVER modify `.pbxproj` directly
5. SwiftUI + SwiftData + @Observable + MVVM architecture
6. Theme: dynamic via `@AppStorage(colorSchemePreference)` — default "dark"
7. No third-party libraries
8. Swift 6.0 strict concurrency — zero warnings
9. Don't over-engineer
10. For compilation-only verification (no signing): append `CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO`
11. Simulator UUID for iPhone 16 Pro (iOS 18.4): `D35A0E8C-0FF2-46DC-86EA-F9C263D01E1B`
