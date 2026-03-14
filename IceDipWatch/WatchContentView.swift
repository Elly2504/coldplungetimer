import SwiftUI

struct WatchContentView: View {
    @State private var selectedTab = 0

    var body: some View {
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
    }
}
