import SwiftUI

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
    var body: some View {
        VStack(spacing: 12) {
            Text("ClassroomMaestro")
                .font(.largeTitle)
            Text("Project skeleton — Milestone 1")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
