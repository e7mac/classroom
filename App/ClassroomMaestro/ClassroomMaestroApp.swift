import SwiftUI
import MusicTheory
import MusicRendering

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
        .frame(minWidth: 720, minHeight: 480)
    }
}

#Preview {
    ContentView()
}
