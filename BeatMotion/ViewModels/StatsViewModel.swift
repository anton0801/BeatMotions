import SwiftUI
import Combine

class StatsViewModel: ObservableObject {
    @Published var period: StatPeriod = .week
    @Published var dayStats: [DayStats] = []

    enum StatPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }

    init() {
        generateSampleStats()
    }

    func generateSampleStats() {
        var stats: [DayStats] = []
        let moods: [MoodType] = [.focus, .chill, .energy, .night, .happy]
        for i in 0..<30 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let stat = DayStats(
                date: date,
                minutesListened: Double.random(in: 15...120),
                dominantMood: moods[i % moods.count],
                focusSessions: Int.random(in: 0...5),
                energyScore: Double.random(in: 30...95)
            )
            stats.append(stat)
        }
        dayStats = stats
    }

    var filteredStats: [DayStats] {
        let cal = Calendar.current
        switch period {
        case .week:
            let cutoff = cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return dayStats.filter { $0.date >= cutoff }.reversed()
        case .month:
            let cutoff = cal.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            return dayStats.filter { $0.date >= cutoff }.reversed()
        case .all:
            return dayStats.reversed()
        }
    }

    var filteredStats2: [DayStats] {
        let cal = Calendar.current
        switch period {
        case .week:
            let cutoff = cal.date(byAdding: .day, value: -5, to: Date()) ?? Date()
            return dayStats.filter { $0.date >= cutoff }.reversed()
        case .month:
            let cutoff = cal.date(byAdding: .day, value: -24, to: Date()) ?? Date()
            return dayStats.filter { $0.date >= cutoff }.reversed()
        case .all:
            return dayStats.reversed()
        }
    }

    var totalMinutes: Double {
        filteredStats.reduce(0) { $0 + $1.minutesListened }
    }

    var totalMinutes2: Double {
        filteredStats.reduce(0) { $0 + $1.minutesListened }
    }

    var totalFocusSessions: Int {
        filteredStats.reduce(0) { $0 + $1.focusSessions }
    }

    var avgEnergy: Double {
        guard !filteredStats.isEmpty else { return 0 }
        return filteredStats.reduce(0) { $0 + $1.energyScore } / Double(filteredStats.count)
    }

    var moodUsage: [(MoodType, Int)] {
        var counts: [MoodType: Int] = [:]
        for stat in filteredStats {
            counts[stat.dominantMood, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    func energyData(for period: StatPeriod) -> [Double] {
        filteredStats.map { $0.energyScore }
    }

    func minutesData(for period: StatPeriod) -> [Double] {
        filteredStats.map { $0.minutesListened }
    }
}

@MainActor
final class BeatMotionsViewModel: ObservableObject {

    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    private let conductor: MotionConductor
    private var cancellables = Set<AnyCancellable>()
    private var deadlineTask: Task<Void, Never>?
    
    private var uiLocked: Bool = false
    
    init() {
        self.conductor = MotionConductor()
        wireUp()
    }
    
    deinit {
        deadlineTask?.cancel()
    }
    
    private func wireUp() {
        conductor.outcomePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] outcome in
                self?.handleOutcome(outcome)
            }
            .store(in: &cancellables)
    }
    
    func boot() {
        conductor.warmUp()
        armDeadline()
    }
    
    func ingestAttribution(_ data: [String: Any]) {
        Task {
            conductor.ingestTempo(data)
            await conductor.conduct()
        }
    }
    
    func ingestDeeplinks(_ data: [String: Any]) {
        conductor.ingestCues(data)
    }
    
    func acceptConsent() {
        conductor.acceptConsent {
            self.showPermissionPrompt = false
        }
    }
    
    func skipConsent() {
        conductor.deferConsent()
        showPermissionPrompt = false
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        showOfflineView = !connected
    }
    
    private func handleOutcome(_ outcome: MotionOutcome) {
        guard !uiLocked else {
            return
        }
        
        switch outcome {
        case .soundchecking:
            break
        case .requestConsent:
            showPermissionPrompt = true
        case .openConsole:
            navigateToWeb = true
        case .fadedToBackstage:
            navigateToMain = true
        }
    }
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard let self = self else { return }
            
            let shouldFire = self.conductor.reportBeatDropped()
            if shouldFire {
                self.handleOutcome(.fadedToBackstage)
            }
        }
    }
}
