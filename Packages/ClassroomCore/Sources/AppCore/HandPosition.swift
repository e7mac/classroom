public struct HandPosition: Sendable, Hashable {
    public enum Source: Sendable, Hashable {
        case userSpecified
        case inferred
    }

    public let startMIDI: Int
    public let fingerCount: Int
    public let source: Source

    public init(startMIDI: Int, fingerCount: Int = 5, source: Source = .userSpecified) {
        self.startMIDI = startMIDI
        self.fingerCount = fingerCount
        self.source = source
    }
}
