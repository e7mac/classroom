import SwiftUI
import AppCore
import MusicTheory
import MusicRendering

@MainActor
struct KeyboardWidgetContent: View {
    @ObservedObject var manager: WidgetManager
    @ObservedObject var appState: AppState

    var body: some View {
        WidgetChrome(kind: .keyboard, manager: manager) { isExpanded in
            KeyboardView(
                pressedMIDI: appState.activeMIDINotes,
                handPosition: appState.handPosition,
                lowMIDI: isExpanded ? 36 : 48,
                highMIDI: isExpanded ? 96 : 84
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
