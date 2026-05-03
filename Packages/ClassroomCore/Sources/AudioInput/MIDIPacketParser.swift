import Foundation

public struct MIDIPacketParser: Sendable {
    public init() {}

    // v1 limitation: only the first message in a packet is parsed; running status across messages is unsupported.
    public func parse(bytes: [UInt8], deviceID: String, timestamp: Date) -> [NoteEvent] {
        guard let status = bytes.first, status >= 0x80 else {
            return []
        }

        let messageType = status & 0xF0
        let source: NoteEvent.Source = .midi(deviceID: deviceID)

        switch messageType {
        case 0x80:
            guard bytes.count >= 3 else { return [] }
            let note = bytes[1]
            let velocity = bytes[2]
            return [
                NoteEvent(
                    kind: .noteOff,
                    midi: Int(note),
                    velocity: velocity,
                    timestamp: timestamp,
                    source: source
                )
            ]

        case 0x90:
            guard bytes.count >= 3 else { return [] }
            let note = bytes[1]
            let velocity = bytes[2]
            let kind: NoteEvent.Kind = velocity > 0 ? .noteOn : .noteOff
            return [
                NoteEvent(
                    kind: kind,
                    midi: Int(note),
                    velocity: velocity,
                    timestamp: timestamp,
                    source: source
                )
            ]

        case 0xB0:
            guard bytes.count >= 3 else { return [] }
            let controller = bytes[1]
            let value = bytes[2]
            guard controller == 64 else { return [] }
            return [
                NoteEvent(
                    kind: .sustainPedal(down: value >= 64),
                    midi: 0,
                    velocity: value,
                    timestamp: timestamp,
                    source: source
                )
            ]

        default:
            return []
        }
    }
}
