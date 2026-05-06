import Testing
 import ClassroomTheory

@Suite
struct AccidentalTests {
    @Test(arguments: Accidental.allCases)
    func semitoneOffsetMatchesRawValue(accidental: Accidental) {
        #expect(accidental.semitoneOffset == accidental.rawValue)
    }

    @Test func engravingSymbolsRenderFullUnicodeIncludingNatural() {
        // The full-glyph variant used for staff engraving — includes
        // ♮ to cancel a prior accidental. MusicCore's `.symbol` returns
        // ASCII and `.displaySymbol` returns "" for natural; Classroom
        // exposes `.engravingSymbol` for the engraver case.
        #expect(Accidental.doubleFlat.engravingSymbol == "𝄫")
        #expect(Accidental.flat.engravingSymbol == "♭")
        #expect(Accidental.natural.engravingSymbol == "♮")
        #expect(Accidental.sharp.engravingSymbol == "♯")
        #expect(Accidental.doubleSharp.engravingSymbol == "𝄪")
    }

    @Test func displaySymbolHidesNatural() {
        #expect(Accidental.doubleFlat.displaySymbol == "𝄫")
        #expect(Accidental.flat.displaySymbol == "♭")
        #expect(Accidental.natural.displaySymbol == "")
        #expect(Accidental.sharp.displaySymbol == "♯")
        #expect(Accidental.doubleSharp.displaySymbol == "𝄪")
    }
}
