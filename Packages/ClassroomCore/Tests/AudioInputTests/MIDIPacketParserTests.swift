import Foundation
import Testing
@testable import AudioInput

@Suite
struct MIDIPacketParserTests {
    private let parser = MIDIPacketParser()
    private let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
    private let deviceID = "device-A"

    @Test func noteOnIsParsed() {
        let events = parser.parse(bytes: [0x90, 60, 100], deviceID: deviceID, timestamp: timestamp)
        #expect(events.count == 1)
        let event = events[0]
        #expect(event.kind == .noteOn)
        #expect(event.midi == 60)
        #expect(event.velocity == 100)
    }

    @Test func noteOnWithVelocityZeroIsNoteOff() {
        let events = parser.parse(bytes: [0x90, 60, 0], deviceID: deviceID, timestamp: timestamp)
        #expect(events.count == 1)
        #expect(events[0].kind == .noteOff)
        #expect(events[0].velocity == 0)
    }

    @Test func noteOffIsParsed() {
        let events = parser.parse(bytes: [0x80, 60, 50], deviceID: deviceID, timestamp: timestamp)
        #expect(events.count == 1)
        #expect(events[0].kind == .noteOff)
        #expect(events[0].midi == 60)
        #expect(events[0].velocity == 50)
    }

    @Test func channelByteDoesNotAffectOutput() {
        let events = parser.parse(bytes: [0x95, 60, 100], deviceID: deviceID, timestamp: timestamp)
        #expect(events.count == 1)
        #expect(events[0].kind == .noteOn)
        #expect(events[0].midi == 60)
    }

    @Test func sustainPedalDown() {
        let events = parser.parse(bytes: [0xB0, 64, 80], deviceID: deviceID, timestamp: timestamp)
        #expect(events.count == 1)
        #expect(events[0].kind == .sustainPedal(down: true))
    }

    @Test func sustainPedalUp() {
        let events = parser.parse(bytes: [0xB0, 64, 30], deviceID: deviceID, timestamp: timestamp)
        #expect(events.count == 1)
        #expect(events[0].kind == .sustainPedal(down: false))
    }

    @Test func sustainPedalThresholdIsDown() {
        let events = parser.parse(bytes: [0xB0, 64, 64], deviceID: deviceID, timestamp: timestamp)
        #expect(events.count == 1)
        #expect(events[0].kind == .sustainPedal(down: true))
    }

    @Test func nonSustainCCIsIgnored() {
        let events = parser.parse(bytes: [0xB0, 7, 100], deviceID: deviceID, timestamp: timestamp)
        #expect(events.isEmpty)
    }

    @Test func pitchBendIsIgnored() {
        let events = parser.parse(bytes: [0xE0, 0, 64], deviceID: deviceID, timestamp: timestamp)
        #expect(events.isEmpty)
    }

    @Test func truncatedNoteOnIsIgnored() {
        let events = parser.parse(bytes: [0x90, 60], deviceID: deviceID, timestamp: timestamp)
        #expect(events.isEmpty)
    }

    @Test func emptyBytesIsIgnored() {
        let events = parser.parse(bytes: [], deviceID: deviceID, timestamp: timestamp)
        #expect(events.isEmpty)
    }

    @Test func dataByteInStatusPositionIsIgnored() {
        let events = parser.parse(bytes: [0x40, 60, 100], deviceID: deviceID, timestamp: timestamp)
        #expect(events.isEmpty)
    }

    @Test func deviceIDIsPropagated() {
        let events = parser.parse(bytes: [0x90, 60, 100], deviceID: "studio-88", timestamp: timestamp)
        #expect(events.count == 1)
        if case .midi(let id) = events[0].source {
            #expect(id == "studio-88")
        } else {
            Issue.record("Expected midi source")
        }
    }

    @Test func timestampIsPropagated() {
        let events = parser.parse(bytes: [0x90, 60, 100], deviceID: deviceID, timestamp: timestamp)
        #expect(events.count == 1)
        #expect(events[0].timestamp == timestamp)
    }
}
