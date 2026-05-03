import Foundation
import Testing
@testable import AudioInput

@Suite
struct OnsetDetectorTests {

    @Test func initialStateLowRMSGivesNoOnset() {
        let det = OnsetDetector()
        let (isOnset, _) = det.process(rms: 0.001, state: OnsetDetector.State())
        #expect(!isOnset)
    }

    @Test func suddenRiseAboveThresholdTriggersOnset() {
        let det = OnsetDetector()
        // Establish a low previous RMS first so the rise ratio test passes.
        var (_, state) = det.process(rms: 0.001, state: OnsetDetector.State())
        let (isOnset, _) = det.process(rms: 0.5, state: state)
        #expect(isOnset)
        _ = state
    }

    @Test func sustainedHighRMSDoesNotRetrigger() {
        let det = OnsetDetector()
        var state = OnsetDetector.State()
        (_, state) = det.process(rms: 0.001, state: state)
        var (isOnset, newState) = det.process(rms: 0.5, state: state)
        #expect(isOnset)
        state = newState
        // Stay at 0.5 for several frames — should not retrigger (no rise + debounce).
        for _ in 0..<5 {
            (isOnset, newState) = det.process(rms: 0.5, state: state)
            state = newState
            #expect(!isOnset)
        }
    }

    @Test func afterDebounceFramesNewRiseTriggers() {
        let det = OnsetDetector(minimumFramesBetweenOnsets: 4, energyRiseRatio: 1.5)
        var state = OnsetDetector.State()
        (_, state) = det.process(rms: 0.001, state: state)
        var (isOnset, newState) = det.process(rms: 0.3, state: state)
        #expect(isOnset)
        state = newState
        // Decay to a low RMS for several frames so rise can re-trigger.
        for _ in 0..<5 {
            (_, newState) = det.process(rms: 0.05, state: state)
            state = newState
        }
        (isOnset, _) = det.process(rms: 0.6, state: state)
        #expect(isOnset)
    }

    @Test func riseBelowRatioDoesNotTrigger() {
        let det = OnsetDetector(energyRiseRatio: 2.0)
        var state = OnsetDetector.State()
        (_, state) = det.process(rms: 0.1, state: state)
        // 0.1 → 0.15 is only a 1.5x rise; below 2.0 → no onset.
        let (isOnset, _) = det.process(rms: 0.15, state: state)
        #expect(!isOnset)
    }
}
