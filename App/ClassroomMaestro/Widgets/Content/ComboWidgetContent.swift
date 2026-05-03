import SwiftUI
import AppCore
import MusicTheory
import MusicRendering

@MainActor
struct ComboWidgetContent: View {
    @ObservedObject var manager: WidgetManager
    @ObservedObject var appState: AppState

    var body: some View {
        WidgetChrome(kind: .combo, manager: manager) { isExpanded in
            VStack(spacing: 8) {
                StaffView(
                    notes: appState.displayedNotes,
                    keySignature: appState.keySignature,
                    clef: .grand,
                    showKeySignature: !appState.hideKeySignatureFromStaff,
                    staffSpacing: isExpanded ? 11 : 7
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                KeyboardView(
                    pressedMIDI: appState.activeMIDINotes,
                    handPosition: appState.handPosition,
                    lowMIDI: 48,
                    highMIDI: 84
                )
                .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 90)
            }
        }
    }
}
