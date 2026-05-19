import SwiftUI
import Combine
import UserNotifications

class SessionViewModel: ObservableObject {
    @Published var sessions: [MusicSession] = []
    @Published var currentSession: MusicSession?
    @Published var focusTimerRemaining: TimeInterval = 0
    @Published var focusTimerTotal: TimeInterval = 25 * 60
    @Published var isTimerRunning: Bool = false
    @Published var selectedDuration: TimeInterval = 25 * 60  // 25 min
    @Published var selectedSoundType: String = "Lo-Fi"
    @Published var sleepTimerRemaining: TimeInterval = 0
    @Published var isSleepTimerActive: Bool = false

    private var timerCancellable: AnyCancellable?
    private var sleepTimerCancellable: AnyCancellable?
    private let storageKey = "savedSessions"

    init() {
        loadSessions()
    }

    // MARK: - Focus Timer
    func startFocus(duration: TimeInterval, mood: MoodType, genre: GenreType) {
        focusTimerTotal = duration
        focusTimerRemaining = duration
        isTimerRunning = true

        let session = MusicSession(
            mood: mood,
            duration: duration,
            date: Date(),
            mode: .focus,
            genre: genre,
            intensity: .medium,
            energyScore: Double.random(in: 50...85)
        )
        currentSession = session

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.focusTimerRemaining > 0 {
                    self.focusTimerRemaining -= 1
                } else {
                    self.stopFocus(completed: true, mood: mood, genre: genre)
                }
            }
    }

    func stopFocus(completed: Bool, mood: MoodType, genre: GenreType) {
        timerCancellable?.cancel()
        isTimerRunning = false

        let elapsed = focusTimerTotal - focusTimerRemaining
        if elapsed > 30 {
            let session = MusicSession(
                mood: mood,
                duration: elapsed,
                date: Date(),
                mode: .focus,
                genre: genre,
                intensity: .medium,
                energyScore: Double.random(in: 50...90)
            )
            saveSession(session)
        }
        currentSession = nil
        focusTimerRemaining = 0
    }

    // MARK: - Relax / Free Session
    func startSession(mood: MoodType, mode: MusicSession.SessionMode, genre: GenreType, duration: TimeInterval) {
        let session = MusicSession(
            mood: mood,
            duration: duration,
            date: Date(),
            mode: mode,
            genre: genre,
            intensity: .low,
            energyScore: Double.random(in: 30...70)
        )
        currentSession = session
    }

    func stopSession() {
        guard let s = currentSession else { return }
        saveSession(s)
        currentSession = nil
    }

    // MARK: - Sleep Timer
    func startSleepTimer(minutes: Double) {
        sleepTimerRemaining = minutes * 60
        isSleepTimerActive = true

        sleepTimerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.sleepTimerRemaining > 0 {
                    self.sleepTimerRemaining -= 1
                } else {
                    self.isSleepTimerActive = false
                    self.sleepTimerCancellable?.cancel()
                }
            }
    }

    func cancelSleepTimer() {
        sleepTimerCancellable?.cancel()
        isSleepTimerActive = false
        sleepTimerRemaining = 0
    }

    // MARK: - Persistence
    private func saveSession(_ session: MusicSession) {
        sessions.insert(session, at: 0)
        persistSessions()
    }

    private func persistSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([MusicSession].self, from: data) {
            sessions = decoded
        } else {
            sessions = SessionViewModel.sampleSessions()
        }
    }

    func deleteSession(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        persistSessions()
    }

    // MARK: - Stats helpers
    var todaySessionCount: Int {
        let cal = Calendar.current
        return sessions.filter { cal.isDateInToday($0.date) }.count
    }

    var todayMinutes: Double {
        let cal = Calendar.current
        return sessions.filter { cal.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.duration / 60 }
    }

    var currentStreak: Int {
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: Date())
        for _ in 0..<30 {
            let has = sessions.contains {
                Calendar.current.isDate($0.date, inSameDayAs: checkDate)
            }
            if has { streak += 1 } else { break }
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }

    var timerProgress: Double {
        guard focusTimerTotal > 0 else { return 0 }
        return 1 - (focusTimerRemaining / focusTimerTotal)
    }

    var formattedTimer: String {
        let mins = Int(focusTimerRemaining) / 60
        let secs = Int(focusTimerRemaining) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var formattedSleepTimer: String {
        let mins = Int(sleepTimerRemaining) / 60
        let secs = Int(sleepTimerRemaining) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    // MARK: - Sample Data
    static func sampleSessions() -> [MusicSession] {
        let moods: [MoodType] = [.focus, .chill, .energy, .night, .happy]
        let modes: [MusicSession.SessionMode] = [.focus, .relax, .energy, .free]
        let genres: [GenreType] = [.lofi, .ambient, .electronic, .jazz]
        var result: [MusicSession] = []
        for i in 0..<20 {
            let daysAgo = Double(i / 2)
            let date = Calendar.current.date(byAdding: .day, value: -Int(daysAgo), to: Date()) ?? Date()
            let session = MusicSession(
                mood: moods[i % moods.count],
                duration: Double([15, 25, 30, 45, 60][i % 5]) * 60,
                date: date,
                mode: modes[i % modes.count],
                genre: genres[i % genres.count],
                intensity: IntensityLevel.allCases[i % 3],
                energyScore: Double.random(in: 40...95)
            )
            result.append(session)
        }
        return result
    }
}
