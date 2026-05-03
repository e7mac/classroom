import Foundation

public struct Scale: Hashable, Sendable {
    public let name: String
    public let tonic: Note
    public let intervalsFromTonic: [Int]

    public init(name: String, tonic: Note, intervalsFromTonic: [Int]) {
        self.name = name
        self.tonic = tonic
        self.intervalsFromTonic = intervalsFromTonic
    }

    public func notes(octaves: Int = 1) -> [Note] {
        var result: [Note] = []
        for octave in 0..<octaves {
            for (index, offset) in intervalsFromTonic.enumerated() {
                let midi = tonic.midiNumber + offset + 12 * octave
                let letter = Self.letter(from: tonic.pitchClass, steps: index)
                result.append(Self.spell(midi: midi, asLetter: letter))
            }
        }
        let topMidi = tonic.midiNumber + 12 * octaves
        let topLetter = tonic.pitchClass
        result.append(Self.spell(midi: topMidi, asLetter: topLetter))
        return result
    }

    public static func major(tonic: Note) -> Scale {
        Scale(name: "Major", tonic: tonic, intervalsFromTonic: [0, 2, 4, 5, 7, 9, 11])
    }

    public static func naturalMinor(tonic: Note) -> Scale {
        Scale(name: "Natural Minor", tonic: tonic, intervalsFromTonic: [0, 2, 3, 5, 7, 8, 10])
    }

    public static func harmonicMinor(tonic: Note) -> Scale {
        Scale(name: "Harmonic Minor", tonic: tonic, intervalsFromTonic: [0, 2, 3, 5, 7, 8, 11])
    }

    public static func melodicMinor(tonic: Note) -> Scale {
        Scale(name: "Melodic Minor", tonic: tonic, intervalsFromTonic: [0, 2, 3, 5, 7, 9, 11])
    }

    private static func letter(from pitchClass: PitchClass, steps: Int) -> PitchClass {
        let raw = (pitchClass.rawValue + steps) % 7
        return PitchClass(rawValue: raw) ?? pitchClass
    }

    private static func spell(midi: Int, asLetter letter: PitchClass) -> Note {
        let octave = (midi / 12) - 1
        let semitone = ((midi % 12) + 12) % 12
        let diff = ((semitone - letter.naturalSemitones) % 12 + 12) % 12
        let normalized = diff > 6 ? diff - 12 : diff

        let accidental = Accidental(rawValue: normalized) ?? .natural
        let writtenSemitone = letter.naturalSemitones + accidental.semitoneOffset
        var adjustedOctave = octave
        if writtenSemitone < 0 {
            adjustedOctave += 1
        } else if writtenSemitone >= 12 {
            adjustedOctave -= 1
        }
        return Note(pitchClass: letter, accidental: accidental, octave: adjustedOctave)
    }
}
