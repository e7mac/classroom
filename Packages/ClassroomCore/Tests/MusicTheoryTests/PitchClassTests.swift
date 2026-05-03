import Testing
@testable import MusicTheory

@Suite
struct PitchClassTests {
    @Test(arguments: zip(
        PitchClass.allCases,
        [0, 2, 4, 5, 7, 9, 11]
    ))
    func naturalSemitonesAreCorrect(pitchClass: PitchClass, expected: Int) {
        #expect(pitchClass.naturalSemitones == expected)
    }

    @Test(arguments: zip(
        PitchClass.allCases,
        ["C", "D", "E", "F", "G", "A", "B"]
    ))
    func letterNamesAreCorrect(pitchClass: PitchClass, expected: String) {
        #expect(pitchClass.letterName == expected)
    }

    @Test func nextLetterCyclesForward() {
        #expect(PitchClass.c.nextLetter == .d)
        #expect(PitchClass.d.nextLetter == .e)
        #expect(PitchClass.e.nextLetter == .f)
        #expect(PitchClass.f.nextLetter == .g)
        #expect(PitchClass.g.nextLetter == .a)
        #expect(PitchClass.a.nextLetter == .b)
        #expect(PitchClass.b.nextLetter == .c)
    }

    @Test func previousLetterCyclesBackward() {
        #expect(PitchClass.c.previousLetter == .b)
        #expect(PitchClass.b.previousLetter == .a)
        #expect(PitchClass.a.previousLetter == .g)
        #expect(PitchClass.g.previousLetter == .f)
        #expect(PitchClass.f.previousLetter == .e)
        #expect(PitchClass.e.previousLetter == .d)
        #expect(PitchClass.d.previousLetter == .c)
    }

    @Test func allCasesCount() {
        #expect(PitchClass.allCases.count == 7)
    }
}
