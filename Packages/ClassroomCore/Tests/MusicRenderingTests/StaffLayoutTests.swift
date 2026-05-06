import Testing
import CoreGraphics
import ClassroomTheory
@testable import MusicRendering

@Suite struct StaffLayoutClefTests {
    @Test func clefHasAllExpectedCases() {
        #expect(StaffLayout.Clef.allCases.count == 3)
        #expect(StaffLayout.Clef.allCases.contains(.treble))
        #expect(StaffLayout.Clef.allCases.contains(.bass))
        #expect(StaffLayout.Clef.allCases.contains(.grand))
    }
}

@Suite struct StaffLayoutGeometryTests {
    @Test func stepHeightIsHalfStaffSpacing() {
        let g = StaffLayout.Geometry(staffSpacing: 10)
        #expect(g.stepHeight == 5)
    }

    @Test func customSpacingPropagates() {
        let g = StaffLayout.Geometry(staffSpacing: 16)
        #expect(g.stepHeight == 8)
        #expect(g.trebleStaffBottomY == g.trebleStaffTopY + 64)
    }

    @Test func bassStaffPositioningRelativeToTreble() {
        let g = StaffLayout.Geometry(staffSpacing: 10, trebleStaffTopY: 20, grandStaffGap: 60)
        #expect(g.trebleStaffBottomY == 60)
        #expect(g.bassStaffTopY == 120)
        #expect(g.bassStaffBottomY == 160)
    }

    @Test func totalHeightVariesByClef() {
        let g = StaffLayout.Geometry(staffSpacing: 10, trebleStaffTopY: 20, grandStaffGap: 60)
        #expect(g.totalHeight(for: .treble) == 100)
        #expect(g.totalHeight(for: .bass) == 200)
        #expect(g.totalHeight(for: .grand) == 200)
    }
}

@Suite struct StaffLayoutDiatonicStepTests {
    @Test func middleCStep() {
        #expect(StaffLayout.diatonicStep(for: Note(pitchClass: .c, octave: 4)) == 28)
    }

    @Test func d4Step() {
        #expect(StaffLayout.diatonicStep(for: Note(pitchClass: .d, octave: 4)) == 29)
    }

    @Test func c5Step() {
        #expect(StaffLayout.diatonicStep(for: Note(pitchClass: .c, octave: 5)) == 35)
    }

    @Test func accidentalDoesNotAffectDiatonicStep() {
        let cSharp = Note(pitchClass: .c, accidental: .sharp, octave: 4)
        let cNat = Note(pitchClass: .c, octave: 4)
        #expect(StaffLayout.diatonicStep(for: cSharp) == StaffLayout.diatonicStep(for: cNat))
    }
}

@Suite struct StaffLayoutTrebleYPositionTests {
    let geometry = StaffLayout.Geometry(staffSpacing: 10, trebleStaffTopY: 20, grandStaffGap: 60)

    @Test func b4SitsOnMiddleLine() {
        let y = StaffLayout.yPosition(
            for: Note(pitchClass: .b, octave: 4),
            clef: .treble,
            geometry: geometry
        )
        #expect(y == geometry.trebleStaffTopY + 2 * geometry.staffSpacing)
        #expect(y == 40)
    }

    @Test func f5SitsOnTopLine() {
        let y = StaffLayout.yPosition(
            for: Note(pitchClass: .f, octave: 5),
            clef: .treble,
            geometry: geometry
        )
        #expect(y == geometry.trebleStaffTopY)
        #expect(y == 20)
    }

    @Test func e4SitsOnBottomLine() {
        let y = StaffLayout.yPosition(
            for: Note(pitchClass: .e, octave: 4),
            clef: .treble,
            geometry: geometry
        )
        #expect(y == geometry.trebleStaffTopY + 4 * geometry.staffSpacing)
        #expect(y == 60)
    }

    @Test func c4SitsOneLedgerBelowStaff() {
        let y = StaffLayout.yPosition(
            for: Note(pitchClass: .c, octave: 4),
            clef: .treble,
            geometry: geometry
        )
        #expect(y == geometry.trebleStaffBottomY + geometry.staffSpacing)
        #expect(y == 70)
    }

    @Test func c6SitsAboveStaff() {
        let y = StaffLayout.yPosition(
            for: Note(pitchClass: .c, octave: 6),
            clef: .treble,
            geometry: geometry
        )
        #expect(y < geometry.trebleStaffTopY)
    }
}

@Suite struct StaffLayoutBassYPositionTests {
    let geometry = StaffLayout.Geometry(staffSpacing: 10, trebleStaffTopY: 20, grandStaffGap: 60)

    @Test func d3SitsOnMiddleLine() {
        let y = StaffLayout.yPosition(
            for: Note(pitchClass: .d, octave: 3),
            clef: .bass,
            geometry: geometry
        )
        #expect(y == geometry.bassStaffTopY + 2 * geometry.staffSpacing)
        #expect(y == 140)
    }

    @Test func a3SitsOnTopLine() {
        let y = StaffLayout.yPosition(
            for: Note(pitchClass: .a, octave: 3),
            clef: .bass,
            geometry: geometry
        )
        #expect(y == geometry.bassStaffTopY)
        #expect(y == 120)
    }

