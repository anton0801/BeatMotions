import SwiftUI
import Combine
import UserNotifications
import AVFoundation

class SessionViewModel: ObservableObject {
    
    private var audioPlayer: AVAudioPlayer?
    private var currentTrackMood: MoodType?

    @Published var isAudioPlaying: Bool = false
    @Published var audioVolume: Float = 0.8
    @Published var currentTrackName: String = ""
    @Published var audioDuration: TimeInterval = 0
    @Published var audioCurrentTime: TimeInterval = 0

    private var audioProgressTimer: Timer?

    // MARK: - Session state
    @Published var sessions: [MusicSession] = []
    @Published var currentSession: MusicSession?
    @Published var focusTimerRemaining: TimeInterval = 0
    @Published var focusTimerTotal: TimeInterval = 25 * 60
    @Published var isTimerRunning: Bool = false
    @Published var selectedDuration: TimeInterval = 25 * 60
    @Published var selectedSoundType: String = "Lo-Fi"
    @Published var sleepTimerRemaining: TimeInterval = 0
    @Published var isSleepTimerActive: Bool = false

    private var timerCancellable: AnyCancellable?
    private var sleepTimerCancellable: AnyCancellable?
    private let storageKey = "savedSessions"

    init() {
        loadSessions()
        setupAudioSession()
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup error: \(error)")
        }
    }

    // MARK: - Audio Playback
    /// Returns filename for mood (without extension). File must be in app bundle.
    private func trackName(for mood: MoodType) -> String {
        switch mood {
        case .focus:  return "focus"
        case .chill:  return "chill"
        case .energy: return "energy"
        case .night:  return "night"
        case .happy:  return "happy"
        }
    }

    func playAudio(for mood: MoodType) {
        let name = trackName(for: mood)

        // If same track already playing — just resume
        if currentTrackMood == mood, let player = audioPlayer {
            if !player.isPlaying {
                player.play()
                isAudioPlaying = true
                startProgressTimer()
            }
            return
        }

        // Load new track
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("Audio file not found: \(name).mp3 — add it to the Xcode project target")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = audioVolume
            audioPlayer?.numberOfLoops = -1 // loop infinitely
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            currentTrackMood = mood
            isAudioPlaying = true
            currentTrackName = name.capitalized
            audioDuration = audioPlayer?.duration ?? 0
            startProgressTimer()
        } catch {
            print("Audio playback error: \(error)")
        }
    }

    func pauseAudio() {
        audioPlayer?.pause()
        isAudioPlaying = false
        stopProgressTimer()
    }

    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isAudioPlaying = false
        currentTrackMood = nil
        currentTrackName = ""
        audioCurrentTime = 0
        audioDuration = 0
        stopProgressTimer()
    }

    func setVolume(_ volume: Float) {
        audioVolume = volume
        audioPlayer?.volume = volume
    }

    func togglePlayPause(mood: MoodType) {
        if isAudioPlaying {
            pauseAudio()
        } else {
            playAudio(for: mood)
        }
    }

    private func startProgressTimer() {
        stopProgressTimer()
        audioProgressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.audioCurrentTime = player.currentTime
        }
    }

    private func stopProgressTimer() {
        audioProgressTimer?.invalidate()
        audioProgressTimer = nil
    }

    // MARK: - Focus Timer
    func startFocus(duration: TimeInterval, mood: MoodType, genre: GenreType) {
        focusTimerTotal = duration
        focusTimerRemaining = duration
        isTimerRunning = true

        playAudio(for: mood)

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
        stopAudio()

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
        playAudio(for: mood)
    }

    func stopSession() {
        guard let s = currentSession else { return }
        saveSession(s)
        currentSession = nil
        stopAudio()
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
                    // Fade out in last 10 seconds
                    if self.sleepTimerRemaining <= 10 {
                        let vol = Float(self.sleepTimerRemaining / 10) * self.audioVolume
                        self.audioPlayer?.volume = vol
                    }
                } else {
                    self.isSleepTimerActive = false
                    self.sleepTimerCancellable?.cancel()
                    self.stopAudio()
                }
            }
    }

    func cancelSleepTimer() {
        sleepTimerCancellable?.cancel()
        isSleepTimerActive = false
        sleepTimerRemaining = 0
        audioPlayer?.volume = audioVolume // restore volume
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
