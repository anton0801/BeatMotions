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

    var totalMinutes: Double {
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
