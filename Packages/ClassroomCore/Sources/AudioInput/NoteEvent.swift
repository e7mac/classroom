import Foundation
import MusicTheory

public struct NoteEvent: Sendable, Hashable {
    public enum Kind: Sendable, Hashable {
        case noteOn
        case noteOff
        case sustainPedal(down: Bool)
    }

    public enum Source: Sendable, Hashable {
        case midi(deviceID: String)
        case acoustic(confidence: Float)
    }

    public let kind: Kind
    public let midi: Int
    public let velocity: UInt8
    public let timestamp: Date
    public let source: Source

    public init(
        kind: Kind,
        midi: Int,
        velocity: UInt8,
        timestamp: Date = Date(),
        source: Source
    ) {
        self.kind = kind
        self.midi = midi
        self.velocity = velocity
        self.timestamp = timestamp
        self.source = source
    }
}
