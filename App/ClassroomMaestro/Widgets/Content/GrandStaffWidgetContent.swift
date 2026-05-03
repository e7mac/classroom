#if os(macOS)
import SwiftUI
import AppCore
import MusicTheory
import MusicRendering

@MainActor
struct GrandStaffWidgetContent: View {
    @ObservedObject var manager: WidgetManager
    @ObservedObject var appState: AppState

    var body: some View {
        WidgetChrome(kind: .grandStaff, manager: manager) { isExpanded in
            StaffView(
                notes: appState.displayedNotes,
                keySignature: appState.keySignature,
                clef: .grand,
                showKeySignature: !appState.hideKeySignatureFromStaff,
                staffSpacing: isExpanded ? 12 : 8
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#endif
