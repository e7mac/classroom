import Testing
@testable import MusicTheory

@Suite
struct EnharmonicSpellerTests {
    let speller = EnharmonicSpeller()

    @Test func cSharpReturnsDFlatExcludingDoubles() {
        let cSharp4 = Note(pitchClass: .c, accidental: .sharp, octave: 4)
        let alts = speller.alternatives(for: cSharp4)
        let dFlat4 = Note(pitchClass: .d, accidental: .flat, octave: 4)
        #expect(alts.contains(dFlat4))
        for note in alts {
            #expect(note.accidental != .doubleSharp)
            #expect(note.accidental != .doubleFlat)
        }
    }

    @Test func cNaturalIncludingDoublesIncludesBSharpAndDDoubleFlat() {
        let c4 = Note(pitchClass: .c, octave: 4)
        let alts = speller.alternatives(for: c4, includeDoubles: true)
        let bSharp3 = Note(pitchClass: .b, accidental: .sharp, octave: 3)
        let dDoubleFlat4 = Note(pitchClass: .d, accidental: .doubleFlat, octave: 4)
        #expect(alts.contains(bSharp3))
        #expect(alts.contains(dDoubleFlat4))
    }

    @Test func fNaturalIncludingDoublesIncludesESharpAndGDoubleFlat() {
        let f4 = Note(pitchClass: .f, octave: 4)
        let alts = speller.alternatives(for: f4, includeDoubles: true)
        let eSharp4 = Note(pitchClass: .e, accidental: .sharp, octave: 4)
        let gDoubleFlat4 = Note(pitchClass: .g, accidental: .doubleFlat, octave: 4)
        #expect(alts.contains(eSharp4))
        #expect(alts.contains(gDoubleFlat4))
    }

    @Test func bNaturalIncludingDoublesIncludesCFlatAndADoubleSharp() {
        let b4 = Note(pitchClass: .b, octave: 4)
        let alts = speller.alternatives(for: b4, includeDoubles: true)
        let cFlat5 = Note(pitchClass: .c, accidental: .flat, octave: 5)
        let aDoubleSharp4 = Note(pitchClass: .a, accidental: .doubleSharp, octave: 4)
        #expect(alts.contains(cFlat5))
        #expect(alts.contains(aDoubleSharp4))
    }

    @Test func bNaturalExcludingDoublesContainsOnlyCFlat() {
        let b4 = Note(pitchClass: .b, octave: 4)
        let alts = speller.alternatives(for: b4)
        let cFlat5 = Note(pitchClass: .c, accidental: .flat, octave: 5)
        #expect(alts == [cFlat5])
    }

    @Test func everyAlternativeMatchesInputMidi() {
        let inputs: [Note] = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .d, accidental: .sharp, octave: 5),
            Note(pitchClass: .g, accidental: .flat, octave: 3),
            Note(pitchClass: .e, octave: 2),
            Note(pitchClass: .b, octave: 4),
        ]
        for input in inputs {
            let alts = speller.alternatives(for: input, includeDoubles: true)
            for alt in alts {
                #expect(alt.midiNumber == input.midiNumber, "\(alt) should match midi \(input.midiNumber)")
            }
        }
    }

    @Test func inputNoteNeverIncluded() {
        let inputs: [Note] = [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .f, accidental: .sharp, octave: 4),
            Note(pitchClass: .a, accidental: .flat, octave: 5),
            Note(pitchClass: .b, octave: 3),
        ]
        for input in inputs {
            let alts = speller.alternatives(for: input, includeDoubles: true)
            #expect(!alts.contains(input))
        }
    }
}
