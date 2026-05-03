import Foundation

public struct Note: Hashable, Sendable {
    public let pitchClass: PitchClass
    public let accidental: Accidental
    public let octave: Int

    public init(pitchClass: PitchClass, accidental: Accidental = .natural, octave: Int) {
        self.pitchClass = pitchClass
        self.accidental = accidental
        self.octave = octave
    }

    // MIDI: C-1 = 0, so octave offset is (octave + 1) * 12.
    public var midiNumber: Int {
        12 * (octave + 1) + pitchClass.naturalSemitones + accidental.semitoneOffset
    }

    public var frequency: Double {
        440.0 * pow(2.0, Double(midiNumber - 69) / 12.0)
    }

    public var description: String {
        "\(pitchClass.letterName)\(accidental.displaySymbol)\(octave)"
    }

    public init(midi: Int) {
        let octave = (midi / 12) - 1
        let semitone = ((midi % 12) + 12) % 12
        let (pitchClass, accidental) = Self.defaultSpelling[semitone]
        self.pitchClass = pitchClass
        self.accidental = accidental
        self.octave = octave
    }

    private static let defaultSpelling: [(PitchClass, Accidental)] = [
        (.c, .natural),
        (.c, .sharp),
        (.d, .natural),
        (.d, .sharp),
        (.e, .natural),
        (.f, .natural),
        (.f, .sharp),
        (.g, .natural),
        (.g, .sharp),
        (.a, .natural),
        (.a, .sharp),
        (.b, .natural),
    ]
}
