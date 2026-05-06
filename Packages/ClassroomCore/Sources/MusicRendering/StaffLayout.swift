import Foundation
import CoreGraphics
import ClassroomTheory

public enum StaffLayout {
    public enum Clef: Sendable, Hashable, CaseIterable {
        case treble
        case bass
        case grand
    }

    public enum StemDirection: Sendable, Hashable {
        case up
        case down
    }

    public struct GlyphPlacement: Sendable, Hashable {
        public let symbol: String
        public let x: CGFloat
        public let y: CGFloat

        public init(symbol: String, x: CGFloat, y: CGFloat) {
            self.symbol = symbol
            self.x = x
            self.y = y
        }
    }

    public struct NoteLayout: Sendable, Hashable {
        public let note: Note
        public let y: CGFloat
        public let stem: StemDirection
        public let ledgerLineYs: [CGFloat]
        public let accidental: GlyphPlacement?

        public init(
            note: Note,
            y: CGFloat,
            stem: StemDirection,
            ledgerLineYs: [CGFloat],
            accidental: GlyphPlacement?
        ) {
            self.note = note
            self.y = y
            self.stem = stem
            self.ledgerLineYs = ledgerLineYs
            self.accidental = accidental
        }
    }

    /// Coordinate convention: y INCREASES DOWNWARD (matching SwiftUI / AppKit screen coordinates).
    /// The TOP staff line of the treble staff has the smallest y; the BOTTOM staff line has the largest y.
    public struct Geometry: Sendable, Hashable {
        public let staffSpacing: CGFloat
        public let trebleStaffTopY: CGFloat
        public let grandStaffGap: CGFloat

        public init(
            staffSpacing: CGFloat = 10,
            trebleStaffTopY: CGFloat = 20,
            grandStaffGap: CGFloat = 60
        ) {
            self.staffSpacing = staffSpacing
            self.trebleStaffTopY = trebleStaffTopY
            self.grandStaffGap = grandStaffGap
        }

        public var stepHeight: CGFloat { staffSpacing / 2 }

        public var trebleStaffBottomY: CGFloat { trebleStaffTopY + 4 * staffSpacing }

        public var bassStaffTopY: CGFloat { trebleStaffBottomY + grandStaffGap }
        public var bassStaffBottomY: CGFloat { bassStaffTopY + 4 * staffSpacing }

        public func totalHeight(for clef: Clef) -> CGFloat {
            switch clef {
            case .treble: return trebleStaffBottomY + 4 * staffSpacing
            case .bass:   return bassStaffBottomY + 4 * staffSpacing
            case .grand:  return bassStaffBottomY + 4 * staffSpacing
            }
        }
    }

    // MARK: - Diatonic step helpers

    /// Diatonic step value of a note: each letter contributes 1, each octave contributes 7.
    /// e.g. C4 = 4*7 + 0 = 28. D4 = 29. C5 = 35.
    public static func diatonicStep(for note: Note) -> Int {
        note.octave * 7 + note.pitchClass.rawValue
    }

    /// Middle C as a diatonic step (C4 = 28).
    private static let middleCStep = 4 * 7 + 0

    // MARK: - Vertical position

    public static func yPosition(for note: Note, clef: Clef, geometry: Geometry) -> CGFloat {
        let referenceStep: Int
        let referenceY: CGFloat
        switch clef {
        case .treble:
            referenceStep = diatonicStep(for: Note(pitchClass: .b, octave: 4))
            referenceY = geometry.trebleStaffTopY + 2 * geometry.staffSpacing
        case .bass:
            referenceStep = diatonicStep(for: Note(pitchClass: .d, octave: 3))
            referenceY = geometry.bassStaffTopY + 2 * geometry.staffSpacing
        case .grand:
            if diatonicStep(for: note) >= middleCStep {
                return yPosition(for: note, clef: .treble, geometry: geometry)
            } else {
                return yPosition(for: note, clef: .bass, geometry: geometry)
            }
        }
        let delta = referenceStep - diatonicStep(for: note)
        return referenceY + CGFloat(delta) * geometry.stepHeight
    }

    // MARK: - Stem direction

