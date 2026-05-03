import Testing
@testable import MusicTheory

@Suite
struct AccidentalTests {
    @Test(arguments: Accidental.allCases)
    func semitoneOffsetMatchesRawValue(accidental: Accidental) {
        #expect(accidental.semitoneOffset == accidental.rawValue)
    }

    @Test func symbolsRenderUnicode() {
        #expect(Accidental.doubleFlat.symbol == "𝄫")
        #expect(Accidental.flat.symbol == "♭")
        #expect(Accidental.natural.symbol == "♮")
        #expect(Accidental.sharp.symbol == "♯")
        #expect(Accidental.doubleSharp.symbol == "𝄪")
    }

    @Test func displaySymbolHidesNatural() {
        #expect(Accidental.doubleFlat.displaySymbol == "𝄫")
        #expect(Accidental.flat.displaySymbol == "♭")
        #expect(Accidental.natural.displaySymbol == "")
        #expect(Accidental.sharp.displaySymbol == "♯")
        #expect(Accidental.doubleSharp.displaySymbol == "𝄪")
    }
}
