import Foundation
import Testing
@testable import AudioInput

@Suite
struct YINDetectorTests {

    private func generateSine(frequency: Float, sampleRate: Double, count: Int) -> [Float] {
        let omega = 2.0 * Float.pi * frequency / Float(sampleRate)
        return (0..<count).map { sin(omega * Float($0)) }
    }

    private func detect(_ samples: [Float], detector: YINDetector = YINDetector()) -> (frequency: Float, confidence: Float)? {
        samples.withUnsafeBufferPointer { buf in
            detector.detectPitch(in: buf.baseAddress!, count: samples.count)
        }
    }

    @Test func detects440Hz() {
        let samples = generateSine(frequency: 440, sampleRate: 44100, count: 2048)
        let result = detect(samples)
        try? #require(result != nil)
        guard let result else { return }
        #expect(abs(result.frequency - 440) <= 1)
        #expect(result.confidence > 0.9)
    }

    @Test func detectsC4() {
        let samples = generateSine(frequency: 261.63, sampleRate: 44100, count: 2048)
        let result = detect(samples)
        guard let result else {
            Issue.record("No pitch detected for C4")
            return
        }
        #expect(abs(result.frequency - 261.63) <= 1)
    }

    @Test func detects1000Hz() {
        let samples = generateSine(frequency: 1000, sampleRate: 44100, count: 2048)
        let result = detect(samples)
        guard let result else {
            Issue.record("No pitch detected for 1000 Hz")
            return
        }
        #expect(abs(result.frequency - 1000) <= 1)
    }

    @Test func detectsA5() {
        let samples = generateSine(frequency: 880, sampleRate: 44100, count: 2048)
        let result = detect(samples)
        guard let result else {
            Issue.record("No pitch detected for A5")
            return
        }
        #expect(abs(result.frequency - 880) <= 1)
    }

    @Test func detectsLow100Hz() {
        let samples = generateSine(frequency: 100, sampleRate: 44100, count: 2048)
        let result = detect(samples)
        guard let result else {
            Issue.record("No pitch detected for 100 Hz")
            return
        }
        #expect(abs(result.frequency - 100) <= 2)
    }

    @Test func pureNoiseHasLowConfidenceOrNil() {
        var generator = SeededRNG(seed: 42)
        let samples = (0..<2048).map { _ in Float.random(in: -1...1, using: &generator) }
        let result = detect(samples)
        if let result {
            #expect(result.confidence < 0.5)
        }
    }

    @Test func silenceReturnsNil() {
        let samples = [Float](repeating: 0, count: 2048)
        let result = detect(samples)
        #expect(result == nil)
    }

    @Test func outOfRangeFrequencyReturnsNil() {
        let samples = generateSine(frequency: 10, sampleRate: 44100, count: 2048)
        let result = detect(samples)
        #expect(result == nil)
    }

    @Test func sineWithSmallNoiseStillDetected() {
        var generator = SeededRNG(seed: 7)
        let pure = generateSine(frequency: 440, sampleRate: 44100, count: 2048)
        // SNR ~20dB → noise amplitude ~0.1
        let noisy = pure.map { $0 + Float.random(in: -0.1...0.1, using: &generator) }
        let result = detect(noisy)
        guard let result else {
            Issue.record("No pitch detected for noisy 440 Hz")
            return
        }
        #expect(abs(result.frequency - 440) <= 2)
    }
}

private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 1 : seed }
    mutating func next() -> UInt64 {
        // SplitMix64
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