    public static func stemDirection(for note: Note, clef: Clef, geometry: Geometry) -> StemDirection {
        let middleY: CGFloat
        switch clef {
        case .treble:
            middleY = geometry.trebleStaffTopY + 2 * geometry.staffSpacing
        case .bass:
            middleY = geometry.bassStaffTopY + 2 * geometry.staffSpacing
        case .grand:
            return diatonicStep(for: note) >= middleCStep
                ? stemDirection(for: note, clef: .treble, geometry: geometry)
                : stemDirection(for: note, clef: .bass, geometry: geometry)
        }
        let y = yPosition(for: note, clef: clef, geometry: geometry)
        // y < middleY means notehead is HIGHER on screen (smaller y), so stem goes down.
        // A note exactly on the middle line gets stem up by convention.
        return y < middleY ? .down : .up
    }

    // MARK: - Ledger lines

    public static func ledgerLineYs(for note: Note, clef: Clef, geometry: Geometry) -> [CGFloat] {
        if clef == .grand {
            let routedClef: Clef = diatonicStep(for: note) >= middleCStep ? .treble : .bass
            return ledgerLineYs(for: note, clef: routedClef, geometry: geometry)
        }

        let topY: CGFloat
        let bottomY: CGFloat
        switch clef {
        case .treble:
            topY = geometry.trebleStaffTopY
            bottomY = geometry.trebleStaffBottomY
        case .bass:
            topY = geometry.bassStaffTopY
            bottomY = geometry.bassStaffBottomY
        case .grand:
            return []
        }

        let noteY = yPosition(for: note, clef: clef, geometry: geometry)
        var lines: [CGFloat] = []

        if noteY < topY {
            var y = topY - geometry.staffSpacing
            while y >= noteY - geometry.staffSpacing / 2 {
                lines.append(y)
                y -= geometry.staffSpacing
            }
        } else if noteY > bottomY {
            var y = bottomY + geometry.staffSpacing
            while y <= noteY + geometry.staffSpacing / 2 {
                lines.append(y)
                y += geometry.staffSpacing
            }
        }
        return lines
    }

    // MARK: - Accidental placement

    public static func accidentalPlacement(
        for note: Note,
        atY y: CGFloat,
        accidentalXOffset: CGFloat = -14
    ) -> GlyphPlacement? {
        guard note.accidental != .natural else { return nil }
        return GlyphPlacement(symbol: note.accidental.engravingSymbol, x: accidentalXOffset, y: y)
    }

    // MARK: - Full note layout

    public static func layout(
        _ note: Note,
        clef: Clef,
        geometry: Geometry,
        accidentalXOffset: CGFloat = -14
    ) -> NoteLayout {
        let y = yPosition(for: note, clef: clef, geometry: geometry)
        let stem = stemDirection(for: note, clef: clef, geometry: geometry)
        let ledgers = ledgerLineYs(for: note, clef: clef, geometry: geometry)
        let acc = accidentalPlacement(for: note, atY: y, accidentalXOffset: accidentalXOffset)
        return NoteLayout(note: note, y: y, stem: stem, ledgerLineYs: ledgers, accidental: acc)
    }

    // MARK: - Key signature glyphs

    public static func keySignatureGlyphs(
        _ key: KeySignature,
        clef: Clef,
        geometry: Geometry,
        startX: CGFloat = 0,
        glyphSpacing: CGFloat = 10
    ) -> [GlyphPlacement] {
        var x = startX
        var glyphs: [GlyphPlacement] = []
        for note in key.sharpsAndFlats {
            let displayNote = repositioned(note, forKeySignatureIn: clef)
            let y = yPosition(for: displayNote, clef: clef, geometry: geometry)
            glyphs.append(GlyphPlacement(symbol: displayNote.accidental.engravingSymbol, x: x, y: y))
            x += glyphSpacing
        }
        return glyphs
    }

    private static func repositioned(_ note: Note, forKeySignatureIn clef: Clef) -> Note {
        let octaveShift: Int
        switch clef {
        case .treble: octaveShift = 0
        case .bass:   octaveShift = -1
        case .grand:  octaveShift = 0
        }
        return Note(
            pitchClass: note.pitchClass,
            accidental: note.accidental,
            octave: note.octave + octaveShift
        )
    }
}
