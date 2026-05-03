import Foundation

public enum FrequencyToMIDI {
    /// Convert frequency (Hz) → nearest MIDI note number (rounded). A4 = 69 = 440 Hz.
    public static func midi(from frequency: Float) -> Int {
        Int(round(69 + 12 * log2(frequency / 440)))
    }

    /// Cents-off-perfect (signed). Useful for confidence-weighted gating later.
    public static func cents(from frequency: Float, midi: Int) -> Float {
        let exact = 69 + 12 * log2(Double(frequency) / 440)
        return Float(exact - Double(midi)) * 100
    }
}
