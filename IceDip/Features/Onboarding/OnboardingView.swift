import SwiftUI

struct OnboardingView: View {
    @AppStorage(PreferenceKey.hasOnboarded) private var hasOnboarded = false
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            TabView(selection: $currentPage) {
                onboardingPage(
                    icon: "snowflake",
                    title: "Welcome to IceDip",
                    subtitle: "Track your cold plunge sessions and build resilience through consistent cold exposure.",
                    page: 0
                )
                .tag(0)

                onboardingPage(
                    icon: "brain.head.profile",
                    title: "Science-Backed Zones",
                    subtitle: "See real-time benefit zones as you progress through your plunge \u{2014} from cold shock to deep resilience.",
                    page: 1
                )
                .tag(1)

                onboardingPage(
                    icon: "flame.fill",
                    title: "Build Your Streak",
                    subtitle: "Track your consistency, set weekly goals, and watch your cold tolerance grow over time.",
                    page: 2,
                    showGetStarted: true
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    private func onboardingPage(
        icon: String,
        title: String,
        subtitle: String,
        page: Int,
        showGetStarted: Bool = false
    ) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(Theme.Colors.iceBlue)

            Text(title)
                .font(Theme.Fonts.heading)
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Spacer()

            if showGetStarted {
                Button {
                    hasOnboarded = true
                } label: {
                    Text("Get Started")
                        .font(Theme.Fonts.headingSmall)
                        .foregroundStyle(Theme.Colors.background)
                        .frame(width: 200, height: 56)
                        .background(Theme.Colors.iceBlue)
                        .clipShape(Capsule())
                }
                .padding(.bottom, Theme.Spacing.xxl)
            } else {
                Color.clear.frame(height: 56)
                    .padding(.bottom, Theme.Spacing.xxl)
            }
        }
    }
}
