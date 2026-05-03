import Testing
@testable import MusicRendering

@Test func clefHasAllExpectedCases() {
    #expect(StaffLayout.Clef.allCases.count == 3)
    #expect(StaffLayout.Clef.allCases.contains(.treble))
    #expect(StaffLayout.Clef.allCases.contains(.bass))
    #expect(StaffLayout.Clef.allCases.contains(.grand))
}
