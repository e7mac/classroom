import Testing
@testable import MusicTheory

@Suite
struct RomanNumeralTests {
    @Test func plainSymbol() {
        let numeral = RomanNumeral(symbol: "V")
        #expect(numeral.displayString == "V")
    }

    @Test func symbolWithQuality() {
        let numeral = RomanNumeral(symbol: "V", qualityModifier: "7")
        #expect(numeral.displayString == "V7")
    }

    @Test func symbolWithInversion() {
        let numeral = RomanNumeral(symbol: "I", inversionFigure: "6")
        #expect(numeral.displayString == "I6")
    }

    @Test func symbolWithQualityAndInversion() {
        let numeral = RomanNumeral(
            symbol: "vii°",
            qualityModifier: "7",
            inversionFigure: "6/5"
        )
        #expect(numeral.displayString == "vii°76/5")
    }

    @Test func minorSubtonicWithSeventh() {
        let numeral = RomanNumeral(symbol: "ii", qualityModifier: "7")
        #expect(numeral.displayString == "ii7")
    }
}
