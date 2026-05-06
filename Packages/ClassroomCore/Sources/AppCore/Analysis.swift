import ClassroomTheory

public struct Analysis: Sendable, Equatable {
    public var chord: Chord?
    public var interval: Interval?
    public var scale: Scale?
    public var romanNumeral: RomanNumeral?

    public init(
        chord: Chord? = nil,
        interval: Interval? = nil,
        scale: Scale? = nil,
        romanNumeral: RomanNumeral? = nil
    ) {
        self.chord = chord
        self.interval = interval
        self.scale = scale
        self.romanNumeral = romanNumeral
    }

    public static let empty = Analysis()

    public var isEmpty: Bool {
        chord == nil && interval == nil && scale == nil && romanNumeral == nil
    }
}
