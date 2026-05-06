import Testing
 import ClassroomTheory

@Suite
struct KeySignatureTests {
    @Test func allMajorKeysFifthsCount() {
        let expected: [(KeySignature, Int)] = [
            (KeySignature(tonic: .c, mode: .major), 0),
            (KeySignature(tonic: .g, mode: .major), 1),
            (KeySignature(tonic: .d, mode: .major), 2),
            (KeySignature(tonic: .a, mode: .major), 3),
            (KeySignature(tonic: .e, mode: .major), 4),
            (KeySignature(tonic: .b, mode: .major), 5),
            (KeySignature(tonic: .f, accidental: .sharp, mode: .major), 6),
            (KeySignature(tonic: .c, accidental: .sharp, mode: .major), 7),
            (KeySignature(tonic: .f, mode: .major), -1),
            (KeySignature(tonic: .b, accidental: .flat, mode: .major), -2),
            (KeySignature(tonic: .e, accidental: .flat, mode: .major), -3),
            (KeySignature(tonic: .a, accidental: .flat, mode: .major), -4),
            (KeySignature(tonic: .d, accidental: .flat, mode: .major), -5),
            (KeySignature(tonic: .g, accidental: .flat, mode: .major), -6),
            (KeySignature(tonic: .c, accidental: .flat, mode: .major), -7),
        ]
        for (key, fifths) in expected {
            #expect(key.fifthsCount == fifths, "Expected \(fifths) for \(key.tonic.letterName)")
        }
    }

    @Test func allMinorKeysFifthsCount() {
        let expected: [(KeySignature, Int)] = [
            (KeySignature(tonic: .a, mode: .minor), 0),
            (KeySignature(tonic: .e, mode: .minor), 1),
            (KeySignature(tonic: .b, mode: .minor), 2),
            (KeySignature(tonic: .f, accidental: .sharp, mode: .minor), 3),
            (KeySignature(tonic: .c, accidental: .sharp, mode: .minor), 4),
            (KeySignature(tonic: .g, accidental: .sharp, mode: .minor), 5),
            (KeySignature(tonic: .d, accidental: .sharp, mode: .minor), 6),
            (KeySignature(tonic: .a, accidental: .sharp, mode: .minor), 7),
            (KeySignature(tonic: .d, mode: .minor), -1),
            (KeySignature(tonic: .g, mode: .minor), -2),
            (KeySignature(tonic: .c, mode: .minor), -3),
            (KeySignature(tonic: .f, mode: .minor), -4),
            (KeySignature(tonic: .b, accidental: .flat, mode: .minor), -5),
            (KeySignature(tonic: .e, accidental: .flat, mode: .minor), -6),
            (KeySignature(tonic: .a, accidental: .flat, mode: .minor), -7),
        ]
        for (key, fifths) in expected {
            #expect(key.fifthsCount == fifths, "Expected \(fifths) for \(key.tonic.letterName) minor")
        }
    }

    @Test func cMajorSpellingsUseSharps() {
        let key = KeySignature.cMajor
        let c4 = key.spell(midi: 60)
        #expect(c4.pitchClass == .c)
        #expect(c4.accidental == .natural)
        #expect(c4.octave == 4)

        let cSharp4 = key.spell(midi: 61)
        #expect(cSharp4.pitchClass == .c)
        #expect(cSharp4.accidental == .sharp)
    }

    @Test func bFlatMajorSpellsBFlatNotASharp() {
        let key = KeySignature(tonic: .b, accidental: .flat, mode: .major)
        let note = key.spell(midi: 70)
        #expect(note.pitchClass == .b)
        #expect(note.accidental == .flat)
        #expect(note.octave == 4)
    }

    @Test func bFlatMajorChromaticUsesFlats() {
        let key = KeySignature(tonic: .b, accidental: .flat, mode: .major)
        let note = key.spell(midi: 73)
        #expect(note.pitchClass == .d)
        #expect(note.accidental == .flat)
        #expect(note.octave == 5)
    }

    @Test func fSharpMajorSpellsFSharp() {
        let key = KeySignature(tonic: .f, accidental: .sharp, mode: .major)
        let note = key.spell(midi: 66)
        #expect(note.pitchClass == .f)
        #expect(note.accidental == .sharp)
        #expect(note.octave == 4)
    }

    @Test func dFlatMajorSpellsDFlat() {
        let key = KeySignature(tonic: .d, accidental: .flat, mode: .major)
        let note = key.spell(midi: 61)
        #expect(note.pitchClass == .d)
        #expect(note.accidental == .flat)
        #expect(note.octave == 4)
    }

    @Test func diatonicRoundTripForAllMajorKeys() {
        for key in KeySignature.all15Major {
            for offset in [0, 2, 4, 5, 7, 9, 11] {
                let baseTonicMidi = 60 + key.tonic.naturalSemitones + key.accidental.semitoneOffset
                let midi = baseTonicMidi + offset
                let spelled = key.spell(midi: midi)
                #expect(spelled.midiNumber == midi, "Round-trip failed for key \(key.tonic.letterName)\(key.accidental.displaySymbol) midi \(midi)")
            }
        }
    }

    @Test func sharpsAndFlatsCount() {
        #expect(KeySignature.cMajor.sharpsAndFlats.count == 0)
        #expect(KeySignature(tonic: .g, mode: .major).sharpsAndFlats.count == 1)
        #expect(KeySignature(tonic: .d, mode: .major).sharpsAndFlats.count == 2)
        #expect(KeySignature(tonic: .b, accidental: .flat, mode: .major).sharpsAndFlats.count == 2)
        #expect(KeySignature(tonic: .c, accidental: .flat, mode: .major).sharpsAndFlats.count == 7)
        #expect(KeySignature(tonic: .c, accidental: .sharp, mode: .major).sharpsAndFlats.count == 7)
    }

    @Test func sharpsAndFlatsFollowStandardOrder() {
        let gMajor = KeySignature(tonic: .g, mode: .major).sharpsAndFlats
        #expect(gMajor.first?.pitchClass == .f)
        #expect(gMajor.first?.accidental == .sharp)

        let bFlat = KeySignature(tonic: .b, accidental: .flat, mode: .major).sharpsAndFlats
        #expect(bFlat[0].pitchClass == .b)
        #expect(bFlat[0].accidental == .flat)
        #expect(bFlat[1].pitchClass == .e)
        #expect(bFlat[1].accidental == .flat)
    }

    @Test func canonicalShortcuts() {
        #expect(KeySignature.cMajor.tonic == .c)
        #expect(KeySignature.cMajor.mode == .major)
        #expect(KeySignature.aMinor.tonic == .a)
        #expect(KeySignature.aMinor.mode == .minor)
    }
}
