import Foundation

/// Pure pitch detection: feed audio samples in, get fundamental frequency + confidence out.
/// Implementations must be Sendable and reentrant (the actor calls them from a detached task).
public protocol PitchDetectionAlgorithm: Sendable {
    /// Required input sample rate. The detector will resample the mic input to match.
    var sampleRate: Double { get }

    /// Required buffer size (number of mono float samples per detection call).
    var bufferSize: Int { get }

    /// Returns nil if no pitch detected with sufficient confidence.
    /// confidence: 0.0 (none) ... 1.0 (perfect).
    func detectPitch(in samples: UnsafePointer<Float>, count: Int) -> (frequency: Float, confidence: Float)?
}
