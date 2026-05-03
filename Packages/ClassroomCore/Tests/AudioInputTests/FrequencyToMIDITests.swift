import Foundation
import Testing
@testable import AudioInput

@Suite
struct FrequencyToMIDITests {

    @Test func a4Maps69() {
        #expect(FrequencyToMIDI.midi(from: 440) == 69)
    }

    @Test func c4Maps60() {
        #expect(FrequencyToMIDI.midi(from: 261.63) == 60)
    }

    @Test func a5Maps81() {
        #expect(FrequencyToMIDI.midi(from: 880) == 81)
    }

    @Test func a0Maps21() {
        #expect(FrequencyToMIDI.midi(from: 27.5) == 21)
    }

    @Test func c8Maps108() {
        #expect(FrequencyToMIDI.midi(from: 4186.01) == 108)
    }

    @Test func centsAt442Hz() {
        let cents = FrequencyToMIDI.cents(from: 442, midi: 69)
        // 442 Hz is ~7.85 cents above A4 (440 Hz).
        #expect(abs(cents - 7.85) < 0.5)
    }
}
