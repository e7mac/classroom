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
        // The local NSEvent callback is documented to run on the main thread, but its
        // type isn't @MainActor-annotated and NSEvent isn't Sendable, so we extract
        // the Sendable bits synchronously and dispatch the handler onto the main actor.
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            let snapshot = EventSnapshot(
                type: event.type,
                modifierFlags: event.modifierFlags,
                charactersIgnoringModifiers: event.charactersIgnoringModifiers
            )
            let consumed = MainActor.assumeIsolated {
                self?.handle(snapshot) ?? false
            }
            return consumed ? nil : event
        }
    }

    func uninstall() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    private struct EventSnapshot: Sendable {
        let type: NSEvent.EventType
        let modifierFlags: NSEvent.ModifierFlags
        let charactersIgnoringModifiers: String?
    }

    /// Returns true if the event should be consumed (not forwarded to the system).
    private func handle(_ event: EventSnapshot) -> Bool {
        guard let appState else { return false }

        if event.type == .flagsChanged {
            let capsOn = event.modifierFlags.contains(.capsLock)
            if capsOn != lastCapsLockState {
                lastCapsLockState = capsOn
                appState.toggleCapsLockFreeze()
            }
            return false
        }

        // Pure single-letter shortcuts only — defer to system on any modifier.
        let modifiers = event.modifierFlags.intersection([.command, .control, .option])
        guard modifiers.isEmpty else { return false }

        guard let chars = event.charactersIgnoringModifiers?.lowercased() else { return false }
        switch chars {
        case "a":
            appState.analysisOverlayVisible.toggle()
            return true
        case "e":
            appState.cycleEnharmonic()
            return true
        case "k":
            switch appState.clefMode {
            case .treble: appState.clefMode = .grand
            case .grand:  appState.clefMode = .bass
            case .bass:   appState.clefMode = .treble
            }
            return true
        case "s":
            appState.hideKeySignatureFromStaff.toggle()
            return true
        case "1", "2", "3", "4", "5", "6":
            if let raw = Int(chars), let mode = DisplayMode(rawValue: raw) {
                appState.displayMode = mode
                return true
            }
            return false
        default:
            return false
        }
    }
}
