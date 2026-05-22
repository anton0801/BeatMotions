import Foundation
import AppsFlyerLib
import Combine

@MainActor
final class MotionConductor {
    
    @Published private(set) var state: StudioState = .initial
    
    private let outcomeSubject = PassthroughSubject<MotionOutcome, Never>()
    var outcomePublisher: AnyPublisher<MotionOutcome, Never> {
        outcomeSubject.eraseToAnyPublisher()
    }
    
    private var sequenceCompleted: Bool = false
    
    private let bag: FactoryBag
    private let interpreter: MotionInterpreter
    private var cancellables = Set<AnyCancellable>()
    
    init(bag: FactoryBag = .production()) {
        self.bag = bag
        self.interpreter = MotionInterpreter(bag: bag)
    }
    
    func warmUp() {
        let record = bag.resolve((StudioVault).self).thaw()
        state = StudioState.hydrate(from: record)
    }
    
    func ingestTempo(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        state = reduce(state, applying: .ingestTempo(mapped))
        bag.resolve((StudioVault).self).stash(state.freeze())
    }
    
    func ingestCues(_ raw: [String: Any]) {
        let mapped = raw.mapValues { "\($0)" }
        state = reduce(state, applying: .ingestCues(mapped))
        bag.resolve((StudioVault).self).stash(state.freeze())
    }
    
    func conduct() async {
        guard !sequenceCompleted else { return }
        
        let script: [Motion] = [
            .readPushURL,
            .probeVoltage,
            .maybeRefetchOrganic,
            .spotConsole
        ]
        
        var working = state
        
        for motion in script {
            if sequenceCompleted { return }
            
            let result = await interpreter.interpret(motion, state: working)
            
            switch result {
            case .proceed(let newState):
                working = newState
                state = newState
                continue
                
            case .settle(let outcome, let newState):
                state = newState
                if case .soundchecking = outcome {
                    return
                }
                sequenceCompleted = true
                outcomeSubject.send(outcome)
                return
                
            case .fail(let fault):
                sequenceCompleted = true
                outcomeSubject.send(.fadedToBackstage)
                return
            }
        }
    }
    
    func acceptConsent(callback: @escaping () -> Void) {
        let priorTracked = state.consentTracked
        let priorMuted = state.consentMuted
        
        bag.resolve((ConsentSinger).self)
            .sing()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] granted in
                guard let self = self else { return }
                
                let now = Date()
                self.state = reduce(self.state, applying: .stampConsent(granted: granted, at: now))
                
                if granted {
                    self.bag.resolve((ConsentSinger).self).armPushNotifications()
                }
                
                _ = priorTracked
                _ = priorMuted
                
                self.bag.resolve((StudioVault).self).stash(self.state.freeze())
                self.outcomeSubject.send(.openConsole)
                callback()
            }
            .store(in: &cancellables)
    }
    
    func deferConsent() {
        let now = Date()
        state = StudioState(
            tempo: state.tempo, cues: state.cues,
            consoleURL: state.consoleURL, consoleMode: state.consoleMode,
            unmixed: state.unmixed, locked: state.locked, organicTouched: state.organicTouched,
            consentTracked: state.consentTracked, consentMuted: state.consentMuted,
            consentLoggedAt: now
        )
        bag.resolve((StudioVault).self).stash(state.freeze())
        outcomeSubject.send(.openConsole)
    }
    
    func reportBeatDropped() -> Bool {
        guard !sequenceCompleted else {
            return false
        }
        sequenceCompleted = true
        return true
    }
}
