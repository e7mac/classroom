import Testing
 import ClassroomTheory

@Suite
struct ScaleTests {
    @Test func cMajorScale() {
        let scale = Scale.major(tonic: Note(pitchClass: .c, octave: 4))
        let notes = scale.notes(octaves: 1)
        #expect(notes.count == 8)
        let letters = notes.map { $0.pitchClass }
        #expect(letters == [.c, .d, .e, .f, .g, .a, .b, .c])
        for note in notes.dropLast() {
            #expect(note.accidental == .natural)
        }
    }

    @Test func aNaturalMinorScale() {
        let scale = Scale.naturalMinor(tonic: Note(pitchClass: .a, octave: 4))
        let notes = scale.notes(octaves: 1)
        let letters = notes.map { $0.pitchClass }
        #expect(letters == [.a, .b, .c, .d, .e, .f, .g, .a])
        for note in notes.dropLast() {
            #expect(note.accidental == .natural)
        }
    }

    @Test func aHarmonicMinorScale() {
        let scale = Scale.harmonicMinor(tonic: Note(pitchClass: .a, octave: 4))
        let notes = scale.notes(octaves: 1)
        let letters = notes.map { $0.pitchClass }
        #expect(letters == [.a, .b, .c, .d, .e, .f, .g, .a])
        #expect(notes[6].accidental == .sharp)
    }

    @Test func aMelodicMinorScale() {
        let scale = Scale.melodicMinor(tonic: Note(pitchClass: .a, octave: 4))
        let notes = scale.notes(octaves: 1)
        let letters = notes.map { $0.pitchClass }
        #expect(letters == [.a, .b, .c, .d, .e, .f, .g, .a])
        #expect(notes[5].accidental == .sharp)
        #expect(notes[6].accidental == .sharp)
    }

    @Test func multipleOctaves() {
        let scale = Scale.major(tonic: Note(pitchClass: .c, octave: 4))
        let twoOctaves = scale.notes(octaves: 2)
        #expect(twoOctaves.count == 15)
        #expect(twoOctaves.first?.octave == 4)
        #expect(twoOctaves.last?.pitchClass == .c)
        #expect(twoOctaves.last?.octave == 6)
    }
}
