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
                lowMIDI: 21,
                highMIDI: 108
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
