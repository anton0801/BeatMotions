import Foundation

protocol StudioVault {
    func stash(_ record: StudioRecord)
    func stashConsole(url: String, mode: String)
    func markPrimed()
    func thaw() -> StudioRecord
}

final class PlistBlobVault: StudioVault {
    
    private let homeStore: UserDefaults
    private let suiteStore: UserDefaults
    
    init() {
        self.homeStore = UserDefaults.standard
        self.suiteStore = UserDefaults(suiteName: StudioConstants.suiteStudio) ?? .standard
    }
    
    func stash(_ record: StudioRecord) {
        let veiled = VeiledStudio(
            tempo: veilDict(record.tempo),
            cues: veilDict(record.cues),
            consoleURL: record.consoleURL,
            consoleMode: record.consoleMode,
            unmixed: record.unmixed,
            consentTracked: record.consentTracked,
            consentMuted: record.consentMuted,
            consentLoggedAt: record.consentLoggedAt
        )
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        do {
            let blob = try encoder.encode(veiled)
            suiteStore.set(blob, forKey: StudioConstants.plistBlobKey)
            homeStore.set(blob, forKey: StudioConstants.plistBlobKey)
        } catch {
        }
    }
    
    func stashConsole(url: String, mode: String) {
        suiteStore.set(url, forKey: StudioKey.consoleURL)
        homeStore.set(url, forKey: StudioKey.consoleURL)
        suiteStore.set(mode, forKey: StudioKey.consoleMode)
    }
    
    func markPrimed() {
        suiteStore.set(true, forKey: StudioKey.primed)
        homeStore.set(true, forKey: StudioKey.primed)
    }
    
    func thaw() -> StudioRecord {
        guard let blob = suiteStore.data(forKey: StudioConstants.plistBlobKey)
            ?? homeStore.data(forKey: StudioConstants.plistBlobKey) else {
            return fallback()
        }
        
        let decoder = PropertyListDecoder()
        
        do {
            let veiled = try decoder.decode(VeiledStudio.self, from: blob)
            return StudioRecord(
                tempo: unveilDict(veiled.tempo),
                cues: unveilDict(veiled.cues),
                consoleURL: veiled.consoleURL,
                consoleMode: veiled.consoleMode,
                unmixed: veiled.unmixed,
                consentTracked: veiled.consentTracked,
                consentMuted: veiled.consentMuted,
                consentLoggedAt: veiled.consentLoggedAt
            )
        } catch {
            return fallback()
        }
    }
    
    private func fallback() -> StudioRecord {
        let consoleURL = homeStore.string(forKey: StudioKey.consoleURL)
            ?? suiteStore.string(forKey: StudioKey.consoleURL)
        let consoleMode = suiteStore.string(forKey: StudioKey.consoleMode)
        let primed = suiteStore.bool(forKey: StudioKey.primed)
        
        return StudioRecord(
            tempo: [:], cues: [:],
            consoleURL: consoleURL, consoleMode: consoleMode,
            unmixed: !primed,
            consentTracked: false, consentMuted: false, consentLoggedAt: nil
        )
    }
    
    private func veilDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = veil(v) }
        return result
    }
    
    private func unveilDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = unveil(v) ?? v }
        return result
    }
    
    private func veil(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "+", with: "%")
            .replacingOccurrences(of: "/", with: "&")
    }
    
    private func unveil(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: "%", with: "+")
            .replacingOccurrences(of: "&", with: "/")
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}

struct VeiledStudio: Codable {
    let tempo: [String: String]
    let cues: [String: String]
    let consoleURL: String?
    let consoleMode: String?
    let unmixed: Bool
    let consentTracked: Bool
    let consentMuted: Bool
    let consentLoggedAt: Date?
}
