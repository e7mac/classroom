import SwiftUI
import AppKit
import AppCore
import MusicRendering

// Spec re-interpretation for v1:
// The original spec mapped K = "toggle keyboard visibility" and S = "toggle staff
// visibility" — both intended for quiz mode. Quiz mode is deferred per product
// decision, so K and S are repurposed to give the user 4 useful single-letter
// shortcuts today:
//   A — Toggle analysis overlay
//   E — Cycle enharmonic spelling
//   K — Cycle clef mode (treble → grand → bass → treble)
//   S — Toggle "hide key signature from staff"
//   1–6 — Display mode
//   Caps Lock — Freeze
// Cmd+K opens the key-signature picker; that lives in SwiftUI .commands, not here.
@MainActor
final class KeyboardShortcutsMonitor {
    private var monitor: Any?
    private var lastCapsLockState: Bool
    private weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
        self.lastCapsLockState = NSEvent.modifierFlags.contains(.capsLock)
    }

    func install() {
        guard monitor == nil else { return }
        // Local NSEvent monitors are invoked on the main thread, so we can safely
        // hop into MainActor isolation synchronously to touch our state and AppState.
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handle(event) ?? event
            }
        }
    }

    func uninstall() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        guard let appState else { return event }

        if event.type == .flagsChanged {
            let capsOn = event.modifierFlags.contains(.capsLock)
            if capsOn != lastCapsLockState {
                lastCapsLockState = capsOn
                appState.toggleCapsLockFreeze()
            }
            return event
        }

        // Pure single-letter shortcuts only — defer to system on any modifier.
        let modifiers = event.modifierFlags.intersection([.command, .control, .option])
        guard modifiers.isEmpty else { return event }

        guard let chars = event.charactersIgnoringModifiers?.lowercased() else { return event }
        switch chars {
        case "a":
            appState.analysisOverlayVisible.toggle()
            return nil
        case "e":
            appState.cycleEnharmonic()
            return nil
        case "k":
            switch appState.clefMode {
            case .treble: appState.clefMode = .grand
            case .grand:  appState.clefMode = .bass
            case .bass:   appState.clefMode = .treble
            }
            return nil
        case "s":
            appState.hideKeySignatureFromStaff.toggle()
            return nil
        case "1", "2", "3", "4", "5", "6":
            if let raw = Int(chars), let mode = DisplayMode(rawValue: raw) {
                appState.displayMode = mode
                return nil
            }
            return event
        default:
            return event
        }
    }
}
