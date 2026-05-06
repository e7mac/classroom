import Foundation
import ClassroomTheory

/// Facade over MusicCore's music theory primitives that adds Classroom's
/// app-specific algorithms: chord identification from a set of sounding
/// notes, scale identification, and Roman-numeral analysis.
public struct MusicTheoryEngine: Sendable {
    public init() {}

    public func spell(midiNotes: [Int], in key: KeySignature) -> [Note] {
        midiNotes.map { key.spell(midi: $0) }
    }

    public func interval(from a: Note, to b: Note) -> Interval {
        Interval(from: a, to: b)
    }

    public func identifyChord(_ notes: [Note]) -> Chord? {
        guard !notes.isEmpty else { return nil }

        let pitchClassSet = Set(notes.map { mod12($0.midiNumber) })
        guard pitchClassSet.count >= 2 else { return nil }

        let bassNote = notes.min(by: { $0.midiNumber < $1.midiNumber })!
        let bassPC = mod12(bassNote.midiNumber)

        var matches: [(chord: Chord, isBassRoot: Bool, inversion: Int, qualityKey: String)] = []

        // Try every input note as candidate root.
        for candidate in notes {
            let rootPC = mod12(candidate.midiNumber)
            let intervalSet = Set(pitchClassSet.map { mod12($0 - rootPC) })

            for quality in Self.identifiableQualities {
                let templateSet = Set(quality.intervals.map { mod12($0) })
                guard templateSet == intervalSet else { continue }

                // Build the root-position chord first to know the chord
                // tones and figure out which one is the bass (= inversion).
                let rootPosition = Chord(root: candidate.pitchClass,
                                         rootAccidental: candidate.accidental,
                                         quality: quality)
                let chordPCs = rootPosition.notes(inOctave: 4)
                    .map { mod12($0.midiNumber) }
                let inversion = chordPCs.firstIndex(of: bassPC) ?? 0
                let chordWithInversion = Chord(root: candidate.pitchClass,
                                               rootAccidental: candidate.accidental,
                                               quality: quality,
                                               inversion: inversion,
                                               explicitBass: bassNote)
                matches.append((
                    chord: chordWithInversion,
                    isBassRoot: rootPC == bassPC,
                    inversion: inversion,
                    qualityKey: qualityKey(quality)
                ))
            }
        }

        guard !matches.isEmpty else { return nil }

        matches.sort { lhs, rhs in
            if lhs.isBassRoot != rhs.isBassRoot { return lhs.isBassRoot }
            if lhs.inversion != rhs.inversion { return lhs.inversion < rhs.inversion }
            return lhs.qualityKey < rhs.qualityKey
        }

        return matches[0].chord
    }

    public func identifyScales(_ notes: [Note]) -> [Scale] {
        let pitchClassSet = Set(notes.map { mod12($0.midiNumber) })
        guard pitchClassSet.count >= 3 else { return [] }

        var matches: [Scale] = []
        var seen = Set<String>()

        for candidate in notes {
            let tonicPC = mod12(candidate.midiNumber)
            let intervalSet = Set(pitchClassSet.map { mod12($0 - tonicPC) })

            for template in ScaleTemplate.all {
                let templateSet = Set(template.intervalsFromTonic.map { mod12($0) })
                guard templateSet == intervalSet else { continue }

                let key = "\(template.name)|\(tonicPC)|\(candidate.octave)|\(candidate.pitchClass)|\(candidate.accidental)"
                guard !seen.contains(key) else { continue }
                seen.insert(key)

                let scale = Scale(
                    name: template.name,
                    tonic: candidate,
                    intervalsFromTonic: template.intervalsFromTonic
                )
                matches.append(scale)
            }
        }

        matches.sort { lhs, rhs in
            if lhs.intervalsFromTonic.count != rhs.intervalsFromTonic.count {
                return lhs.intervalsFromTonic.count < rhs.intervalsFromTonic.count
            }
            return lhs.name < rhs.name
        }

        return matches
    }

