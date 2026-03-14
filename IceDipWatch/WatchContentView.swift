import SwiftUI

struct WatchContentView: View {
    var body: some View {
        TabView {
            WatchTimerView()
            WatchStreakView()
        }
        .tabViewStyle(.verticalPage)
    }
}
