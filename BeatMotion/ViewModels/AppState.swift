import SwiftUI
import Combine

class AppState: ObservableObject {
    @AppStorage("colorSchemeRaw") var colorSchemeRaw: String = "dark"
    @AppStorage("currentMoodRaw") private var currentMoodRaw: String = MoodType.focus.rawValue
    @AppStorage("activeNeonThemeData") private var activeNeonThemeData: Data = (try? JSONEncoder().encode(NeonTheme.defaults[0])) ?? Data()

    @Published var currentMood: MoodType = .focus
    @Published var activeNeonTheme: NeonTheme = NeonTheme.defaults[0]
    @Published var isSessionActive: Bool = false
    @Published var activeSessionMode: MusicSession.SessionMode = .free
    @Published var currentBPM: Double = 80
    @Published var visualizerLevel: Double = 0.5

    var colorScheme: ColorScheme? {
        switch colorSchemeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    init() {
        currentMood = MoodType(rawValue: currentMoodRaw) ?? .focus
        if let decoded = try? JSONDecoder().decode(NeonTheme.self, from: activeNeonThemeData) {
            activeNeonTheme = decoded
        }
    }

    func setMood(_ mood: MoodType) {
        currentMood = mood
        currentMoodRaw = mood.rawValue
    }

    func setColorScheme(_ scheme: String) {
        colorSchemeRaw = scheme
        objectWillChange.send()
    }

    func setNeonTheme(_ theme: NeonTheme) {
        activeNeonTheme = theme
        if let data = try? JSONEncoder().encode(theme) {
            activeNeonThemeData = data
        }
    }
}
