import Testing
@testable import MusicTheory

@Suite
struct IntervalTests {
    @Test func unisonAndOctave() {
        let c4 = Note(pitchClass: .c, octave: 4)
        let c5 = Note(pitchClass: .c, octave: 5)
        let unison = Interval(from: c4, to: c4)
        #expect(unison.number == 1)
        #expect(unison.quality == .perfect)
        #expect(unison.semitones == 0)
        #expect(unison.shortName == "P1")

        let octave = Interval(from: c4, to: c5)
        #expect(octave.number == 8)
        #expect(octave.quality == .perfect)
        #expect(octave.semitones == 12)
        #expect(octave.shortName == "P8")
    }

    @Test func diatonicIntervalsFromC4() {
        let c4 = Note(pitchClass: .c, octave: 4)
        let cases: [(Note, Int, Interval.Quality, Int, String)] = [
            (Note(pitchClass: .d, accidental: .flat, octave: 4), 2, .minor, 1, "m2"),
            (Note(pitchClass: .d, octave: 4), 2, .major, 2, "M2"),
            (Note(pitchClass: .e, accidental: .flat, octave: 4), 3, .minor, 3, "m3"),
            (Note(pitchClass: .e, octave: 4), 3, .major, 4, "M3"),
            (Note(pitchClass: .f, octave: 4), 4, .perfect, 5, "P4"),
            (Note(pitchClass: .f, accidental: .sharp, octave: 4), 4, .augmented, 6, "A4"),
            (Note(pitchClass: .g, accidental: .flat, octave: 4), 5, .diminished, 6, "d5"),
            (Note(pitchClass: .g, octave: 4), 5, .perfect, 7, "P5"),
            (Note(pitchClass: .a, accidental: .flat, octave: 4), 6, .minor, 8, "m6"),
            (Note(pitchClass: .a, octave: 4), 6, .major, 9, "M6"),
            (Note(pitchClass: .b, accidental: .flat, octave: 4), 7, .minor, 10, "m7"),
            (Note(pitchClass: .b, octave: 4), 7, .major, 11, "M7"),
        ]
        for (high, expectedNumber, expectedQuality, expectedSemitones, expectedShort) in cases {
            let interval = Interval(from: c4, to: high)
            #expect(interval.number == expectedNumber, "Number for \(high.description)")
            #expect(interval.quality == expectedQuality, "Quality for \(high.description)")
            #expect(interval.semitones == expectedSemitones, "Semitones for \(high.description)")
            #expect(interval.shortName == expectedShort, "shortName for \(high.description)")
        }
    }

    @Test func enharmonicDistinctIntervals() {
        let c4 = Note(pitchClass: .c, octave: 4)
        let dSharp4 = Note(pitchClass: .d, accidental: .sharp, octave: 4)
        let eFlat4 = Note(pitchClass: .e, accidental: .flat, octave: 4)

        let augmented2 = Interval(from: c4, to: dSharp4)
        #expect(augmented2.number == 2)
        #expect(augmented2.quality == .augmented)
        #expect(augmented2.semitones == 3)
        #expect(augmented2.shortName == "A2")

        let minor3 = Interval(from: c4, to: eFlat4)
        #expect(minor3.number == 3)
        #expect(minor3.quality == .minor)
        #expect(minor3.semitones == 3)
        #expect(minor3.shortName == "m3")
    }

    @Test func compoundIntervals() {
        let c4 = Note(pitchClass: .c, octave: 4)
        let e5 = Note(pitchClass: .e, octave: 5)
        let interval = Interval(from: c4, to: e5)
        #expect(interval.number == 10)
        #expect(interval.quality == .major)
        #expect(interval.semitones == 16)
        #expect(interval.shortName == "M10")
    }

    @Test func compoundMinorNinth() {
        let c4 = Note(pitchClass: .c, octave: 4)
        let dFlat5 = Note(pitchClass: .d, accidental: .flat, octave: 5)
        let interval = Interval(from: c4, to: dFlat5)
        #expect(interval.number == 9)
        #expect(interval.quality == .minor)
        #expect(interval.shortName == "m9")
    }

    @Test func descendingInputSwapsToAscending() {
        let c4 = Note(pitchClass: .c, octave: 4)
        let g4 = Note(pitchClass: .g, octave: 4)
        let descending = Interval(from: g4, to: c4)
        let ascending = Interval(from: c4, to: g4)
        #expect(descending.number == ascending.number)
        #expect(descending.quality == ascending.quality)
        #expect(descending.semitones == ascending.semitones)
    }

    @Test func doublyAugmentedAndDiminished() {
        let c4 = Note(pitchClass: .c, octave: 4)
        let fDoubleSharp4 = Note(pitchClass: .f, accidental: .doubleSharp, octave: 4)
        let interval = Interval(from: c4, to: fDoubleSharp4)
        #expect(interval.number == 4)
        #expect(interval.quality == .doubleAugmented)
        #expect(interval.shortName == "AA4")

        let gDoubleFlat4 = Note(pitchClass: .g, accidental: .doubleFlat, octave: 4)
        let dd5 = Interval(from: c4, to: gDoubleFlat4)
        #expect(dd5.number == 5)
        #expect(dd5.quality == .doubleDiminished)
        #expect(dd5.shortName == "dd5")
    }
}
