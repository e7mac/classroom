import Foundation
import Testing
@testable import AudioInput

@Suite
struct NoteEventTests {
    @Test func noteEventRoundTripsEquatable() {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let lhs = NoteEvent(
            kind: .noteOn,
            midi: 60,
            velocity: 100,
            timestamp: timestamp,
            source: .midi(deviceID: "X")
        )
        let rhs = NoteEvent(
            kind: .noteOn,
            midi: 60,
            velocity: 100,
            timestamp: timestamp,
            source: .midi(deviceID: "X")
        )
        #expect(lhs == rhs)
        #expect(lhs.hashValue == rhs.hashValue)
    }

    @Test func differentKindsAreNotEqual() {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let on = NoteEvent(
            kind: .noteOn,
            midi: 60,
            velocity: 100,
            timestamp: timestamp,
            source: .midi(deviceID: "X")
        )
        let off = NoteEvent(
            kind: .noteOff,
            midi: 60,
            velocity: 100,
            timestamp: timestamp,
            source: .midi(deviceID: "X")
        )
        #expect(on != off)
    }

    @Test func sustainPedalKindCarriesDownState() {
        let pedalDown = NoteEvent(
            kind: .sustainPedal(down: true),
            midi: 0,
            velocity: 0,
            source: .midi(deviceID: "X")
        )
        if case .sustainPedal(let down) = pedalDown.kind {
            #expect(down == true)
        } else {
            Issue.record("Expected sustainPedal kind")
        }
    }

    @Test func acousticSourceCarriesConfidence() {
        let event = NoteEvent(
            kind: .noteOn,
            midi: 69,
            velocity: 80,
            source: .acoustic(confidence: 0.92)
        )
        if case .acoustic(let confidence) = event.source {
            #expect(confidence == 0.92)
        } else {
            Issue.record("Expected acoustic source")
        }
    }
}
