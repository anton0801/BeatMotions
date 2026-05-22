import SwiftUI


struct StudioConstants {
    static let appCode = "6771043626"
    static let trackerKey = "KwkBqT8BezMpkEdNdCo2hR"
    static let suiteStudio = "group.beatmotions.studio"
    static let logBeat = "🎶 [BeatMotions]"
    static let cookieConsole = "beatmotions_console"
    static let backendSoundboard = "https://beattmotion.com/config.php"
    static let plistBlobKey = "bm_studio_blob"
}


@main
struct BeatMotionApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var playlistVM = PlaylistViewModel()
    @StateObject private var statsVM = StatsViewModel()
    @StateObject private var sessionVM = SessionViewModel()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegator

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(appState)
                .environmentObject(playlistVM)
                .environmentObject(statsVM)
                .environmentObject(sessionVM)
        }
    }
}

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
        .preferredColorScheme(appState.colorScheme)
    }
}
