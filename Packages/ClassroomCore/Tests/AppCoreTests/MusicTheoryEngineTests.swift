import Testing
 import AppCore
import ClassroomTheory

@Suite
struct MusicTheoryEngineTests {
    let engine = MusicTheoryEngine()

    // MARK: - Spelling

    @Test func spellsCMajorTriadInCMajor() {
        let notes = engine.spell(midiNotes: [60, 64, 67], in: .cMajor)
        #expect(notes.map { $0.pitchClass } == [.c, .e, .g])
        #expect(notes.allSatisfy { $0.accidental == .natural })
        #expect(notes[0].octave == 4)
    }

    @Test func spellsCMinorTriadInCMinor() {
        let cMinor = KeySignature(tonic: .c, mode: .minor)
        let notes = engine.spell(midiNotes: [60, 63, 67], in: cMinor)
        #expect(notes[0].pitchClass == .c)
        #expect(notes[1].pitchClass == .e)
        #expect(notes[1].accidental == .flat)
        #expect(notes[2].pitchClass == .g)
    }

    @Test func spellsEmptyArrayReturnsEmpty() {
        #expect(engine.spell(midiNotes: [], in: .cMajor).isEmpty)
    }

    // MARK: - Interval delegation

    @Test func intervalCToGIsPerfectFifth() {
        let c4 = Note(pitchClass: .c, octave: 4)
        let g4 = Note(pitchClass: .g, octave: 4)
        #expect(engine.interval(from: c4, to: g4).shortName == "P5")
    }

    @Test func intervalCToEIsMajorThird() {
        let c4 = Note(pitchClass: .c, octave: 4)
        let e4 = Note(pitchClass: .e, octave: 4)
        #expect(engine.interval(from: c4, to: e4).shortName == "M3")
    }

    // MARK: - Chord identification (root position)

