import SwiftUI

@main
struct BeatMotionApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var playlistVM = PlaylistViewModel()
    @StateObject private var statsVM = StatsViewModel()
    @StateObject private var sessionVM = SessionViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(playlistVM)
                .environmentObject(statsVM)
                .environmentObject(sessionVM)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView(isVisible: $showSplash)
                    .transition(.identity)
            } else if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
    }
}
