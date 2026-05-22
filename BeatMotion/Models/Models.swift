import SwiftUI
import Foundation

indirect enum MotionFault: Error {
    case staticHum
    case emptyTempo
    case consoleRejected(httpCode: Int)
    case voltageStatic
    case packetGarbled(stage: String)
    case wireUnplugged(attempts: Int)
    case feedbackLoop(retryAfter: TimeInterval)
    case beatDropped
    
    case wrappingFault(reason: String, cause: MotionFault)
    case combinedFault(left: MotionFault, right: MotionFault)
    
    var topLabel: String {
        switch self {
        case .staticHum: return "staticHum"
        case .emptyTempo: return "emptyTempo"
        case .consoleRejected: return "consoleRejected"
        case .voltageStatic: return "voltageStatic"
        case .packetGarbled: return "packetGarbled"
        case .wireUnplugged: return "wireUnplugged"
        case .feedbackLoop: return "feedbackLoop"
        case .beatDropped: return "beatDropped"
        case .wrappingFault: return "wrappingFault"
        case .combinedFault: return "combinedFault"
        }
    }
    
    var unrolled: [String] {
        switch self {
        case .wrappingFault(let reason, let cause):
            return ["wrappingFault(\(reason))"] + cause.unrolled
        case .combinedFault(let left, let right):
            return ["combinedFault"] + left.unrolled + right.unrolled
        default:
            return [topLabel]
        }
    }
}

struct MusicSession: Identifiable, Codable {
    var id: UUID = UUID()
    var mood: MoodType
    var duration: TimeInterval  // seconds
    var date: Date
    var mode: SessionMode
    var genre: GenreType
    var intensity: IntensityLevel
    var energyScore: Double // 0-100

    enum SessionMode: String, Codable, CaseIterable {
        case focus  = "Focus"
        case relax  = "Relax"
        case energy = "Energy"
        case free   = "Free"
    }
}

struct StudioKey {
    static let consoleURL = "bm_console_url"
    static let consoleMode = "bm_console_mode"
    static let primed = "bm_primed"
    
    // Legacy
    static let pushURL = "temp_url"
    static let fcm = "fcm_token"
    static let push = "push_token"
}

struct Playlist: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var mood: MoodType
    var duration: TimeInterval
    var trackCount: Int
    var genre: GenreType
    var intensity: IntensityLevel
    var createdAt: Date
    var isFavorite: Bool = false
    var colorIndex: Int = 0

    var durationString: String {
        let mins = Int(duration) / 60
        return "\(mins) min"
    }
}

// MARK: - Track Note
struct TrackNote: Identifiable, Codable {
    var id: UUID = UUID()
    var trackName: String
    var moodNote: String
    var rating: Int // 1-5
    var mood: MoodType
    var date: Date
}

// MARK: - Genre
enum GenreType: String, CaseIterable, Codable {
    case lofi       = "Lo-Fi"
    case ambient    = "Ambient"
    case electronic = "Electronic"
    case classical  = "Classical"
    case hiphop     = "Hip-Hop"
    case jazz       = "Jazz"
    case rock       = "Rock"
    case pop        = "Pop"
}

// MARK: - Intensity
enum IntensityLevel: String, CaseIterable, Codable {
    case low    = "Low"
    case medium = "Medium"
    case high   = "High"
}

enum MotionEffect {
    case ingestTempo([String: String])
    case ingestCues([String: String])
    case markOrganicTouched
    case mergeTempo([String: String])
    case lockConsole(url: String, mode: String)
    case stampConsent(granted: Bool, at: Date)
    case noop
}

struct NeonTheme: Codable, Equatable {
    var primaryHex: String
    var secondaryHex: String
    var animationSpeed: Double // 0.5 - 3.0
    var name: String

    static let defaults: [NeonTheme] = [
        NeonTheme(primaryHex: "#8B5CF6", secondaryHex: "#EC4899", animationSpeed: 1.0, name: "Violet Dreams"),
        NeonTheme(primaryHex: "#22D3EE", secondaryHex: "#8B5CF6", animationSpeed: 1.2, name: "Cyber Wave"),
        NeonTheme(primaryHex: "#F97316", secondaryHex: "#EC4899", animationSpeed: 0.8, name: "Solar Flare"),
        NeonTheme(primaryHex: "#10B981", secondaryHex: "#22D3EE", animationSpeed: 1.5, name: "Aurora"),
    ]

    var primaryColor: Color { Color(hex: primaryHex) }
    var secondaryColor: Color { Color(hex: secondaryHex) }
}

// MARK: - Daily Stats
struct DayStats: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var minutesListened: Double
    var dominantMood: MoodType
    var focusSessions: Int
    var energyScore: Double
}

struct NotificationConfig: Codable {
    var focusReminder: Bool = true
    var focusReminderHour: Int = 10
    var relaxReminder: Bool = false
    var relaxReminderHour: Int = 20
    var dailyMoodCheck: Bool = true
    var dailyMoodCheckHour: Int = 9
}

struct StudioRecord: Codable {
    let tempo: [String: String]
    let cues: [String: String]
    let consoleURL: String?
    let consoleMode: String?
    let unmixed: Bool
    let consentTracked: Bool
    let consentMuted: Bool
    let consentLoggedAt: Date?
}

enum MotionOutcome {
    case soundchecking
    case requestConsent
    case openConsole
    case fadedToBackstage
}