    @Test func g2SitsOnBottomLine() {
        // Standard bass clef bottom line is G2 (not F2). Spec mentioned F2 but
        // music theory + the diatonic-step math agree on G2 for the bottom line.
        let y = StaffLayout.yPosition(
            for: Note(pitchClass: .g, octave: 2),
            clef: .bass,
            geometry: geometry
        )
        #expect(y == geometry.bassStaffBottomY)
        #expect(y == 160)
    }
}

@Suite struct StaffLayoutGrandStaffRoutingTests {
    let geometry = StaffLayout.Geometry(staffSpacing: 10, trebleStaffTopY: 20, grandStaffGap: 60)

    @Test func c4RoutesToTreble() {
        let grandY = StaffLayout.yPosition(
            for: Note(pitchClass: .c, octave: 4),
            clef: .grand,
            geometry: geometry
        )
        let trebleY = StaffLayout.yPosition(
            for: Note(pitchClass: .c, octave: 4),
            clef: .treble,
            geometry: geometry
        )
        #expect(grandY == trebleY)
    }

    @Test func b3RoutesToBass() {
        let grandY = StaffLayout.yPosition(
            for: Note(pitchClass: .b, octave: 3),
            clef: .grand,
            geometry: geometry
        )
        let bassY = StaffLayout.yPosition(
            for: Note(pitchClass: .b, octave: 3),
            clef: .bass,
            geometry: geometry
        )
        #expect(grandY == bassY)
    }
}

@Suite struct StaffLayoutLedgerLineTests {
    let geometry = StaffLayout.Geometry(staffSpacing: 10, trebleStaffTopY: 20, grandStaffGap: 60)

    @Test func c4InTrebleHasOneLedgerBelow() {
        let lines = StaffLayout.ledgerLineYs(
            for: Note(pitchClass: .c, octave: 4),
            clef: .treble,
            geometry: geometry
        )
        #expect(lines.count == 1)
        #expect(lines.first == geometry.trebleStaffBottomY + geometry.staffSpacing)
    }

    @Test func a3InTrebleHasTwoLedgersBelow() {
        let lines = StaffLayout.ledgerLineYs(
            for: Note(pitchClass: .a, octave: 3),
            clef: .treble,
            geometry: geometry
        )
        #expect(lines.count == 2)
    }

    @Test func c6InTrebleHasTwoLedgersAbove() {
        // C6 sits on the SECOND ledger line above the treble staff
        // (top line F5 → space G5 → ledger A5 → space B5 → ledger C6).
        let lines = StaffLayout.ledgerLineYs(
            for: Note(pitchClass: .c, octave: 6),
            clef: .treble,
            geometry: geometry
        )
        #expect(lines.count == 2)
        #expect(lines.contains(geometry.trebleStaffTopY - geometry.staffSpacing))
        #expect(lines.contains(geometry.trebleStaffTopY - 2 * geometry.staffSpacing))
    }

    @Test func a5InTrebleHasOneLedgerAbove() {
        // A5 sits on the FIRST ledger line above the treble staff.
        let lines = StaffLayout.ledgerLineYs(
            for: Note(pitchClass: .a, octave: 5),
            clef: .treble,
            geometry: geometry
        )
        #expect(lines.count == 1)
        #expect(lines.first == geometry.trebleStaffTopY - geometry.staffSpacing)
    }

    @Test func c5InTrebleHasNoLedgers() {
        let lines = StaffLayout.ledgerLineYs(
            for: Note(pitchClass: .c, octave: 5),
            clef: .treble,
            geometry: geometry
        )
        #expect(lines.isEmpty)
    }

    @Test func c4InBassHasOneLedgerAbove() {
        // C4 above the bass staff: it's exactly one staffSpacing above the top line.
        let lines = StaffLayout.ledgerLineYs(
            for: Note(pitchClass: .c, octave: 4),
            clef: .bass,
            geometry: geometry
        )
        #expect(lines.count == 1)
        #expect(lines.first == geometry.bassStaffTopY - geometry.staffSpacing)
    }

    @Test func notesOnStaffHaveNoLedgers() {
        let lines = StaffLayout.ledgerLineYs(
            for: Note(pitchClass: .b, octave: 4),
            clef: .treble,
            geometry: geometry
        )
        #expect(lines.isEmpty)
    }
}

@Suite struct StaffLayoutStemDirectionTests {
    let geometry = StaffLayout.Geometry(staffSpacing: 10, trebleStaffTopY: 20, grandStaffGap: 60)

    @Test func f5InTrebleStemsDown() {
        let dir = StaffLayout.stemDirection(
            for: Note(pitchClass: .f, octave: 5),
            clef: .treble,
            geometry: geometry
        )
        #expect(dir == .down)
    }

    @Test func c5InTrebleStemsDown() {
        let dir = StaffLayout.stemDirection(
            for: Note(pitchClass: .c, octave: 5),
            clef: .treble,
            geometry: geometry
        )
        #expect(dir == .down)
    }

