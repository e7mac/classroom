import SwiftUI
import MusicTheory
import MusicRendering
import AppCore

public struct StaffView: View {
    public let notes: [Note]
    public let keySignature: KeySignature
    public let clef: StaffLayout.Clef
    public let showKeySignature: Bool
    public let staffSpacing: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        notes: [Note],
        keySignature: KeySignature = .cMajor,
        clef: StaffLayout.Clef = .grand,
        showKeySignature: Bool = true,
        staffSpacing: CGFloat = 12
    ) {
        self.notes = notes
        self.keySignature = keySignature
        self.clef = clef
        self.showKeySignature = showKeySignature
        self.staffSpacing = staffSpacing
    }

    private var geometry: StaffLayout.Geometry {
        StaffLayout.Geometry(
            staffSpacing: staffSpacing,
            trebleStaffTopY: ledgerHeadroomAboveStaff,
            grandStaffGap: 60
        )
    }

    /// Extra space reserved above the top staff line so ledger lines and
    /// noteheads on high notes (e.g. C7) aren't clipped at the top of the canvas.
    private var ledgerHeadroomAboveStaff: CGFloat {
        // Default 30pt + 1 staffSpacing per ledger line slot we might need.
        // Cap so the staff doesn't drift absurdly far down for a single C8.
        let extraSlots = max(0, maxLedgerSlotsAboveTopLine())
        return 30 + CGFloat(min(extraSlots, 8)) * staffSpacing
    }

    /// Extra space reserved below the bottom staff line for low-note ledger lines.
    private var ledgerFootroomBelowStaff: CGFloat {
        let extraSlots = max(0, maxLedgerSlotsBelowBottomLine())
        return 30 + CGFloat(min(extraSlots, 8)) * staffSpacing
    }

    private func maxLedgerSlotsAboveTopLine() -> Int {
        // Treble top line is F5 (diatonic step 5*7+3 = 38).
        // Each diatonic step above adds half a staff space; ledger lines occur
        // every two steps. 1 ledger line = 2 steps above F5.
        let topLineStep = 5 * 7 + 3   // F5
        let highestStep = notes.map { staffLayoutStep(for: $0) }.max() ?? topLineStep
        let stepsAbove = max(0, highestStep - topLineStep)
        return Int(ceil(Double(stepsAbove) / 2.0))
    }

    private func maxLedgerSlotsBelowBottomLine() -> Int {
        // Bass bottom line is G2 (diatonic step 2*7+4 = 18).
        // For grand or treble, the lowest visible reference is bass G2 if grand,
        // treble E4 (28) if treble-only.
        let bottomLineStep: Int
        switch clef {
        case .treble: bottomLineStep = 4 * 7 + 2  // E4
        case .bass:   bottomLineStep = 2 * 7 + 4  // G2
        case .grand:  bottomLineStep = 2 * 7 + 4  // G2
        }
        let lowestStep = notes.map { staffLayoutStep(for: $0) }.min() ?? bottomLineStep
        let stepsBelow = max(0, bottomLineStep - lowestStep)
        return Int(ceil(Double(stepsBelow) / 2.0))
    }

    private func staffLayoutStep(for note: Note) -> Int {
        note.octave * 7 + note.pitchClass.rawValue
    }

    private var clefSet: ClefSet { ClefSet(clef: clef) }

    private var keySignatureGlyphSpacing: CGFloat { staffSpacing * 1.15 }

    private var clefAreaWidth: CGFloat { 60 }

    private var keySignatureAreaWidth: CGFloat {
        guard showKeySignature else { return 0 }
        let count = keySignature.sharpsAndFlats.count
        guard count > 0 else { return 0 }
        return CGFloat(count) * keySignatureGlyphSpacing + 8
    }

    public var body: some View {
        let geo = geometry
        Canvas(rendersAsynchronously: false) { context, size in
            draw(in: &context, size: size, geometry: geo)
        }
        .frame(minHeight: geo.totalHeight(for: clef) + ledgerFootroomBelowStaff)
        .animation(.reduceMotionAware(.easeInOut(duration: 0.18), reduceMotion: reduceMotion), value: notes)
        .accessibilityLabel(accessibilityDescription)
        .onAppear { BravuraFont.registerIfNeeded() }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        let clefName: String
        switch clef {
        case .treble: clefName = "treble clef"
        case .bass: clefName = "bass clef"
        case .grand: clefName = "grand staff"
        }
        if notes.isEmpty {
            return "Empty \(clefName)"
        }
        let names = notes.map { $0.description }.joined(separator: ", ")
        return "\(clefName) showing \(names)"
    }

    // MARK: - Composite drawing

    private func draw(in context: inout GraphicsContext, size: CGSize, geometry geo: StaffLayout.Geometry) {
        let leftEdge: CGFloat = 8
        let rightEdge = max(size.width - 8, leftEdge + 100)

        drawStaffLines(in: &context, leftEdge: leftEdge, rightEdge: rightEdge, geometry: geo)
        drawClefs(in: &context, geometry: geo)
        drawKeySignature(in: &context, geometry: geo)
        drawNotes(in: &context, size: size, geometry: geo)
    }

    // MARK: - Staff lines

    private func drawStaffLines(
        in context: inout GraphicsContext,
        leftEdge: CGFloat,
        rightEdge: CGFloat,
        geometry geo: StaffLayout.Geometry
    ) {
        if clefSet.showsTreble {
            drawFiveLineStaff(in: &context, topY: geo.trebleStaffTopY, leftEdge: leftEdge, rightEdge: rightEdge, geometry: geo)
        }
        if clefSet.showsBass {
            drawFiveLineStaff(in: &context, topY: geo.bassStaffTopY, leftEdge: leftEdge, rightEdge: rightEdge, geometry: geo)
        }
        if clef == .grand {
            // Vertical brace bars on left & right join the two staves
            var leftBar = Path()
            leftBar.move(to: CGPoint(x: leftEdge, y: geo.trebleStaffTopY))
            leftBar.addLine(to: CGPoint(x: leftEdge, y: geo.bassStaffBottomY))
            context.stroke(leftBar, with: .color(.primary), lineWidth: 1.5)

            var rightBar = Path()
            rightBar.move(to: CGPoint(x: rightEdge, y: geo.trebleStaffTopY))
            rightBar.addLine(to: CGPoint(x: rightEdge, y: geo.bassStaffBottomY))
            context.stroke(rightBar, with: .color(.primary), lineWidth: 1.5)
        }
    }

    private func drawFiveLineStaff(
        in context: inout GraphicsContext,
        topY: CGFloat,
        leftEdge: CGFloat,
        rightEdge: CGFloat,
        geometry geo: StaffLayout.Geometry
    ) {
        for i in 0..<5 {
            let y = topY + CGFloat(i) * geo.staffSpacing
            var p = Path()
            p.move(to: CGPoint(x: leftEdge, y: y))
            p.addLine(to: CGPoint(x: rightEdge, y: y))
            context.stroke(p, with: .color(.primary), lineWidth: 1)
        }
    }

    // MARK: - Clefs

    private func drawClefs(in context: inout GraphicsContext, geometry geo: StaffLayout.Geometry) {
        // Bravura: 1 em = 4 staff spaces. Em box is centered on the baseline, so drawing
        // with `.center` anchor at the staff line a clef references puts the glyph
        // approximately right. Y nudges below absorb any per-glyph asymmetry.
        let fontSize = geo.staffSpacing * 4.0
        let clefX: CGFloat = 36

        if clefSet.showsTreble {
            let trebleY = geo.trebleStaffTopY + 3 * geo.staffSpacing
            let txt = context.resolve(
                Text(BravuraFont.Glyph.trebleClef)
                    .font(.custom(BravuraFont.name, size: fontSize))
                    .foregroundColor(.primary)
            )
            context.draw(txt, at: CGPoint(x: clefX, y: trebleY), anchor: .center)
        }

        if clefSet.showsBass {
            let bassY = geo.bassStaffTopY + geo.staffSpacing
            let txt = context.resolve(
                Text(BravuraFont.Glyph.bassClef)
                    .font(.custom(BravuraFont.name, size: fontSize))
                    .foregroundColor(.primary)
            )
            context.draw(txt, at: CGPoint(x: clefX, y: bassY), anchor: .center)
        }
    }

    // MARK: - Key signature

    private func drawKeySignature(in context: inout GraphicsContext, geometry geo: StaffLayout.Geometry) {
        guard showKeySignature, !keySignature.sharpsAndFlats.isEmpty else { return }
        let fontSize = geo.staffSpacing * 4.0
        let startX = clefAreaWidth

        if clefSet.showsTreble {
            drawAccidentals(
                glyphs: StaffLayout.keySignatureGlyphs(
                    keySignature, clef: .treble, geometry: geo,
                    startX: startX, glyphSpacing: keySignatureGlyphSpacing
                ),
                fontSize: fontSize,
                context: &context
            )
        }
        if clefSet.showsBass {
            drawAccidentals(
                glyphs: StaffLayout.keySignatureGlyphs(
                    keySignature, clef: .bass, geometry: geo,
                    startX: startX, glyphSpacing: keySignatureGlyphSpacing
                ),
                fontSize: fontSize,
                context: &context
            )
        }
    }

    private func drawAccidentals(
        glyphs: [StaffLayout.GlyphPlacement],
        fontSize: CGFloat,
        context: inout GraphicsContext
    ) {
        for g in glyphs {
            let smufl = BravuraFont.smufl(forAccidentalSymbol: g.symbol)
            let txt = context.resolve(
                Text(smufl)
                    .font(.custom(BravuraFont.name, size: fontSize))
                    .foregroundColor(.primary)
            )
            // Bravura accidentals center vertically on the staff line/space they belong to.
            context.draw(txt, at: CGPoint(x: g.x, y: g.y), anchor: .center)
        }
    }

    // MARK: - Notes

    private func drawNotes(in context: inout GraphicsContext, size: CGSize, geometry geo: StaffLayout.Geometry) {
        guard !notes.isEmpty else { return }
        let layouts = notes.map { StaffLayout.layout($0, clef: clef, geometry: geo) }

        let noteAreaStart = clefAreaWidth + keySignatureAreaWidth + 16
        let noteAreaEnd = max(size.width - 16, noteAreaStart + 40)

        for (i, layout) in layouts.enumerated() {
            let x: CGFloat
            if layouts.count == 1 {
                x = noteAreaStart + (noteAreaEnd - noteAreaStart) / 2
            } else {
                let spacing = (noteAreaEnd - noteAreaStart) / CGFloat(layouts.count + 1)
                x = noteAreaStart + spacing * CGFloat(i + 1)
            }
            drawNote(layout, at: x, in: &context, geometry: geo)
        }
    }

    private func drawNote(
        _ layout: StaffLayout.NoteLayout,
        at x: CGFloat,
        in context: inout GraphicsContext,
        geometry geo: StaffLayout.Geometry
    ) {
        let noteheadWidth = geo.staffSpacing * 1.3
        let noteheadHeight = geo.staffSpacing * 0.95
        let headRect = CGRect(
            x: x - noteheadWidth / 2,
            y: layout.y - noteheadHeight / 2,
            width: noteheadWidth,
            height: noteheadHeight
        )

        context.fill(Path(ellipseIn: headRect), with: .color(.primary))

        let stemHeight = geo.staffSpacing * 3.5
        let stemX: CGFloat
        let stemY1: CGFloat
        let stemY2: CGFloat
        switch layout.stem {
        case .up:
            stemX = headRect.maxX - 0.5
            stemY1 = layout.y
            stemY2 = layout.y - stemHeight
        case .down:
            stemX = headRect.minX + 0.5
            stemY1 = layout.y
            stemY2 = layout.y + stemHeight
        }
        var stemPath = Path()
        stemPath.move(to: CGPoint(x: stemX, y: stemY1))
        stemPath.addLine(to: CGPoint(x: stemX, y: stemY2))
        context.stroke(stemPath, with: .color(.primary), lineWidth: 1.5)

        let ledgerWidth = geo.staffSpacing * 1.8
        for ly in layout.ledgerLineYs {
            var p = Path()
            p.move(to: CGPoint(x: x - ledgerWidth / 2, y: ly))
            p.addLine(to: CGPoint(x: x + ledgerWidth / 2, y: ly))
            context.stroke(p, with: .color(.primary), lineWidth: 1)
        }

        if let acc = layout.accidental {
            let smufl = BravuraFont.smufl(forAccidentalSymbol: acc.symbol)
            let txt = context.resolve(
                Text(smufl)
                    .font(.custom(BravuraFont.name, size: geo.staffSpacing * 4.0))
                    .foregroundColor(.primary)
            )
            context.draw(txt, at: CGPoint(x: x + acc.x, y: acc.y), anchor: .center)
        }
    }
}