    public func romanNumeral(for chord: Chord, in key: KeySignature) -> RomanNumeral? {
        let tonicPC = mod12(key.tonic.naturalSemitones + key.accidental.semitoneOffset)
        let rootPC = chord.rootChromaticIndex
        let offsetFromTonic = mod12(rootPC - tonicPC)

        let scalePattern: [Int] = key.mode == .major
            ? [0, 2, 4, 5, 7, 9, 11]
            : [0, 2, 3, 5, 7, 8, 10]

        var degree: Int? = nil
        var chromaticPrefix: String = ""

        if let exactDegree = scalePattern.firstIndex(of: offsetFromTonic) {
            degree = exactDegree + 1
        } else {
            // Try as flat alteration: this offset = scaleDegree - 1
            if let flatDegree = scalePattern.firstIndex(of: mod12(offsetFromTonic + 1)) {
                degree = flatDegree + 1
                chromaticPrefix = "♭"
            } else if let sharpDegree = scalePattern.firstIndex(of: mod12(offsetFromTonic - 1)) {
                degree = sharpDegree + 1
                chromaticPrefix = "♯"
            }
        }

        guard let scaleDegree = degree else { return nil }

        let isUpper: Bool = {
            switch chord.quality {
            case .major, .augmented, .dominant7, .major7, .sus2, .sus4, .major6: return true
            case .minor, .diminished, .minor7, .halfDiminished7, .diminished7,
                 .minorMajor7, .minor6:
                return false
            }
        }()

        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII"]
        var symbol = numerals[scaleDegree - 1]
        if !isUpper { symbol = symbol.lowercased() }
        symbol = chromaticPrefix + symbol

        let isSeventh: Bool = {
            switch chord.quality {
            case .dominant7, .major7, .minor7, .halfDiminished7, .diminished7,
                 .minorMajor7:
                return true
            default: return false
            }
        }()

        // For seventh chords in inversions, the figure replaces the modifier (per spec).
        // Quality marker (°/ø) stays as the modifier prefix; "7"/"maj7" is dropped on inversion.
        let isInverted = chord.inversion > 0

        var qualityModifier: String? = nil
        var inversionFigure: String? = nil

        if isSeventh {
            switch chord.inversion {
            case 0:
                switch chord.quality {
                case .dominant7: qualityModifier = "7"
                case .major7: qualityModifier = "maj7"
                case .minor7: qualityModifier = "7"
                case .halfDiminished7: qualityModifier = "ø7"
                case .diminished7: qualityModifier = "°7"
                case .minorMajor7: qualityModifier = "(M7)"
                default: break
                }
            case 1: inversionFigure = "6/5"
            case 2: inversionFigure = "4/3"
            case 3: inversionFigure = "4/2"
            default: break
            }
            // Preserve quality marker on inverted half-dim/dim sevenths.
            if isInverted {
                switch chord.quality {
                case .halfDiminished7: qualityModifier = "ø"
                case .diminished7: qualityModifier = "°"
                default: break
                }
            }
        } else {
            switch chord.quality {
            case .major: qualityModifier = nil
            case .minor: qualityModifier = nil
            case .diminished: qualityModifier = "°"
            case .augmented: qualityModifier = "+"
            case .sus2: qualityModifier = "sus2"
            case .sus4: qualityModifier = "sus4"
            case .major6, .minor6: qualityModifier = "6"
            default: break
            }
            switch chord.inversion {
            case 1: inversionFigure = "6"
            case 2: inversionFigure = "6/4"
            default: break
            }
        }

        return RomanNumeral(
            symbol: symbol,
            qualityModifier: qualityModifier,
            inversionFigure: inversionFigure
        )
    }

    public func enharmonicAlternatives(for note: Note, includeDoubles: Bool = false) -> [Note] {
        EnharmonicSpeller().alternatives(for: note, includeDoubles: includeDoubles)
    }

    // MARK: - Internal

    /// Qualities the chord-identification algorithm tries to match.
    /// Mirrors Classroom's historical ChordTemplate.all set — we don't
    /// emit MusicCore's added qualities (minorMajor7, major6, minor6)
    /// because the original Classroom algorithm wasn't tuned for them.
    private static let identifiableQualities: [Chord.Quality] = [
        .major, .minor, .diminished, .augmented,
        .dominant7, .major7, .minor7, .halfDiminished7, .diminished7,
        .sus2, .sus4,
    ]

    private func mod12(_ value: Int) -> Int {
        ((value % 12) + 12) % 12
    }

    private func qualityKey(_ quality: Chord.Quality) -> String {
        switch quality {
        case .major: return "1_major"
        case .minor: return "2_minor"
        case .dominant7: return "3_dominant7"
        case .major7: return "4_major7"
        case .minor7: return "5_minor7"
        case .diminished: return "6_diminished"
        case .augmented: return "7_augmented"
        case .halfDiminished7: return "8_halfDiminished7"
        case .diminished7: return "9_diminished7"
        case .sus2: return "A_sus2"
        case .sus4: return "B_sus4"
        case .minorMajor7: return "C_minorMajor7"
        case .major6: return "D_major6"
        case .minor6: return "E_minor6"
        }
    }
}
