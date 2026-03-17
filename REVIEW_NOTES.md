# IceDip — App Store Review Notes

## Demo Account

Not applicable. IceDip does not require login or account creation.

## HealthKit Usage

IceDip saves cold plunge sessions as workouts in Apple Health using `HKWorkoutActivityType.other`.

- **Read:** Not used. The app does not read existing Health data.
- **Write:** Session duration saved as a workout when the user completes a cold plunge.
- **Permission:** Requested only when the user enables "Save to Apple Health" in Settings > Health. The toggle is off by default.
- **Usage descriptions** (in Info.plist):
  - Share: "IceDip reads your health data to show your cold plunge history alongside other workouts."
  - Update: "IceDip saves your cold plunge sessions as workouts in Apple Health."

If HealthKit permission is denied, the app functions normally — sessions are still saved locally. A non-blocking alert is shown if a Health save fails.

## iCloud / CloudKit

- Session data syncs across the user's devices via CloudKit (automatic configuration).
- No server-side processing. No custom CloudKit dashboard logic.
- Conflict resolution: last-writer-wins (CloudKit default).
- Widget extension does not use CloudKit (read-only from shared App Group container).

## Notifications

Two types of local notifications are used:

1. **Timer completion** — Fires when a cold plunge timer reaches zero (foreground/background). One-time, non-repeating.
2. **Daily reminder** — Optional repeating notification at a user-configured time. Enabled/disabled via Settings > Notifications.

No push notifications. No remote notification server.

## Background Modes

None. The app does not use any background modes. Timer completion notifications are scheduled via `UNTimeIntervalNotificationTrigger` when the timer starts.

## Data Collection & Privacy

- **Collected data type:** Health & Fitness (session duration, water temperature, mood rating)
- **Purpose:** App functionality only
- **Linked to identity:** No
- **Used for tracking:** No
- **Third-party analytics:** None
- **Advertising:** None

Declared in `PrivacyInfo.xcprivacy` under `NSPrivacyCollectedDataTypes`.

## Data Deletion

Users can delete all their data via **Settings > Data > Delete All Data**. This action:

- Deletes all PlungeSession records from SwiftData
- Resets all user preferences (AppStorage keys)
- Clears shared App Group UserDefaults
- Cancels all pending notifications
- Does NOT require re-onboarding (the onboarding flag is preserved)

This satisfies GDPR Article 17 (Right to Erasure) and App Store Review Guideline 5.1.1(v).

## In-App Purchases

IceDip uses a freemium model with two auto-renewable subscriptions in the "IceDip Pro" subscription group:

- **Pro Monthly** (`com.icedip.app.pro.monthly`) — $2.99/month
- **Pro Yearly** (`com.icedip.app.pro.yearly`) — $19.99/year

**How to find the subscription offer:**
1. Open the app.
2. Go to the **Settings** tab (gear icon).
3. Tap **"Upgrade to Pro"** in the "IceDip Pro" section.
4. The paywall screen displays both subscription options with pricing.

**What Pro unlocks:** Unlimited History & Charts, Breathing Exercise, Ambient Sounds, Apple Watch & Widget, Siri Shortcuts & HealthKit, iCloud Sync & CSV Export, Custom Zones & Themes.

Free users can use the core timer, view 7 days of history, and track streaks. Pro-only features show a lock overlay prompting upgrade.

**Terms of Use (EULA):** The app uses Apple's Standard EULA. A link is displayed in the paywall and in the App Store description.
**Privacy Policy:** https://elly2504.github.io/coldplungetimer/privacy/

## Third-Party Libraries

None. The app uses only Apple frameworks: SwiftUI, SwiftData, HealthKit, CloudKit, WidgetKit, WatchConnectivity, AVFoundation, UserNotifications.

## Supported Languages

English (source), German, Spanish, French, Japanese, Turkish.

## Apple Watch

The companion watchOS app provides a standalone cold plunge timer. Sessions started on the Watch sync to the iPhone via WatchConnectivity (`transferUserInfo`). The Watch app does not use SwiftData or CloudKit directly.

## Minimum Requirements

- iOS 17.0+
- watchOS 10.0+
