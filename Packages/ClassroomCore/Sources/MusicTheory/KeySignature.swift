import Foundation

public struct KeySignature: Hashable, Sendable {
    public enum Mode: Sendable, Hashable { case major, minor }

    public let tonic: PitchClass
    public let accidental: Accidental
    public let mode: Mode

    public init(tonic: PitchClass, accidental: Accidental = .natural, mode: Mode) {
        self.tonic = tonic
        self.accidental = accidental
        self.mode = mode
    }

    public var fifthsCount: Int {
        let key = TonicKey(tonic: tonic, accidental: accidental)
        switch mode {
        case .major: return Self.majorFifths[key] ?? 0
        case .minor: return Self.minorFifths[key] ?? 0
        }
    }

    public var sharpsAndFlats: [Note] {
        let count = fifthsCount
        if count > 0 {
            return Array(Self.sharpOrder.prefix(count))
        }
        if count < 0 {
            return Array(Self.flatOrder.prefix(-count))
        }
        return []
    }

    // Spelling: build a 7-note diatonic map keyed by pitch-class index 0..11,
    // then fall back to the key's accidental flavor for chromatic notes.
    public func spell(midi: Int) -> Note {
        let octave = (midi / 12) - 1
        let semitone = ((midi % 12) + 12) % 12
        let diatonic = diatonicMap()

        if let note = diatonic[semitone] {
            return Self.adjustOctave(forNote: note, semitone: semitone, baseOctave: octave)
        }

        let useFlats = fifthsCount < 0
        let (pitchClass, accidental): (PitchClass, Accidental) = useFlats
            ? Self.flatChromatic[semitone]
            : Self.sharpChromatic[semitone]
        let candidate = Note(pitchClass: pitchClass, accidental: accidental, octave: octave)
        return Self.adjustOctave(forNote: candidate, semitone: semitone, baseOctave: octave)
    }

    public static let cMajor = KeySignature(tonic: .c, accidental: .natural, mode: .major)
    public static let aMinor = KeySignature(tonic: .a, accidental: .natural, mode: .minor)

    public static let all15Major: [KeySignature] = [
        KeySignature(tonic: .c, mode: .major),
        KeySignature(tonic: .g, mode: .major),
        KeySignature(tonic: .d, mode: .major),
        KeySignature(tonic: .a, mode: .major),
        KeySignature(tonic: .e, mode: .major),
        KeySignature(tonic: .b, mode: .major),
        KeySignature(tonic: .f, accidental: .sharp, mode: .major),
        KeySignature(tonic: .c, accidental: .sharp, mode: .major),
        KeySignature(tonic: .f, mode: .major),
        KeySignature(tonic: .b, accidental: .flat, mode: .major),
        KeySignature(tonic: .e, accidental: .flat, mode: .major),
        KeySignature(tonic: .a, accidental: .flat, mode: .major),
        KeySignature(tonic: .d, accidental: .flat, mode: .major),
        KeySignature(tonic: .g, accidental: .flat, mode: .major),
        KeySignature(tonic: .c, accidental: .flat, mode: .major),
    ]

    public static let all15Minor: [KeySignature] = [
        KeySignature(tonic: .a, mode: .minor),
        KeySignature(tonic: .e, mode: .minor),
        KeySignature(tonic: .b, mode: .minor),
        KeySignature(tonic: .f, accidental: .sharp, mode: .minor),
        KeySignature(tonic: .c, accidental: .sharp, mode: .minor),
        KeySignature(tonic: .g, accidental: .sharp, mode: .minor),
        KeySignature(tonic: .d, accidental: .sharp, mode: .minor),
        KeySignature(tonic: .a, accidental: .sharp, mode: .minor),
        KeySignature(tonic: .d, mode: .minor),
        KeySignature(tonic: .g, mode: .minor),
        KeySignature(tonic: .c, mode: .minor),
        KeySignature(tonic: .f, mode: .minor),
        KeySignature(tonic: .b, accidental: .flat, mode: .minor),
        KeySignature(tonic: .e, accidental: .flat, mode: .minor),
        KeySignature(tonic: .a, accidental: .flat, mode: .minor),
    ]

    private struct TonicKey: Hashable {
        let tonic: PitchClass
        let accidental: Accidental
    }

