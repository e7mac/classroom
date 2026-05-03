import SwiftUI
import AppCore
import MusicTheory
import MusicRendering
import AudioInput

@main
struct ClassroomMaestroApp: App {
    @StateObject private var container = AppStateContainer()

    var body: some Scene {
        WindowGroup("ClassroomMaestro") {
            MainView()
                .environmentObject(container)
                .environmentObject(container.appState)
                .frame(minWidth: 900, minHeight: 720)
                .task {
                    await container.startMIDI()
                }
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Open Key Signature Picker") {
                    NotificationCenter.default.post(name: .openKeySignaturePicker, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    static let openKeySignaturePicker = Notification.Name("openKeySignaturePicker")
}
