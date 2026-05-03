import Testing
import CoreGraphics
@testable import MusicRendering

@Suite struct KeyboardLayoutBlackKeyTests {
    @Test func cIsWhite() { #expect(!KeyboardLayout.isBlackKey(60)) }
    @Test func cSharpIsBlack() { #expect(KeyboardLayout.isBlackKey(61)) }
    @Test func dIsWhite() { #expect(!KeyboardLayout.isBlackKey(62)) }
    @Test func dSharpIsBlack() { #expect(KeyboardLayout.isBlackKey(63)) }
    @Test func eIsWhite() { #expect(!KeyboardLayout.isBlackKey(64)) }
    @Test func fIsWhite() { #expect(!KeyboardLayout.isBlackKey(65)) }
    @Test func fSharpIsBlack() { #expect(KeyboardLayout.isBlackKey(66)) }
    @Test func gIsWhite() { #expect(!KeyboardLayout.isBlackKey(67)) }
    @Test func gSharpIsBlack() { #expect(KeyboardLayout.isBlackKey(68)) }
    @Test func aIsWhite() { #expect(!KeyboardLayout.isBlackKey(69)) }
    @Test func aSharpIsBlack() { #expect(KeyboardLayout.isBlackKey(70)) }
    @Test func bIsWhite() { #expect(!KeyboardLayout.isBlackKey(71)) }
}

@Suite struct KeyboardLayoutWhiteKeyCountTests {
    @Test func fullPianoHas52WhiteKeys() {
        #expect(KeyboardLayout.whiteKeyCount(from: 21, to: 108) == 52)
    }

    @Test func singleOctaveHas7WhiteKeys() {
        #expect(KeyboardLayout.whiteKeyCount(from: 60, to: 71) == 7)
    }

    @Test func emptyRangeReturnsZero() {
        #expect(KeyboardLayout.whiteKeyCount(from: 60, to: 59) == 0)
    }
}

@Suite struct KeyboardLayoutWhiteIndexTests {
    @Test func a0HasIndexZero() {
        #expect(KeyboardLayout.whiteIndex(of: 21, lowMIDI: 21) == 0)
    }

    @Test func c4HasIndex23OnFullPiano() {
        // C4 (MIDI 60) is the 24th white key (index 23) starting from A0 (MIDI 21).
        #expect(KeyboardLayout.whiteIndex(of: 60, lowMIDI: 21) == 23)
    }

    @Test func c5IsSevenStepsAboveC4() {
        let c4 = KeyboardLayout.whiteIndex(of: 60, lowMIDI: 21)
        let c5 = KeyboardLayout.whiteIndex(of: 72, lowMIDI: 21)
        #expect(c5 - c4 == 7)
    }
}

@Suite struct KeyboardLayoutKeyRectTests {
    @Test func c4WhiteKeyHasExpectedRect() {
        let rect = KeyboardLayout.keyRect(
            for: 60,
            lowMIDI: 21,
            highMIDI: 108,
            totalWidth: 520,
            totalHeight: 100
        )
        #expect(rect.origin.x == 230)
        #expect(rect.origin.y == 0)
        #expect(rect.size.width == 10)
        #expect(rect.size.height == 100)
    }

    @Test func cSharp4BlackKeyIsNarrowerAndShorter() {
        let rect = KeyboardLayout.keyRect(
            for: 61,
            lowMIDI: 21,
            highMIDI: 108,
            totalWidth: 520,
            totalHeight: 100
        )
        #expect(rect.size.width == 6)
        #expect(rect.size.height == 60)
    }

    @Test func cSharp4BlackKeyIsCenteredOnSeam() {
        // Seam between C4 (white index 23) and D4 (white index 24) is at x = 240.
        // Black key width = 6, so left edge = 240 - 3 = 237.
        let rect = KeyboardLayout.keyRect(
            for: 61,
            lowMIDI: 21,
            highMIDI: 108,
            totalWidth: 520,
            totalHeight: 100
        )
        #expect(rect.origin.x == 237)
        #expect(rect.midX == 240)
    }

    @Test func a0LeftmostWhiteKeyStartsAtZero() {
        let rect = KeyboardLayout.keyRect(
            for: 21,
            lowMIDI: 21,
            highMIDI: 108,
            totalWidth: 520,
            totalHeight: 100
        )
        #expect(rect.origin.x == 0)
    }
}

@Suite struct KeyboardLayoutHandPositionBracketTests {
    @Test func fiveFingerCMajorHandPosition() {
        // C4 to G4 is a 5-finger position spanning 5 white keys.
        let rect = KeyboardLayout.handPositionBracket(
            startMIDI: 60,
            fingerCount: 5,
            lowMIDI: 21,
            highMIDI: 108,
            totalWidth: 520,
            totalHeight: 100
        )
        #expect(rect != nil)
        #expect(rect?.origin.x == 230)
        // C4 white index 23, G4 white index 27 → endRect.maxX = 28*10 = 280.
        #expect(rect?.maxX == 280)
        #expect(rect?.size.width == 50)
        #expect(rect?.size.height == 100)
    }

    @Test func zeroFingerCountReturnsNil() {
        let rect = KeyboardLayout.handPositionBracket(
            startMIDI: 60,
            fingerCount: 0,
            lowMIDI: 21,
            highMIDI: 108,
            totalWidth: 520,
            totalHeight: 100
        )
        #expect(rect == nil)
    }

    @Test func startBelowRangeReturnsNil() {
        let rect = KeyboardLayout.handPositionBracket(
            startMIDI: 20,
            fingerCount: 5,
            lowMIDI: 21,
            highMIDI: 108,
            totalWidth: 520,
            totalHeight: 100
        )
        #expect(rect == nil)
    }

    @Test func startOnBlackKeyAdvancesToNextWhite() {
        // Starting on C#4 (61) should anchor to D4 (62).
        let rect = KeyboardLayout.handPositionBracket(
            startMIDI: 61,
            fingerCount: 5,
            lowMIDI: 21,
            highMIDI: 108,
            totalWidth: 520,
            totalHeight: 100
        )
        let d4Rect = KeyboardLayout.keyRect(
            for: 62,
            lowMIDI: 21,
            highMIDI: 108,
            totalWidth: 520,
            totalHeight: 100
        )
        #expect(rect?.origin.x == d4Rect.origin.x)
    }
}
