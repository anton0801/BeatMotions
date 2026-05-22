import Foundation
import Combine
import AppsFlyerLib

enum Motion {
    case readPushURL
    case probeVoltage
    case maybeRefetchOrganic
    case spotConsole
}

extension Motion {
    var label: String {
        switch self {
        case .readPushURL: return "readPushURL"
        case .probeVoltage: return "probeVoltage"
        case .maybeRefetchOrganic: return "maybeRefetchOrganic"
        case .spotConsole: return "spotConsole"
        }
    }
}

enum InterpretationResult {
    case proceed(StudioState)
    case settle(MotionOutcome, StudioState)
    case fail(MotionFault)
}

@MainActor
final class MotionInterpreter {
    
    let bag: FactoryBag
    
    init(bag: FactoryBag) {
        self.bag = bag
    }
    
    func interpret(_ motion: Motion, state: StudioState) async -> InterpretationResult {
        switch motion {
        case .readPushURL:
            return interpretReadPushURL(state: state)
        case .probeVoltage:
            return await interpretProbeVoltage(state: state)
        case .maybeRefetchOrganic:
            return await interpretMaybeOrganic(state: state)
        case .spotConsole:
            return await interpretSpotConsole(state: state)
        }
    }
    
    private func interpretReadPushURL(state: StudioState) -> InterpretationResult {
        guard let pushURL = UserDefaults.standard.string(forKey: StudioKey.pushURL),
              !pushURL.isEmpty else {
            return .proceed(state)
        }
        
        let needsConsent = state.consentRipe
        
        let vault = bag.resolve((StudioVault).self)
        let newState = reduce(state, applying: .lockConsole(url: pushURL, mode: "Active"))
        vault.stash(newState.freeze())
        vault.stashConsole(url: pushURL, mode: "Active")
        vault.markPrimed()
        UserDefaults.standard.removeObject(forKey: StudioKey.pushURL)
        
        return .settle(needsConsent ? .requestConsent : .openConsole, newState)
    }
    
    private func interpretProbeVoltage(state: StudioState) async -> InterpretationResult {
        guard state.tempoReady else {
            return .settle(.soundchecking, state)
        }
        
        do {
            let valid = try await bag.resolve((VoltageProbe).self).probe()
            if !valid {
                return .fail(.voltageStatic)
            }
            return .proceed(state)
        } catch let fault as MotionFault {
            return .fail(.wrappingFault(reason: "probe", cause: fault))
        } catch {
            return .fail(.voltageStatic)
        }
    }
    
    private func interpretMaybeOrganic(state: StudioState) async -> InterpretationResult {
        guard state.organicLane && state.unmixed && !state.organicTouched else {
            return .proceed(state)
        }
        
        var working = reduce(state, applying: .markOrganicTouched)
        
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !working.locked else {
            return .proceed(working)
        }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        do {
            var fetched = try await bag.resolve((AttributionFetcher).self).fetch(deviceID: deviceID)
            
            for (k, v) in working.cues {
                if fetched[k] == nil {
                    fetched[k] = v
                }
            }
            
            let mapped = fetched.mapValues { "\($0)" }
            working = reduce(working, applying: .mergeTempo(mapped))
            
            let vault = bag.resolve((StudioVault).self)
            vault.stash(working.freeze())
        } catch {
        }
        
        return .proceed(working)
    }
    
    private func interpretSpotConsole(state: StudioState) async -> InterpretationResult {
        guard state.tempoReady else {
            return .settle(.soundchecking, state)
        }
        
        let seed = state.tempo.mapValues { $0 as Any }
        
        do {
            let url = try await bag.resolve((ConsoleFinder).self).find(seed: seed)
            
            let needsConsent = state.consentRipe
            
            let vault = bag.resolve((StudioVault).self)
            let newState = reduce(state, applying: .lockConsole(url: url, mode: "Active"))
            vault.stash(newState.freeze())
            vault.stashConsole(url: url, mode: "Active")
            vault.markPrimed()
            UserDefaults.standard.removeObject(forKey: StudioKey.pushURL)
            
            return .settle(needsConsent ? .requestConsent : .openConsole, newState)
        } catch let fault as MotionFault {
            return .fail(.wrappingFault(reason: "spotConsole", cause: fault))
        } catch {
            return .fail(.wireUnplugged(attempts: 0))
        }
    }
}

