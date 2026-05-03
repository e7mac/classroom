import SwiftUI
import AppKit
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
                    container.widgetManager.restorePreviouslyOpenWidgets()
                }
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About ClassroomMaestro") {
                    NSApp.orderFrontStandardAboutPanel(options: [
                        .applicationName: "ClassroomMaestro",
                        .applicationVersion: "0.1.0",
                        .credits: NSAttributedString(
                            string: "Music education classroom display tool.\nUses Bravura SMuFL font (SIL OFL).",
                            attributes: [.foregroundColor: NSColor.secondaryLabelColor]
                        )
                    ])
                }
            }

            CommandGroup(after: .toolbar) {
                Button("Open Key Signature Picker") {
                    NotificationCenter.default.post(name: .openKeySignaturePicker, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])

                Button("Save Layout") {
                    NotificationCenter.default.post(name: .openSaveLayoutDialog, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}

extension Notification.Name {
    static let openKeySignaturePicker = Notification.Name("openKeySignaturePicker")
}
