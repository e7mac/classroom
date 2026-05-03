import Testing
@testable import MusicTheory

@Suite
struct ChordTests {
    @Test func cMajorTriad() {
        let chord = Chord(root: Note(pitchClass: .c, octave: 4), quality: .major)
        #expect(chord.symbol == "C")
        let notes = chord.notes
        #expect(notes.count == 3)
        #expect(notes[0].pitchClass == .c)
        #expect(notes[1].pitchClass == .e)
        #expect(notes[2].pitchClass == .g)
    }

    @Test func symbolsForAllQualitiesWithCRoot() {
        let root = Note(pitchClass: .c, octave: 4)
        let expected: [(Chord.Quality, String)] = [
            (.major, "C"),
            (.minor, "Cm"),
            (.diminished, "C°"),
            (.augmented, "C+"),
            (.dominant7, "C7"),
            (.major7, "Cmaj7"),
            (.minor7, "Cm7"),
            (.halfDiminished7, "Cø7"),
            (.diminished7, "C°7"),
            (.sus2, "Csus2"),
            (.sus4, "Csus4"),
        ]
        for (quality, symbol) in expected {
            let chord = Chord(root: root, quality: quality)
            #expect(chord.symbol == symbol, "Quality \(quality) expected \(symbol), got \(chord.symbol)")
        }
    }

    @Test func sharpRootInSymbol() {
        let chord = Chord(root: Note(pitchClass: .f, accidental: .sharp, octave: 4), quality: .minor)
        #expect(chord.symbol == "F♯m")
    }

    @Test func firstInversionSlashNotation() {
        let chord = Chord(
            root: Note(pitchClass: .c, octave: 4),
            quality: .major,
            inversion: 1
        )
        #expect(chord.symbol == "C/E")
    }

    @Test func explicitBassNoteSlashNotation() {
        let chord = Chord(
            root: Note(pitchClass: .c, octave: 4),
            quality: .major,
            bassNote: Note(pitchClass: .g, octave: 3)
        )
        #expect(chord.symbol == "C/G")
    }

    @Test func dMajor7Notes() {
        let chord = Chord(root: Note(pitchClass: .d, octave: 4), quality: .major7)
        let notes = chord.notes
        #expect(notes.map { $0.pitchClass } == [.d, .f, .a, .c])
        #expect(notes[1].accidental == .sharp)
        #expect(notes[3].accidental == .sharp)
    }

    @Test func dominantSeventhNotes() {
        let chord = Chord(root: Note(pitchClass: .g, octave: 4), quality: .dominant7)
        let notes = chord.notes
        #expect(notes.map { $0.pitchClass } == [.g, .b, .d, .f])
        #expect(notes[3].accidental == .natural)
    }

    @Test func sus2Notes() {
        let chord = Chord(root: Note(pitchClass: .c, octave: 4), quality: .sus2)
        let notes = chord.notes
        #expect(notes.map { $0.pitchClass } == [.c, .d, .g])
    }

    @Test func sus4Notes() {
        let chord = Chord(root: Note(pitchClass: .c, octave: 4), quality: .sus4)
        let notes = chord.notes
        #expect(notes.map { $0.pitchClass } == [.c, .f, .g])
    }

    @Test func diminishedSeventhNotes() {
        let chord = Chord(root: Note(pitchClass: .b, octave: 3), quality: .diminished7)
        let notes = chord.notes
        #expect(notes.map { $0.pitchClass } == [.b, .d, .f, .a])
        #expect(notes[3].accidental == .flat)
    }

    @Test func chordTemplateAllCount() {
        #expect(ChordTemplate.all.count == Chord.Quality.allCases.count)
    }
}
