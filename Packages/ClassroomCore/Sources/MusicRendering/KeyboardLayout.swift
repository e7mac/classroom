import Foundation
import CoreGraphics
import ClassroomTheory

public enum KeyboardLayout {
    /// MIDI range piano: A0 (21) ... C8 (108).
    public static let lowestPianoMIDI = 21
    public static let highestPianoMIDI = 108

    /// Returns true for MIDI notes that are black keys.
    public static func isBlackKey(_ midi: Int) -> Bool {
        let pc = ((midi % 12) + 12) % 12
        return [1, 3, 6, 8, 10].contains(pc)
    }

    /// Number of white keys in [low...high] inclusive.
    public static func whiteKeyCount(from low: Int, to high: Int) -> Int {
        guard low <= high else { return 0 }
        return (low...high).filter { !isBlackKey($0) }.count
    }

    /// 0-based index of `midi` among white keys starting from `lowMIDI`.
    /// Precondition: midi >= lowMIDI and midi is a white key.
    public static func whiteIndex(of midi: Int, lowMIDI: Int) -> Int {
        precondition(!isBlackKey(midi), "whiteIndex called on black key")
        precondition(midi >= lowMIDI, "midi must be >= lowMIDI")
        return (lowMIDI..<midi).filter { !isBlackKey($0) }.count
    }

    /// Bounds for a single key in a strip from `lowMIDI` to `highMIDI` filling `totalWidth`.
    /// White keys have uniform width; black keys are narrower (60%) and shorter (60%),
    /// centered above the seam between their two adjacent white neighbors.
    public static func keyRect(
        for midi: Int,
        lowMIDI: Int,
        highMIDI: Int,
        totalWidth: CGFloat,
        totalHeight: CGFloat
    ) -> CGRect {
        let whiteCount = whiteKeyCount(from: lowMIDI, to: highMIDI)
        let whiteWidth = totalWidth / CGFloat(whiteCount)
        let blackWidth = whiteWidth * 0.6
        let blackHeight = totalHeight * 0.6

        if isBlackKey(midi) {
            let leftWhiteMIDI = midi - 1
            let leftWhiteIndex = whiteIndex(of: leftWhiteMIDI, lowMIDI: lowMIDI)
            let x = (CGFloat(leftWhiteIndex) + 1) * whiteWidth - blackWidth / 2
            return CGRect(x: x, y: 0, width: blackWidth, height: blackHeight)
        } else {
            let i = whiteIndex(of: midi, lowMIDI: lowMIDI)
            return CGRect(x: CGFloat(i) * whiteWidth, y: 0, width: whiteWidth, height: totalHeight)
        }
    }

    /// Bracket rect for a hand position guide.
    /// `startMIDI` is the lowest finger; `fingerCount` is the white-key span.
    public static func handPositionBracket(
        startMIDI: Int,
        fingerCount: Int,
        lowMIDI: Int,
        highMIDI: Int,
        totalWidth: CGFloat,
        totalHeight: CGFloat
    ) -> CGRect? {
        guard startMIDI >= lowMIDI, startMIDI <= highMIDI, fingerCount > 0 else { return nil }
        let startWhite = isBlackKey(startMIDI) ? startMIDI + 1 : startMIDI
        let lastWhite = nthWhiteKey(after: startWhite, n: fingerCount - 1, highMIDI: highMIDI)
        let startRect = keyRect(
            for: startWhite,
            lowMIDI: lowMIDI,
            highMIDI: highMIDI,
            totalWidth: totalWidth,
            totalHeight: totalHeight
        )
        let endRect = keyRect(
            for: lastWhite,
            lowMIDI: lowMIDI,
            highMIDI: highMIDI,
            totalWidth: totalWidth,
            totalHeight: totalHeight
        )
        return CGRect(
            x: startRect.minX,
            y: 0,
            width: endRect.maxX - startRect.minX,
            height: totalHeight
        )
    }

    private static func nthWhiteKey(after midi: Int, n: Int, highMIDI: Int) -> Int {
        var current = midi
        var count = 0
        while count < n && current < highMIDI {
            current += 1
            if !isBlackKey(current) { count += 1 }
        }
        return current
    }
}
