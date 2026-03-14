import SwiftUI

struct ProGateModifier: ViewModifier {
    let isProUser: Bool
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        if isProUser {
            content
        } else {
            content
                .blur(radius: 6)
                .allowsHitTesting(false)
                .overlay {
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "lock.fill")
                            .font(.title)
                            .foregroundStyle(Theme.Colors.iceBlue)
                        Text("Pro Feature")
                            .font(Theme.Fonts.headingSmall)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text("Upgrade to unlock")
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(Theme.Spacing.lg)
                    .background(Theme.Colors.surface.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .contentShape(Rectangle())
                .onTapGesture { showPaywall = true }
                .sheet(isPresented: $showPaywall) {
                    ProPaywallView()
                }
        }
    }
}

extension View {
    func proGated(isProUser: Bool) -> some View {
        modifier(ProGateModifier(isProUser: isProUser))
    }
}
