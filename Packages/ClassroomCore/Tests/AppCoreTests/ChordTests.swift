import Testing
import AppCore
import ClassroomTheory

/// Smoke tests against MusicCore's `Chord` (re-exported from
/// ClassroomTheory). Exhaustive Chord behaviour lives in MusicCore's
/// own test suite — this file just exercises the integration with
/// Classroom's MusicTheoryEngine assumptions.
@Suite
struct ChordTests {
    @Test func cMajorTriad() {
        let chord = Chord(root: .c, quality: .major)
        #expect(chord.displayName == "C")
        let notes = chord.notes(inOctave: 4)
        #expect(notes.count == 3)
        #expect(notes[0].pitchClass == .c)
        #expect(notes[1].pitchClass == .e)
        #expect(notes[2].pitchClass == .g)
    }

    @Test func displayNamesForCommonQualities() {
        let expected: [(Chord.Quality, String)] = [
            (.major, "C"),
            (.minor, "Cm"),
            (.diminished, "Cdim"),
            (.augmented, "Caug"),
            (.dominant7, "C7"),
            (.major7, "Cmaj7"),
            (.minor7, "Cm7"),
            (.halfDiminished7, "Cø7"),
            (.diminished7, "C°7"),
            (.sus2, "Csus2"),
            (.sus4, "Csus4"),
        ]
        for (quality, name) in expected {
            let chord = Chord(root: .c, quality: quality)
            #expect(chord.displayName == name,
                    "Quality \(quality) expected \(name), got \(chord.displayName)")
        }
    }

    @Test func sharpRootInDisplayName() {
        let chord = Chord(root: .f, rootAccidental: .sharp, quality: .minor)
        #expect(chord.displayName == "F♯m")
    }

    @Test func firstInversionSlashNotation() {
        let chord = Chord(root: .c, quality: .major, inversion: 1)
        #expect(chord.displayName == "C/E")
    }

    @Test func explicitBassNoteSlashNotation() {
        let chord = Chord(root: .c, quality: .major,
                          explicitBass: Note(pitchClass: .g, octave: 3))
        #expect(chord.displayName == "C/G")
    }

    @Test func dMajor7Notes() {
        let chord = Chord(root: .d, quality: .major7)
        let notes = chord.notes(inOctave: 4)
        #expect(notes.map { $0.pitchClass } == [.d, .f, .a, .c])
        #expect(notes[1].accidental == .sharp)
        #expect(notes[3].accidental == .sharp)
    }

    @Test func dominantSeventhNotes() {
        let chord = Chord(root: .g, quality: .dominant7)
        let notes = chord.notes(inOctave: 4)
        #expect(notes.map { $0.pitchClass } == [.g, .b, .d, .f])
        #expect(notes[3].accidental == .natural)
    }

    @Test func sus2Notes() {
        let chord = Chord(root: .c, quality: .sus2)
        let notes = chord.notes(inOctave: 4)
        #expect(notes.map { $0.pitchClass } == [.c, .d, .g])
    }

    @Test func sus4Notes() {
        let chord = Chord(root: .c, quality: .sus4)
        let notes = chord.notes(inOctave: 4)
        #expect(notes.map { $0.pitchClass } == [.c, .f, .g])
    }

    @Test func diminishedSeventhNotes() {
        let chord = Chord(root: .b, quality: .diminished7)
        let notes = chord.notes(inOctave: 3)
        #expect(notes.map { $0.pitchClass } == [.b, .d, .f, .a])
        #expect(notes[3].accidental == .flat)
    }
}
