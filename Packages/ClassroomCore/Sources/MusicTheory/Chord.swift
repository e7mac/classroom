import Foundation

public struct Chord: Hashable, Sendable {
    public enum Quality: Sendable, Hashable, CaseIterable {
        case major, minor, diminished, augmented
        case dominant7, major7, minor7, halfDiminished7, diminished7
        case sus2, sus4
    }

    public let root: Note
    public let quality: Quality
    public let inversion: Int
    public let bassNote: Note

    public init(root: Note, quality: Quality, inversion: Int = 0, bassNote: Note? = nil) {
        self.root = root
        self.quality = quality
        self.inversion = inversion
        if let bassNote {
            self.bassNote = bassNote
        } else {
            let template = Self.template(for: quality)
            let stacked = Self.stackThirds(root: root, intervals: template.intervalsFromRoot)
            let safeInversion = max(0, min(inversion, stacked.count - 1))
            self.bassNote = stacked[safeInversion]
        }
    }

    public var symbol: String {
        let rootSymbol = "\(root.pitchClass.letterName)\(root.accidental.displaySymbol)"
        let qualitySymbol: String
        switch quality {
        case .major: qualitySymbol = ""
        case .minor: qualitySymbol = "m"
        case .diminished: qualitySymbol = "°"
        case .augmented: qualitySymbol = "+"
        case .dominant7: qualitySymbol = "7"
        case .major7: qualitySymbol = "maj7"
        case .minor7: qualitySymbol = "m7"
        case .halfDiminished7: qualitySymbol = "ø7"
        case .diminished7: qualitySymbol = "°7"
        case .sus2: qualitySymbol = "sus2"
        case .sus4: qualitySymbol = "sus4"
        }

        var result = "\(rootSymbol)\(qualitySymbol)"
        let bassDiffersFromRoot = bassNote.pitchClass != root.pitchClass
            || bassNote.accidental != root.accidental
        if bassDiffersFromRoot {
            let bassSymbol = "\(bassNote.pitchClass.letterName)\(bassNote.accidental.displaySymbol)"
            result += "/\(bassSymbol)"
        }
        return result
    }

    public var notes: [Note] {
        let template = Self.template(for: quality)
        return Self.stackThirds(root: root, intervals: template.intervalsFromRoot)
    }

    private static func template(for quality: Quality) -> ChordTemplate {
        ChordTemplate.all.first { $0.quality == quality } ?? ChordTemplate.all[0]
    }

    // Stack notes by letter steps matching the chord interval positions.
    // Triads use letters [root, +2 letters, +4 letters]; sevenths add +6 letters.
    // Sus2/sus4 substitute the third with a 2nd/4th.
    private static func stackThirds(root: Note, intervals: [Int]) -> [Note] {
        let letterSteps = letterStepsForIntervals(intervals)
        var notes: [Note] = []
        for (index, semitoneOffset) in intervals.enumerated() {
            let targetMidi = root.midiNumber + semitoneOffset
            let targetLetter = letter(from: root.pitchClass, steps: letterSteps[index])
            let note = spell(midi: targetMidi, asLetter: targetLetter)
            notes.append(note)
        }
        return notes
    }

    private static func letterStepsForIntervals(_ intervals: [Int]) -> [Int] {
        var steps: [Int] = []
        for semitone in intervals {
            switch semitone {
            case 0: steps.append(0)
            case 2: steps.append(1)
            case 3, 4: steps.append(2)
            case 5: steps.append(3)
            case 6, 7, 8: steps.append(4)
            case 9, 10, 11: steps.append(6)
            default: steps.append(semitone / 2)
            }
        }
        return steps
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