    private static let majorFifths: [TonicKey: Int] = [
        TonicKey(tonic: .c, accidental: .natural): 0,
        TonicKey(tonic: .g, accidental: .natural): 1,
        TonicKey(tonic: .d, accidental: .natural): 2,
        TonicKey(tonic: .a, accidental: .natural): 3,
        TonicKey(tonic: .e, accidental: .natural): 4,
        TonicKey(tonic: .b, accidental: .natural): 5,
        TonicKey(tonic: .f, accidental: .sharp): 6,
        TonicKey(tonic: .c, accidental: .sharp): 7,
        TonicKey(tonic: .f, accidental: .natural): -1,
        TonicKey(tonic: .b, accidental: .flat): -2,
        TonicKey(tonic: .e, accidental: .flat): -3,
        TonicKey(tonic: .a, accidental: .flat): -4,
        TonicKey(tonic: .d, accidental: .flat): -5,
        TonicKey(tonic: .g, accidental: .flat): -6,
        TonicKey(tonic: .c, accidental: .flat): -7,
    ]

    private static let minorFifths: [TonicKey: Int] = [
        TonicKey(tonic: .a, accidental: .natural): 0,
        TonicKey(tonic: .e, accidental: .natural): 1,
        TonicKey(tonic: .b, accidental: .natural): 2,
        TonicKey(tonic: .f, accidental: .sharp): 3,
        TonicKey(tonic: .c, accidental: .sharp): 4,
        TonicKey(tonic: .g, accidental: .sharp): 5,
        TonicKey(tonic: .d, accidental: .sharp): 6,
        TonicKey(tonic: .a, accidental: .sharp): 7,
        TonicKey(tonic: .d, accidental: .natural): -1,
        TonicKey(tonic: .g, accidental: .natural): -2,
        TonicKey(tonic: .c, accidental: .natural): -3,
        TonicKey(tonic: .f, accidental: .natural): -4,
        TonicKey(tonic: .b, accidental: .flat): -5,
        TonicKey(tonic: .e, accidental: .flat): -6,
        TonicKey(tonic: .a, accidental: .flat): -7,
    ]

    private static let sharpOrder: [Note] = [
        Note(pitchClass: .f, accidental: .sharp, octave: 4),
        Note(pitchClass: .c, accidental: .sharp, octave: 4),
        Note(pitchClass: .g, accidental: .sharp, octave: 4),
        Note(pitchClass: .d, accidental: .sharp, octave: 4),
        Note(pitchClass: .a, accidental: .sharp, octave: 4),
        Note(pitchClass: .e, accidental: .sharp, octave: 4),
        Note(pitchClass: .b, accidental: .sharp, octave: 4),
    ]

    private static let flatOrder: [Note] = [
        Note(pitchClass: .b, accidental: .flat, octave: 4),
        Note(pitchClass: .e, accidental: .flat, octave: 4),
        Note(pitchClass: .a, accidental: .flat, octave: 4),
        Note(pitchClass: .d, accidental: .flat, octave: 4),
        Note(pitchClass: .g, accidental: .flat, octave: 4),
        Note(pitchClass: .c, accidental: .flat, octave: 4),
        Note(pitchClass: .f, accidental: .flat, octave: 4),
    ]

    private static let sharpChromatic: [(PitchClass, Accidental)] = [
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

    private static let flatChromatic: [(PitchClass, Accidental)] = [
        (.c, .natural),
        (.d, .flat),
        (.d, .natural),
        (.e, .flat),
        (.e, .natural),
        (.f, .natural),
        (.g, .flat),
        (.g, .natural),
        (.a, .flat),
        (.a, .natural),
        (.b, .flat),
        (.b, .natural),
    ]

    private func diatonicMap() -> [Int: Note] {
        let majorPattern = [0, 2, 4, 5, 7, 9, 11]
        let minorPattern = [0, 2, 3, 5, 7, 8, 10]
        let pattern = mode == .major ? majorPattern : minorPattern

        let tonicSemitone = ((tonic.naturalSemitones + accidental.semitoneOffset) % 12 + 12) % 12

        var result: [Int: Note] = [:]
        var letter = tonic
        for (index, offset) in pattern.enumerated() {
            let semitone = (tonicSemitone + offset) % 12
            let diff = ((semitone - letter.naturalSemitones) % 12 + 12) % 12
            let normalizedDiff = diff > 6 ? diff - 12 : diff
            if let acc = Accidental(rawValue: normalizedDiff) {
                result[semitone] = Note(pitchClass: letter, accidental: acc, octave: 4)
            }
            if index < pattern.count - 1 {
                letter = letter.nextLetter
            }
        }
        return result
    }

    private static func adjustOctave(forNote note: Note, semitone: Int, baseOctave: Int) -> Note {
        // A note like Cb spelled at semitone 11 belongs to a lower octave;
        // B# spelled at semitone 0 belongs to a higher octave.
        let writtenSemitone = note.pitchClass.naturalSemitones + note.accidental.semitoneOffset
        var octave = baseOctave
        if writtenSemitone < 0 {
            octave += 1
        } else if writtenSemitone >= 12 {
            octave -= 1
        }
        return Note(pitchClass: note.pitchClass, accidental: note.accidental, octave: octave)
    }
}