    @Test func b4OnMiddleLineStemsUp() {
        // Convention: a note exactly on the middle line gets stem up (y == middleY → not < middleY).
        let dir = StaffLayout.stemDirection(
            for: Note(pitchClass: .b, octave: 4),
            clef: .treble,
            geometry: geometry
        )
        #expect(dir == .up)
    }

    @Test func e4InTrebleStemsUp() {
        let dir = StaffLayout.stemDirection(
            for: Note(pitchClass: .e, octave: 4),
            clef: .treble,
            geometry: geometry
        )
        #expect(dir == .up)
    }

    @Test func grandStaffRoutesStemDirection() {
        let high = StaffLayout.stemDirection(
            for: Note(pitchClass: .c, octave: 5),
            clef: .grand,
            geometry: geometry
        )
        let low = StaffLayout.stemDirection(
            for: Note(pitchClass: .e, octave: 2),
            clef: .grand,
            geometry: geometry
        )
        #expect(high == .down)
        #expect(low == .up)
    }
}

@Suite struct StaffLayoutAccidentalPlacementTests {
    @Test func sharpReturnsSharpGlyph() {
        let placement = StaffLayout.accidentalPlacement(
            for: Note(pitchClass: .c, accidental: .sharp, octave: 4),
            atY: 50
        )
        #expect(placement?.symbol == "♯")
        #expect(placement?.y == 50)
    }

    @Test func naturalReturnsNil() {
        let placement = StaffLayout.accidentalPlacement(
            for: Note(pitchClass: .c, octave: 4),
            atY: 50
        )
        #expect(placement == nil)
    }

    @Test func flatReturnsFlatGlyph() {
        let placement = StaffLayout.accidentalPlacement(
            for: Note(pitchClass: .b, accidental: .flat, octave: 4),
            atY: 30
        )
        #expect(placement?.symbol == "♭")
    }

    @Test func customXOffsetIsHonored() {
        let placement = StaffLayout.accidentalPlacement(
            for: Note(pitchClass: .c, accidental: .sharp, octave: 4),
            atY: 50,
            accidentalXOffset: -22
        )
        #expect(placement?.x == -22)
    }
}

@Suite struct StaffLayoutFullLayoutTests {
    let geometry = StaffLayout.Geometry(staffSpacing: 10, trebleStaffTopY: 20, grandStaffGap: 60)

    @Test func layoutCombinesAllFields() {
        let note = Note(pitchClass: .c, accidental: .sharp, octave: 4)
        let result = StaffLayout.layout(note, clef: .treble, geometry: geometry)
        #expect(result.note == note)
        #expect(result.y == 70)
        #expect(result.stem == .up)
        #expect(result.ledgerLineYs.count == 1)
        #expect(result.accidental?.symbol == "♯")
    }

    @Test func naturalNoteHasNoAccidentalPlacement() {
        let note = Note(pitchClass: .b, octave: 4)
        let result = StaffLayout.layout(note, clef: .treble, geometry: geometry)
        #expect(result.accidental == nil)
        #expect(result.ledgerLineYs.isEmpty)
    }
}

@Suite struct StaffLayoutKeySignatureGlyphsTests {
    let geometry = StaffLayout.Geometry(staffSpacing: 10, trebleStaffTopY: 20, grandStaffGap: 60)

    @Test func cMajorHasNoGlyphs() {
        let glyphs = StaffLayout.keySignatureGlyphs(.cMajor, clef: .treble, geometry: geometry)
        #expect(glyphs.isEmpty)
    }

    @Test func gMajorHasOneSharp() {
        let key = KeySignature(tonic: .g, mode: .major)
        let glyphs = StaffLayout.keySignatureGlyphs(key, clef: .treble, geometry: geometry)
        #expect(glyphs.count == 1)
        #expect(glyphs.first?.symbol == "♯")
    }

    @Test func fMajorHasOneFlat() {
        let key = KeySignature(tonic: .f, mode: .major)
        let glyphs = StaffLayout.keySignatureGlyphs(key, clef: .treble, geometry: geometry)
        #expect(glyphs.count == 1)
        #expect(glyphs.first?.symbol == "♭")
    }

    @Test func glyphSpacingIsApplied() {
        let key = KeySignature(tonic: .d, mode: .major)
        let glyphs = StaffLayout.keySignatureGlyphs(
            key,
            clef: .treble,
            geometry: geometry,
            startX: 0,
            glyphSpacing: 12
        )
        #expect(glyphs.count == 2)
        #expect(glyphs[0].x == 0)
        #expect(glyphs[1].x == 12)
    }

    @Test func bassClefShiftsOctaveDown() {
        let key = KeySignature(tonic: .g, mode: .major)
        let trebleGlyphs = StaffLayout.keySignatureGlyphs(key, clef: .treble, geometry: geometry)
        let bassGlyphs = StaffLayout.keySignatureGlyphs(key, clef: .bass, geometry: geometry)
        #expect(trebleGlyphs.count == bassGlyphs.count)
        // Both should produce the same number of glyphs at potentially different y positions.
    }
}
