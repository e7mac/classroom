import SwiftUI
import MusicTheory
import MusicRendering
import AppCore

@main
struct ClassroomMaestroApp: App {
    var body: some Scene {
        WindowGroup("ClassroomMaestro") {
            ContentView()
                .frame(minWidth: 900, minHeight: 700)
        }
        .windowStyle(.titleBar)
    }
}

struct ContentView: View {
    @State private var notes: [Note] = []
    @State private var displayMode: DisplayMode = .chord
    @State private var keySignature: KeySignature = .cMajor
    @State private var clefMode: StaffLayout.Clef = .grand
    @State private var analysisDisplayMode: AnalysisDisplayMode = .popJazz
    @State private var analysisOverlayVisible = true
    @State private var hideKeySigFromStaff = false

    private let engine = MusicTheoryEngine()

    private var pressedMIDI: Set<Int> {
        Set(notes.map(\.midiNumber))
    }

    private var analysis: Analysis {
        guard !notes.isEmpty else { return .empty }
        if let chord = engine.identifyChord(notes) {
            let roman = engine.romanNumeral(for: chord, in: keySignature)
            return Analysis(chord: chord, romanNumeral: roman)
        }
        if notes.count == 2 {
            return Analysis(interval: engine.interval(from: notes[0], to: notes[1]))
        }
        if notes.count >= 3, let scale = engine.identifyScales(notes).first {
            return Analysis(scale: scale)
        }
        return .empty
    }

    var body: some View {
        VStack(spacing: 16) {
            ToolPaletteView(
                displayMode: $displayMode,
                keySignature: $keySignature,
                clefMode: $clefMode,
                analysisDisplayMode: $analysisDisplayMode,
                analysisOverlayVisible: $analysisOverlayVisible,
                hideKeySignatureFromStaff: $hideKeySigFromStaff,
                freeze: FreezeState(),
                onCycleEnharmonic: {},
                onClearProgression: { notes = [] }
            )

            AnalysisOverlayView(
                analysis: analysis,
                displayMode: analysisDisplayMode,
                isVisible: analysisOverlayVisible
            )

            StaffView(
                notes: notes,
                keySignature: keySignature,
                clef: clefMode,
                showKeySignature: !hideKeySigFromStaff
            )
            .frame(maxWidth: 720, minHeight: 280)

            KeyboardView(
                pressedMIDI: pressedMIDI,
                lowMIDI: 48,
                highMIDI: 84
            )
            .frame(maxWidth: 720, minHeight: 100, maxHeight: 120)

            HStack {
                Button("C major") {
                    notes = [Note(midi: 60), Note(midi: 64), Note(midi: 67)]
                }
                Button("G7") {
                    notes = [Note(midi: 55), Note(midi: 59), Note(midi: 62), Note(midi: 65)]
                }
                Button("F major scale") {
                    notes = [
                        Note(midi: 65), Note(midi: 67), Note(midi: 69), Note(midi: 70),
                        Note(midi: 72), Note(midi: 74), Note(midi: 76), Note(midi: 77),
                    ]
                }
                Button("Clear") {
                    notes = []
                }
            }
        }
        .padding()
        .frame(minWidth: 900, minHeight: 700)
    }
}

#Preview {
    ContentView()
}
