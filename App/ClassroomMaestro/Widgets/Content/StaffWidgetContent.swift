import SwiftUI
import AppCore
import MusicTheory
import MusicRendering

@MainActor
struct StaffWidgetContent: View {
    @ObservedObject var manager: WidgetManager
    @ObservedObject var appState: AppState

    var body: some View {
        WidgetChrome(kind: .staff, manager: manager) { isExpanded in
            StaffView(
                notes: appState.displayedNotes,
                keySignature: appState.keySignature,
                clef: .treble,
                showKeySignature: !appState.hideKeySignatureFromStaff,
                staffSpacing: isExpanded ? 14 : 9
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
