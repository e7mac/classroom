import Testing
@testable import AppCore

@Suite
struct DisplayModeTests {
    @Test func allCasesHaveCorrectMaxConcurrentNotes() {
        #expect(DisplayMode.singleNote.maxConcurrentNotes == 1)
        #expect(DisplayMode.interval.maxConcurrentNotes == 2)
        #expect(DisplayMode.chord.maxConcurrentNotes == 4)
        #expect(DisplayMode.scale.maxConcurrentNotes == 8)
        #expect(DisplayMode.chordProgression.maxConcurrentNotes == 4)
        #expect(DisplayMode.handPosition.maxConcurrentNotes == 5)
    }

    @Test func allCasesHaveNonEmptyDisplayName() {
        for mode in DisplayMode.allCases {
            #expect(!mode.displayName.isEmpty)
        }
    }

    @Test func allCasesPresent() {
        #expect(DisplayMode.allCases.count == 6)
    }

    @Test func rawValuesAreStable() {
        #expect(DisplayMode.singleNote.rawValue == 1)
        #expect(DisplayMode.handPosition.rawValue == 6)
    }
}