// MARK: - Previews

#Preview("Treble — C major") {
    StaffView(
        notes: [Note(midi: 60), Note(midi: 64), Note(midi: 67)],
        keySignature: .cMajor,
        clef: .treble
    )
    .frame(width: 480, height: 160)
    .padding()
}

#Preview("Grand — E♭ major") {
    StaffView(
        notes: [Note(midi: 51), Note(midi: 63), Note(midi: 67), Note(midi: 75)],
        keySignature: KeySignature(tonic: .e, accidental: .flat, mode: .major),
        clef: .grand
    )
    .frame(width: 520, height: 280)
    .padding()
}

#Preview("Bass — empty") {
    StaffView(
        notes: [],
        keySignature: KeySignature(tonic: .b, accidental: .flat, mode: .major),
        clef: .bass
    )
    .frame(width: 480, height: 160)
    .padding()
}

#Preview("Treble — high & low extremes") {
    StaffView(
        notes: [Note(midi: 36), Note(midi: 96)],
        clef: .grand
    )
    .frame(width: 520, height: 320)
    .padding()
}

#Preview("With sharps and flats") {
    StaffView(
        notes: [
            Note(pitchClass: .c, accidental: .sharp, octave: 4),
            Note(pitchClass: .e, accidental: .flat, octave: 4),
            Note(pitchClass: .g, accidental: .sharp, octave: 4),
        ],
        clef: .treble
    )
    .frame(width: 480, height: 160)
    .padding()
}

#Preview("Dark mode") {
    StaffView(
        notes: [Note(midi: 60), Note(midi: 64), Note(midi: 67)],
        clef: .treble
    )
    .frame(width: 480, height: 160)
    .padding()
    .preferredColorScheme(.dark)
}
