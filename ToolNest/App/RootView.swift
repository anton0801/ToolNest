import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true
    @State private var splashDone = false

    var body: some View {
        ZStack {
            if showSplash {
                SplashView(isVisible: $showSplash)
                    .transition(.identity)
                    .zIndex(2)
            } else if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                MainTabView()
                    .transition(.opacity)
                    .zIndex(0)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .animation(.easeInOut(duration: 0.4), value: appState.hasCompletedOnboarding)
    }
}
