import SwiftUI
import MusicTheory
import MusicRendering
import AppCore

public struct ToolPaletteView: View {
    @Binding public var displayMode: DisplayMode
    @Binding public var keySignature: KeySignature
    @Binding public var clefMode: StaffLayout.Clef
    @Binding public var analysisDisplayMode: AnalysisDisplayMode
    @Binding public var analysisOverlayVisible: Bool
    @Binding public var hideKeySignatureFromStaff: Bool
    public let freeze: FreezeState
    public let onCycleEnharmonic: () -> Void
    public let onClearProgression: (() -> Void)?

    @State private var keySignaturePopoverVisible = false

    public init(
        displayMode: Binding<DisplayMode>,
        keySignature: Binding<KeySignature>,
        clefMode: Binding<StaffLayout.Clef>,
        analysisDisplayMode: Binding<AnalysisDisplayMode>,
        analysisOverlayVisible: Binding<Bool>,
        hideKeySignatureFromStaff: Binding<Bool>,
        freeze: FreezeState,
        onCycleEnharmonic: @escaping () -> Void,
        onClearProgression: (() -> Void)? = nil
    ) {
        self._displayMode = displayMode
        self._keySignature = keySignature
        self._clefMode = clefMode
        self._analysisDisplayMode = analysisDisplayMode
        self._analysisOverlayVisible = analysisOverlayVisible
        self._hideKeySignatureFromStaff = hideKeySignatureFromStaff
        self.freeze = freeze
        self.onCycleEnharmonic = onCycleEnharmonic
        self.onClearProgression = onClearProgression
    }

    public var body: some View {
        HStack(spacing: 12) {
            modeSegment
            Divider().frame(height: 24)
            clefSegment
            Divider().frame(height: 24)
            keySignatureButton
            Divider().frame(height: 24)
            analysisToggle
            analysisVisibilityToggle
            enharmonicButton
            if displayMode == .chordProgression, let onClearProgression {
                Button {
                    onClearProgression()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .help("Clear progression history")
            }
            Divider().frame(height: 24)
            freezeIndicator
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 1)
    }

    private var modeSegment: some View {
        Picker("Mode", selection: $displayMode) {
            ForEach(DisplayMode.allCases, id: \.self) { mode in
                Image(systemName: symbol(for: mode))
                    .help(modeTooltip(for: mode))
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 240)
    }

    private func modeTooltip(for mode: DisplayMode) -> String {
        let shortcut = "(\(mode.rawValue))"
        switch mode {
        case .singleNote:        return "Single Note — show only the most recent note \(shortcut)"
        case .interval:          return "Interval — show 2 notes and identify the interval \(shortcut)"
        case .chord:             return "Chord — show 3–4 notes and identify the chord \(shortcut)"
        case .scale:             return "Scale — show up to 8 notes and match against scale templates \(shortcut)"
        case .chordProgression:  return "Chord Progression — accumulate chords; sustain pedal commits \(shortcut)"
        case .handPosition:      return "Hand Position — show 5-finger hand position guide \(shortcut)"
        }
    }

    private func symbol(for mode: DisplayMode) -> String {
        switch mode {
        case .singleNote:        return "music.note"
        case .interval:          return "arrow.left.and.right"
        case .chord:             return "square.stack.3d.up.fill"
        case .scale:             return "music.note.list"
        case .chordProgression:  return "square.grid.3x3.fill"
        case .handPosition:      return "hand.raised.fill"
        }
    }

    private var clefSegment: some View {
        Picker("Clef", selection: $clefMode) {
            Text("Treble").tag(StaffLayout.Clef.treble)
            Text("Grand").tag(StaffLayout.Clef.grand)
            Text("Bass").tag(StaffLayout.Clef.bass)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 200)
        .help("Clef — press K to cycle")
    }

    private var keySignatureButton: some View {
        Button {
            keySignaturePopoverVisible.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "key")
                Text(keySignatureLabel)
            }
        }
        .buttonStyle(.bordered)
        .help("Key Signature — \(keySignatureLabel) (⌘K to open picker; S toggles staff display)")
        .popover(isPresented: $keySignaturePopoverVisible) {
            KeySignaturePicker(selection: $keySignature) {
                keySignaturePopoverVisible = false
            }
        }
    }

    private var keySignatureLabel: String {
        let tonic = "\(keySignature.tonic.letterName)\(keySignature.accidental.displaySymbol)"
        let mode = keySignature.mode == .major ? "" : "m"
        return "\(tonic)\(mode)"
    }

    private var analysisToggle: some View {
        Picker("Analysis", selection: $analysisDisplayMode) {
            Text("Cmaj7").tag(AnalysisDisplayMode.popJazz)
            Text("Imaj7").tag(AnalysisDisplayMode.romanNumeral)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 140)
        .help("Analysis Style — Pop/Jazz chord symbols vs Roman numerals")
    }

    private var analysisVisibilityToggle: some View {
        Toggle(isOn: $analysisOverlayVisible) {
            Image(systemName: analysisOverlayVisible ? "eye" : "eye.slash")
        }
        .toggleStyle(.button)
        .help(analysisOverlayVisible
              ? "Hide Analysis Overlay (A)"
              : "Show Analysis Overlay (A)")
    }

    private var enharmonicButton: some View {
        Button {
            onCycleEnharmonic()
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
        }
        .buttonStyle(.bordered)
        .help("Cycle Enharmonic Spelling (E) — e.g. C♯ ↔ D♭")
    }

    private var freezeIndicator: some View {
        Image(systemName: "snowflake")
            .foregroundStyle(freeze.isFrozen ? Color.blue : Color.clear)
            .help(freeze.isFrozen
                  ? "Display Frozen — Caps Lock or sustain pedal held"
                  : "Display Live — press Caps Lock or hold sustain pedal to freeze")
            .accessibilityHidden(!freeze.isFrozen)
            .accessibilityLabel(freeze.isFrozen ? "Frozen" : "")
    }
}

#Preview("Default state") {
    @Previewable @State var mode: DisplayMode = .singleNote
    @Previewable @State var key: KeySignature = .cMajor
    @Previewable @State var clef: StaffLayout.Clef = .grand
    @Previewable @State var analysis: AnalysisDisplayMode = .popJazz
    @Previewable @State var visible = true
    @Previewable @State var hideKeySig = false

    return ToolPaletteView(
        displayMode: $mode,
        keySignature: $key,
        clefMode: $clef,
        analysisDisplayMode: $analysis,
        analysisOverlayVisible: $visible,
        hideKeySignatureFromStaff: $hideKeySig,
        freeze: FreezeState(),
        onCycleEnharmonic: {},
        onClearProgression: {}
    )
    .padding()
}

#Preview("Frozen + chord progression mode") {
    @Previewable @State var mode: DisplayMode = .chordProgression
    @Previewable @State var key: KeySignature = .cMajor
    @Previewable @State var clef: StaffLayout.Clef = .grand
    @Previewable @State var analysis: AnalysisDisplayMode = .romanNumeral
    @Previewable @State var visible = true
    @Previewable @State var hideKeySig = false

    return ToolPaletteView(
        displayMode: $mode,
        keySignature: $key,
        clefMode: $clef,
        analysisDisplayMode: $analysis,
        analysisOverlayVisible: $visible,
        hideKeySignatureFromStaff: $hideKeySig,
        freeze: FreezeState(capsLockFrozen: true),
        onCycleEnharmonic: {},
        onClearProgression: {}
    )
    .padding()
}
