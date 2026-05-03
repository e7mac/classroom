import Testing
@testable import MusicRendering

@Suite struct ClefSetTests {
    @Test func trebleOnlyShowsOnlyTreble() {
        #expect(ClefSet.trebleOnly.showsTreble)
        #expect(!ClefSet.trebleOnly.showsBass)
    }

    @Test func bassOnlyShowsOnlyBass() {
        #expect(!ClefSet.bassOnly.showsTreble)
        #expect(ClefSet.bassOnly.showsBass)
    }

    @Test func grandShowsBoth() {
        #expect(ClefSet.grand.showsTreble)
        #expect(ClefSet.grand.showsBass)
    }

    @Test func initFromTrebleClef() {
        let set = ClefSet(clef: .treble)
        #expect(set == .trebleOnly)
    }

    @Test func initFromBassClef() {
        let set = ClefSet(clef: .bass)
        #expect(set == .bassOnly)
    }

    @Test func initFromGrandClef() {
        let set = ClefSet(clef: .grand)
        #expect(set == .grand)
    }
}
