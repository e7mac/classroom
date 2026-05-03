import Foundation

public struct OnsetDetector: Sendable {
    public struct State: Sendable, Hashable {
        public var previousRMS: Float
        public var framesSinceOnset: Int

        public init() {
            self.previousRMS = 0
            self.framesSinceOnset = .max
        }
    }

    public let energyThreshold: Float
    public let minimumFramesBetweenOnsets: Int
    public let energyRiseRatio: Float

    public init(
        energyThreshold: Float = 0.02,
        minimumFramesBetweenOnsets: Int = 4,
        energyRiseRatio: Float = 1.5
    ) {
        self.energyThreshold = energyThreshold
        self.minimumFramesBetweenOnsets = minimumFramesBetweenOnsets
        self.energyRiseRatio = energyRiseRatio
    }

    /// Process one frame's RMS value.
    /// Returns: (isOnset, newState).
    public func process(rms: Float, state: State) -> (isOnset: Bool, state: State) {
        let aboveThreshold = rms >= energyThreshold
        let aboveRise = rms >= state.previousRMS * energyRiseRatio
        let debounced = state.framesSinceOnset >= minimumFramesBetweenOnsets
        let isOnset = aboveThreshold && aboveRise && debounced

        var newState = state
        newState.previousRMS = rms
        if isOnset {
            newState.framesSinceOnset = 0
        } else if state.framesSinceOnset != .max {
            newState.framesSinceOnset = state.framesSinceOnset + 1
        }
        return (isOnset, newState)
    }
}
