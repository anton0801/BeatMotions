import Foundation

struct StudioState {
    let tempo: [String: String]
    let cues: [String: String]
    let consoleURL: String?
    let consoleMode: String?
    let unmixed: Bool
    let locked: Bool
    let organicTouched: Bool
    let consentTracked: Bool
    let consentMuted: Bool
    let consentLoggedAt: Date?
    
    static let initial = StudioState(
        tempo: [:], cues: [:],
        consoleURL: nil, consoleMode: nil,
        unmixed: true, locked: false, organicTouched: false,
        consentTracked: false, consentMuted: false, consentLoggedAt: nil
    )
    
    var tempoReady: Bool { !tempo.isEmpty }
    var organicLane: Bool { tempo["af_status"] == "Organic" }
    
    var consentRipe: Bool {
        guard !consentTracked && !consentMuted else { return false }
        if let date = consentLoggedAt {
            let elapsed = Date().timeIntervalSince(date) / 86400
            return elapsed >= 3
        }
        return true
    }
    
    static func hydrate(from record: StudioRecord) -> StudioState {
        StudioState(
            tempo: record.tempo, cues: record.cues,
            consoleURL: record.consoleURL, consoleMode: record.consoleMode,
            unmixed: record.unmixed, locked: false, organicTouched: false,
            consentTracked: record.consentTracked, consentMuted: record.consentMuted,
            consentLoggedAt: record.consentLoggedAt
        )
    }
    
    func freeze() -> StudioRecord {
        StudioRecord(
            tempo: tempo, cues: cues,
            consoleURL: consoleURL, consoleMode: consoleMode,
            unmixed: unmixed,
            consentTracked: consentTracked, consentMuted: consentMuted,
            consentLoggedAt: consentLoggedAt
        )
    }
}

func reduce(_ state: StudioState, applying effect: MotionEffect) -> StudioState {
    switch effect {
    case .ingestTempo(let kv):
        return StudioState(
            tempo: kv, cues: state.cues,
            consoleURL: state.consoleURL, consoleMode: state.consoleMode,
            unmixed: state.unmixed, locked: state.locked, organicTouched: state.organicTouched,
            consentTracked: state.consentTracked, consentMuted: state.consentMuted,
            consentLoggedAt: state.consentLoggedAt
        )
        
    case .ingestCues(let kv):
        return StudioState(
            tempo: state.tempo, cues: kv,
            consoleURL: state.consoleURL, consoleMode: state.consoleMode,
            unmixed: state.unmixed, locked: state.locked, organicTouched: state.organicTouched,
            consentTracked: state.consentTracked, consentMuted: state.consentMuted,
            consentLoggedAt: state.consentLoggedAt
        )
        
    case .markOrganicTouched:
        return StudioState(
            tempo: state.tempo, cues: state.cues,
            consoleURL: state.consoleURL, consoleMode: state.consoleMode,
            unmixed: state.unmixed, locked: state.locked, organicTouched: true,
            consentTracked: state.consentTracked, consentMuted: state.consentMuted,
            consentLoggedAt: state.consentLoggedAt
        )
        
    case .mergeTempo(let kv):
        return StudioState(
            tempo: kv, cues: state.cues,
            consoleURL: state.consoleURL, consoleMode: state.consoleMode,
            unmixed: state.unmixed, locked: state.locked, organicTouched: state.organicTouched,
            consentTracked: state.consentTracked, consentMuted: state.consentMuted,
            consentLoggedAt: state.consentLoggedAt
        )
        
    case .lockConsole(let url, let mode):
        return StudioState(
            tempo: state.tempo, cues: state.cues,
            consoleURL: url, consoleMode: mode,
            unmixed: false, locked: true, organicTouched: state.organicTouched,
            consentTracked: state.consentTracked, consentMuted: state.consentMuted,
            consentLoggedAt: state.consentLoggedAt
        )
        
    case .stampConsent(let granted, let at):
        return StudioState(
            tempo: state.tempo, cues: state.cues,
            consoleURL: state.consoleURL, consoleMode: state.consoleMode,
            unmixed: state.unmixed, locked: state.locked, organicTouched: state.organicTouched,
            consentTracked: granted, consentMuted: !granted,
            consentLoggedAt: at
        )
        
    case .noop:
        return state
    }
}
