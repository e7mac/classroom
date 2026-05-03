import Testing
import Foundation
@testable import MusicTheory

@Suite
struct NoteTests {
    @Test func a4IsMidi69AndFrequency440() {
        let a4 = Note(pitchClass: .a, octave: 4)
        #expect(a4.midiNumber == 69)
        #expect(abs(a4.frequency - 440.0) < 0.001)
    }

    @Test func middleCIsMidi60() {
        let c4 = Note(pitchClass: .c, octave: 4)
        #expect(c4.midiNumber == 60)
        #expect(abs(c4.frequency - 261.6255653005986) < 0.001)
    }

    @Test(arguments: zip(
        [
            Note(pitchClass: .c, octave: 4),
            Note(pitchClass: .c, accidental: .sharp, octave: 4),
            Note(pitchClass: .d, octave: 4),
            Note(pitchClass: .d, accidental: .sharp, octave: 4),
            Note(pitchClass: .e, octave: 4),
            Note(pitchClass: .f, octave: 4),
            Note(pitchClass: .f, accidental: .sharp, octave: 4),
            Note(pitchClass: .g, octave: 4),
            Note(pitchClass: .g, accidental: .sharp, octave: 4),
            Note(pitchClass: .a, octave: 4),
            Note(pitchClass: .a, accidental: .sharp, octave: 4),
            Note(pitchClass: .b, octave: 4),
        ],
        Array(60...71)
    ))
    func chromaticC4ToB4Midi(note: Note, expected: Int) {
        #expect(note.midiNumber == expected)
    }

    @Test func doubleSharpsAndDoubleFlats() {
        #expect(Note(pitchClass: .f, accidental: .doubleSharp, octave: 5).midiNumber == 79)
        #expect(Note(pitchClass: .b, accidental: .doubleFlat, octave: 3).midiNumber == 57)
        #expect(Note(pitchClass: .c, accidental: .doubleFlat, octave: 4).midiNumber == 58)
        #expect(Note(pitchClass: .c, accidental: .doubleSharp, octave: 4).midiNumber == 62)
    }

    @Test func negativeOctaves() {
        #expect(Note(pitchClass: .c, octave: -1).midiNumber == 0)
        #expect(Note(pitchClass: .a, octave: -1).midiNumber == 9)
    }

    @Test func descriptionRendersUnicode() {
        #expect(Note(pitchClass: .c, accidental: .sharp, octave: 4).description == "C♯4")
        #expect(Note(pitchClass: .b, accidental: .flat, octave: 3).description == "B♭3")
        #expect(Note(pitchClass: .f, accidental: .doubleSharp, octave: 5).description == "F𝄪5")
        #expect(Note(pitchClass: .e, accidental: .doubleFlat, octave: 2).description == "E𝄫2")
        #expect(Note(pitchClass: .f, octave: 4).description == "F4")
    }

    @Test(arguments: Array(0...127))
    func initFromMidiRoundTrips(midi: Int) {
        let note = Note(midi: midi)
        #expect(note.midiNumber == midi)
    }

    @Test func initFromMidiUsesSharps() {
        let note = Note(midi: 61)
        #expect(note.pitchClass == .c)
        #expect(note.accidental == .sharp)
        #expect(note.octave == 4)
    }
}