    @Test func identifiesCMajorRootPosition() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .e, octave: 4),
            Note(pitchClass: .g, octave: 4),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .major)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 0)
    }

    @Test func identifiesCMinorRootPosition() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .e, accidental: .flat, octave: 4),
            Note(pitchClass: .g, octave: 4),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .minor)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 0)
    }

    @Test func identifiesCDiminishedRootPosition() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .e, accidental: .flat, octave: 4),
            Note(pitchClass: .g, accidental: .flat, octave: 4),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .diminished)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 0)
    }

    @Test func identifiesCAugmentedRootPosition() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .e, octave: 4),
            Note(pitchClass: .g, accidental: .sharp, octave: 4),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .augmented)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 0)
    }

    @Test func identifiesCDominant7RootPosition() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .e, octave: 4),
            Note(pitchClass: .g, octave: 4),
            Note(pitchClass: .b, accidental: .flat, octave: 4),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .dominant7)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 0)
    }

    @Test func identifiesCMajor7RootPosition() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .e, octave: 4),
            Note(pitchClass: .g, octave: 4),
            Note(pitchClass: .b, octave: 4),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .major7)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 0)
    }

    @Test func identifiesCMinor7RootPosition() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .e, accidental: .flat, octave: 4),
            Note(pitchClass: .g, octave: 4),
            Note(pitchClass: .b, accidental: .flat, octave: 4),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .minor7)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 0)
    }

    @Test func identifiesCHalfDiminished7RootPosition() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .e, accidental: .flat, octave: 4),
            Note(pitchClass: .g, accidental: .flat, octave: 4),
            Note(pitchClass: .b, accidental: .flat, octave: 4),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .halfDiminished7)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 0)
    }

    @Test func identifiesCDiminished7RootPositionEnharmonic() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .e, accidental: .flat, octave: 4),
            Note(pitchClass: .g, accidental: .flat, octave: 4),
            Note(pitchClass: .a, octave: 4),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .diminished7)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 0)
    }

    @Test func identifiesCSus2RootPosition() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .d, octave: 4),
            Note(pitchClass: .g, octave: 4),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .sus2)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 0)
    }

    @Test func identifiesCSus4RootPosition() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .f, octave: 4),
            Note(pitchClass: .g, octave: 4),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .sus4)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 0)
    }

    // MARK: - Chord identification (inversions)

    @Test func identifiesCMajorFirstInversion() {
        let notes = [
            Note(pitchClass: .e, octave: 4),
            Note(pitchClass: .g, octave: 4),
            Note(pitchClass: .c, octave: 5),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .major)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 1)
        #expect(chord?.bassNote().pitchClass == .e)
    }

    @Test func identifiesCMajorSecondInversion() {
        let notes = [
            Note(pitchClass: .g, octave: 4),
            Note(pitchClass: .c, octave: 5),
            Note(pitchClass: .e, octave: 5),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .major)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 2)
        #expect(chord?.bassNote().pitchClass == .g)
    }

    @Test func identifiesC7ThirdInversion() {
        let notes = [
            Note(pitchClass: .b, accidental: .flat, octave: 3),
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .e, octave: 4),
            Note(pitchClass: .g, octave: 4),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .dominant7)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 3)
        #expect(chord?.bassNote().pitchClass == .b)
    }

    @Test func identifiesC7SecondInversion() {
        let notes = [
            Note(pitchClass: .g, octave: 4),
            Note(pitchClass: .b, accidental: .flat, octave: 4),
            Note(pitchClass: .c, octave: 5),
            Note(pitchClass: .e, octave: 5),
        ]
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == .dominant7)
        #expect(chord?.root == .c)
        #expect(chord?.inversion == 2)
        #expect(chord?.bassNote().pitchClass == .g)
    }

    // MARK: - Chord identification (no match)

    @Test func returnsNilForNonChordTwoNotes() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .d, octave: 4),
        ]
        #expect(engine.identifyChord(notes) == nil)
    }

    @Test func returnsNilForChromaticCluster() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .c, accidental: .sharp, octave: 4),
            Note(pitchClass: .d, octave: 4),
            Note(pitchClass: .d, accidental: .sharp, octave: 4),
        ]
        #expect(engine.identifyChord(notes) == nil)
    }

    @Test func returnsNilForEmptyInput() {
        #expect(engine.identifyChord([]) == nil)
    }

    @Test func returnsNilForSingleNote() {
        #expect(engine.identifyChord([Note(pitchClass: .c, octave: 4)]) == nil)
    }

    // MARK: - Scale identification

    @Test func identifiesCMajorScaleIncludesMajorAndIonian() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .d, octave: 4),
            Note(pitchClass: .e, octave: 4),
            Note(pitchClass: .f, octave: 4),
            Note(pitchClass: .g, octave: 4),
            Note(pitchClass: .a, octave: 4),
            Note(pitchClass: .b, octave: 4),
        ]
        let scales = engine.identifyScales(notes)
        let cMajor = scales.first { $0.name == "Major" && $0.tonic.pitchClass == .c }
        let cIonian = scales.first { $0.name == "Ionian" && $0.tonic.pitchClass == .c }
        #expect(cMajor != nil)
        #expect(cIonian != nil)
    }

    @Test func identifiesAMinorScaleIncludesNaturalMinorAndAeolian() {
        let notes = [
            Note(pitchClass: .a, octave: 3),
            Note(pitchClass: .b, octave: 3),
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .d, octave: 4),
            Note(pitchClass: .e, octave: 4),
            Note(pitchClass: .f, octave: 4),
            Note(pitchClass: .g, octave: 4),
        ]
        let scales = engine.identifyScales(notes)
        let aNatMinor = scales.first { $0.name == "Natural Minor" && $0.tonic.pitchClass == .a }
        let aAeolian = scales.first { $0.name == "Aeolian" && $0.tonic.pitchClass == .a }
        #expect(aNatMinor != nil)
        #expect(aAeolian != nil)
    }

    @Test func identifiesCMajorPentatonic() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .d, octave: 4),
            Note(pitchClass: .e, octave: 4),
            Note(pitchClass: .g, octave: 4),
            Note(pitchClass: .a, octave: 4),
        ]
        let scales = engine.identifyScales(notes)
        let cMajPent = scales.first { $0.name == "Major Pentatonic" && $0.tonic.pitchClass == .c }
        #expect(cMajPent != nil)
    }

    @Test func identifiesCBlues() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .e, accidental: .flat, octave: 4),
            Note(pitchClass: .f, octave: 4),
            Note(pitchClass: .f, accidental: .sharp, octave: 4),
            Note(pitchClass: .g, octave: 4),
            Note(pitchClass: .b, accidental: .flat, octave: 4),
        ]
        let scales = engine.identifyScales(notes)
        let cBlues = scales.first { $0.name == "Blues" && $0.tonic.pitchClass == .c }
        #expect(cBlues != nil)
    }

    @Test func identifyScalesFewerThanThreeReturnsEmpty() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .e, octave: 4),
        ]
        #expect(engine.identifyScales(notes).isEmpty)
    }

    @Test func identifyScalesSortsByTemplateLengthThenName() {
        let notes = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .d, octave: 4),
            Note(pitchClass: .e, octave: 4),
            Note(pitchClass: .g, octave: 4),
            Note(pitchClass: .a, octave: 4),
        ]
        let scales = engine.identifyScales(notes)
        guard scales.count >= 2 else { return }
        for i in 1..<scales.count {
            let prev = scales[i - 1].intervalsFromTonic.count
            let curr = scales[i].intervalsFromTonic.count
            #expect(prev <= curr)
        }
    }

    // MARK: - Roman numeral analysis

    @Test func romanIInCMajor() {
        let chord = Chord(root: .c, quality: .major)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "I")
    }

    @Test func romanIIInCMajor() {
        let chord = Chord(root: .d, quality: .minor)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "ii")
    }

    @Test func romanV7InCMajor() {
        let chord = Chord(root: .g, quality: .dominant7)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "V7")
    }

    @Test func romanViiDimInCMajor() {
        let chord = Chord(root: .b, quality: .diminished)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "vii°")
    }

    @Test func romanIV6InCMajor() {
        let chord = Chord(root: .f, quality: .major, inversion: 1)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "IV6")
    }

    @Test func romanV65InCMajor() {
        let chord = Chord(root: .g, quality: .dominant7, inversion: 1)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "V6/5")
    }

    @Test func romanV43InCMajor() {
        let chord = Chord(root: .g, quality: .dominant7, inversion: 2)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "V4/3")
    }

    @Test func romanV42InCMajor() {
        let chord = Chord(root: .g, quality: .dominant7, inversion: 3)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "V4/2")
    }

    @Test func romanFlatVIIInCMajor() {
        let chord = Chord(root: .b, rootAccidental: .flat, quality: .major)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "♭VII")
    }

    @Test func romanFlatIIInCMajor() {
        let chord = Chord(root: .d, rootAccidental: .flat, quality: .major)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "♭II")
    }

    @Test func romanIInAMinor() {
        let chord = Chord(root: .a, quality: .minor)
        let rn = engine.romanNumeral(for: chord, in: .aMinor)
        #expect(rn?.displayString == "i")
    }

    @Test func romanV7InAMinor() {
        let chord = Chord(root: .e, quality: .dominant7)
        let rn = engine.romanNumeral(for: chord, in: .aMinor)
        #expect(rn?.displayString == "V7")
    }

    @Test func romanIVInCMajor() {
        let chord = Chord(root: .f, quality: .major)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "IV")
    }

    @Test func romanVInCMajor() {
        let chord = Chord(root: .g, quality: .major)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "V")
    }

    @Test func romanVIInCMajor() {
        let chord = Chord(root: .a, quality: .minor)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "vi")
    }

    @Test func romanIIIInCMajor() {
        let chord = Chord(root: .e, quality: .minor)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "iii")
    }

    @Test func romanIMaj7InCMajor() {
        let chord = Chord(root: .c, quality: .major7)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "Imaj7")
    }

    @Test func romanIIm7InCMajor() {
        let chord = Chord(root: .d, quality: .minor7)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "ii7")
    }

    @Test func romanI64InCMajor() {
        let chord = Chord(root: .c, quality: .major, inversion: 2)
        let rn = engine.romanNumeral(for: chord, in: .cMajor)
        #expect(rn?.displayString == "I6/4")
    }

    // MARK: - Enharmonic alternatives forwarding

    @Test func enharmonicAlternativesForwardsToSpeller() {
        let cSharp = Note(pitchClass: .c, accidental: .sharp, octave: 4)
        let alts = engine.enharmonicAlternatives(for: cSharp)
        let dFlat = Note(pitchClass: .d, accidental: .flat, octave: 4)
        #expect(alts.contains(dFlat))
    }

    @Test func enharmonicAlternativesIncludeDoublesParameter() {
        let c4 = Note(pitchClass: .c, octave: 4)
        let withoutDoubles = engine.enharmonicAlternatives(for: c4)
        let withDoubles = engine.enharmonicAlternatives(for: c4, includeDoubles: true)
        #expect(withDoubles.count > withoutDoubles.count)
    }

    // MARK: - Parameterized chord ID across qualities

    @Test(arguments: [
        (Chord.Quality.major, [0, 4, 7]),
        (Chord.Quality.minor, [0, 3, 7]),
        (Chord.Quality.diminished, [0, 3, 6]),
        (Chord.Quality.augmented, [0, 4, 8]),
        (Chord.Quality.dominant7, [0, 4, 7, 10]),
        (Chord.Quality.major7, [0, 4, 7, 11]),
        (Chord.Quality.minor7, [0, 3, 7, 10]),
        (Chord.Quality.halfDiminished7, [0, 3, 6, 10]),
        (Chord.Quality.diminished7, [0, 3, 6, 9]),
        (Chord.Quality.sus2, [0, 2, 7]),
        (Chord.Quality.sus4, [0, 5, 7]),
    ])
    func identifiesAllQualitiesFromMidiOffsets(quality: Chord.Quality, intervals: [Int]) {
        let rootMidi = 60
        let notes = intervals.map { Note(midi: rootMidi + $0) }
        let chord = engine.identifyChord(notes)
        #expect(chord?.quality == quality)
        #expect(chord?.inversion == 0)
    }

    // MARK: - Misc round trips

    @Test func chordIdentifiedThenRomanNumeralRoundTrip() {
        let dm = [
            Note(pitchClass: .d, octave: 4),
            Note(pitchClass: .f, octave: 4),
            Note(pitchClass: .a, octave: 4),
        ]
        let chord = engine.identifyChord(dm)
        #expect(chord?.quality == .minor)
        let rn = engine.romanNumeral(for: chord!, in: .cMajor)
        #expect(rn?.displayString == "ii")
    }

    @Test func spellThenIdentifyRoundTrip() {
        let midis = [60, 64, 67]
        let spelled = engine.spell(midiNotes: midis, in: .cMajor)
        let chord = engine.identifyChord(spelled)
        #expect(chord?.quality == .major)
        #expect(chord?.root == .c)
    }
}
