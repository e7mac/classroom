import SwiftUI
import ClassroomTheory
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

    /// Fixed headroom above the top staff line. Staff position must NOT move
    /// based on what's being played — that's distracting (especially on iPad
    /// where the frame shifts visibly). Notes outside this fixed window get
    /// rendered with 8va / 8vb octave markers (see drawNotes).
    private var ledgerHeadroomAboveStaff: CGFloat {
        // Reserve a constant 5 ledger-line slots above + base padding.
        // Anything higher (~A6+) gets transposed down with an 8va indicator.
        30 + 5 * staffSpacing
    }

    private var ledgerFootroomBelowStaff: CGFloat {
        // Same idea below: constant 5 slots; anything lower gets 8vb.
        30 + 5 * staffSpacing
    }

    /// Pitch ranges that fit comfortably WITHOUT octave transposition, given
    /// the fixed headroom above. Notes outside this window are rendered an
    /// octave (or two) closer to the staff with an 8va/8vb marker.
    private func octaveAdjusted(_ note: Note) -> (note: Note, octaveShift: Int) {
        let step = note.octave * 7 + note.pitchClass.rawValue
        switch clef {
        case .treble:
            // Top line F5 = step 38; with 5 ledger slots = ~10 steps above = step 48 = G6
            // Bottom line E4 = step 30; 5 slots = ~10 below = step 20 = D2 (well below treble use)
            if step > 48 {
                let shifts = (step - 48 + 6) / 7   // round up to nearest octave
                return (transposed(note, byOctaves: -shifts), shifts)
            }
            if step < 20 {
                let shifts = (20 - step + 6) / 7
                return (transposed(note, byOctaves: shifts), -shifts)
            }
        case .bass:
            // Bass top A3 = step 24; bottom G2 = step 18
            // 5 slots above top = step 34 = E5
            // 5 slots below bottom = step 8 = B0
            if step > 34 {
                let shifts = (step - 34 + 6) / 7
                return (transposed(note, byOctaves: -shifts), shifts)
            }
            if step < 8 {
                let shifts = (8 - step + 6) / 7
                return (transposed(note, byOctaves: shifts), -shifts)
            }
        case .grand:
            // Grand staff covers everything from bass through treble; only really
            // extreme notes (>C7 or <A0) need transposition.
            // C7 = step 49; A0 = step 14
            if step > 49 {
                let shifts = (step - 49 + 6) / 7
                return (transposed(note, byOctaves: -shifts), shifts)
            }
            if step < 14 {
                let shifts = (14 - step + 6) / 7
                return (transposed(note, byOctaves: shifts), -shifts)
            }
        }
        return (note, 0)
    }

    private func transposed(_ note: Note, byOctaves shifts: Int) -> Note {
        Note(pitchClass: note.pitchClass, accidental: note.accidental, octave: note.octave + shifts)
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

        // Transpose extreme notes into the visible staff window so the staff
        // itself doesn't grow vertically. Track the per-note shift so we can
        // render an 8va / 8vb marker telling the user what was transposed.
        let adjusted: [(layout: StaffLayout.NoteLayout, shift: Int)] = notes.map {
            let (n, shift) = octaveAdjusted($0)
            return (StaffLayout.layout(n, clef: clef, geometry: geo), shift)
        }

        let noteAreaStart = clefAreaWidth + keySignatureAreaWidth + 16
        let noteAreaEnd = max(size.width - 16, noteAreaStart + 40)
        let centerX = (noteAreaStart + noteAreaEnd) / 2

        // All displayed notes are sounding simultaneously, so render as a stacked
        // chord at one x. Apply standard 2nd-interval offset: when two diatonic
        // steps are adjacent, displace one notehead by ~one notehead width so
        // the heads don't overlap. Compute by scanning the chord bottom-up.
        let noteheadWidth = geo.staffSpacing * 1.3
        let xOffsets = computeNoteheadXOffsets(for: adjusted.map(\.layout), staffSpacing: geo.staffSpacing)

        for (i, item) in adjusted.enumerated() {
            let x = centerX + xOffsets[i] * noteheadWidth
            drawNote(item.layout, octaveShift: item.shift, at: x, in: &context, geometry: geo)
        }
    }

    /// Returns one offset per input note (in input order). 0 = on the stem axis;
    /// 1 = displaced one notehead-width to the right.
    /// Convention: when two notes are adjacent diatonic steps (≤1 step apart on
    /// the staff), the upper one shifts right; the lower stays on the axis.
    private func computeNoteheadXOffsets(for layouts: [StaffLayout.NoteLayout], staffSpacing: CGFloat) -> [CGFloat] {
        // Sort by y (top→bottom on screen, which is highest pitch first since y grows down).
        let indexed = layouts.enumerated().map { ($0.offset, $0.element.y) }
        let sorted = indexed.sorted { $0.1 < $1.1 }   // smallest y (highest pitch) first

        var offsets = [CGFloat](repeating: 0, count: layouts.count)
        // Walk pairs from the top down; when two adjacent notes are within 1 step
        // (= staffSpacing/2) of each other, shift the lower one of the pair right.
        // Half-spacing tolerance handles unisons too.
        let stepThreshold = staffSpacing / 2 + 0.5
        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let curr = sorted[i]
            if abs(curr.1 - prev.1) < stepThreshold {
                // If the previous one isn't already shifted, shift this one.
                if offsets[prev.0] == 0 {
                    offsets[curr.0] = 1
                } else {
                    offsets[curr.0] = 0
                }
            }
        }
        return offsets
    }

    private func drawNote(
        _ layout: StaffLayout.NoteLayout,
        octaveShift: Int,
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

        if octaveShift != 0 {
            drawOctaveMarker(
                shift: octaveShift,
                noteX: x,
                noteY: layout.y,
                in: &context,
                geometry: geo
            )
        }
    }

    private func drawOctaveMarker(
        shift: Int,
        noteX: CGFloat,
        noteY: CGFloat,
        in context: inout GraphicsContext,
        geometry geo: StaffLayout.Geometry
    ) {
        // 8va = up an octave; 15ma = up two; 8vb = down; 15mb = down two.
        let label: String
        switch abs(shift) {
        case 1: label = "8"
        case 2: label = "15"
        default: label = "\(abs(shift) * 7 + 1)"
        }
        let suffix = shift > 0 ? "va" : "vb"
        let combined = "\(label)\(suffix)"

        let isAbove = shift > 0
        // Sit just above/below the notehead, not far away — keeps the marker
        // visually attached to the note without pushing layout around.
        let yOffset: CGFloat = isAbove
            ? -(geo.staffSpacing * 1.6)
            :  (geo.staffSpacing * 1.6)
        let labelY = noteY + yOffset

        let txt = context.resolve(
            Text(combined)
                .font(.system(size: geo.staffSpacing * 1.1, weight: .semibold).italic())
                .foregroundColor(.primary.opacity(0.85))
        )
        context.draw(txt, at: CGPoint(x: noteX, y: labelY), anchor: .center)
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
