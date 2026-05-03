import SwiftUI
import MusicTheory
import MusicRendering
import AppCore

@main
struct ClassroomMaestroApp: App {
    var body: some Scene {
        WindowGroup("ClassroomMaestro") {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
    }
}

struct ContentView: View {
    @State private var notes: [Note] = []

    private var pressedMIDI: Set<Int> {
        Set(notes.map(\.midiNumber))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("ClassroomMaestro")
                .font(.largeTitle)

            StaffView(
                notes: notes,
                keySignature: .cMajor,
                clef: .grand
            )
            .frame(maxWidth: 640, minHeight: 280)

            KeyboardView(
                pressedMIDI: pressedMIDI,
                lowMIDI: 48,
                highMIDI: 84
            )
            .frame(maxWidth: 640, minHeight: 100, maxHeight: 120)

            HStack {
                Button("C major") {
                    notes = [Note(midi: 60), Note(midi: 64), Note(midi: 67)]
                }
                Button("G7") {
                    notes = [Note(midi: 55), Note(midi: 59), Note(midi: 62), Note(midi: 65)]
                }
                Button("Clear") {
                    notes = []
                }
            }
        }
        .padding()
        .frame(minWidth: 720, minHeight: 540)
    }
}

#Preview {
    ContentView()
}
