import SwiftUI

struct WatchContentView: View {
    @Environment(WatchConnectivityService.self) private var connectivityService
    @State private var selectedTab = 0

    var body: some View {
        if connectivityService.isProUser {
            TabView(selection: $selectedTab) {
                WatchTimerView()
                    .tag(0)
                WatchStreakView()
                    .tag(1)
            }
            .tabViewStyle(.verticalPage)
            .onOpenURL { url in
                if url.host == "timer" {
                    selectedTab = 0
                }
            }
        } else {
            WatchProLockedView()
        }
    }
}

// MARK: - Pro Locked View

struct WatchProLockedView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "snowflake")
                .font(.system(size: 36))
                .foregroundStyle(Theme.Colors.iceBlue)

            Text("IceDip Pro")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Upgrade on iPhone to unlock Apple Watch")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(Theme.Colors.background.gradient, for: .navigation)
    }
}
