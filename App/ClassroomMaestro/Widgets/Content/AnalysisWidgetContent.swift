import SwiftUI
import AppCore

@MainActor
struct AnalysisWidgetContent: View {
    @ObservedObject var manager: WidgetManager
    @ObservedObject var appState: AppState

    var body: some View {
        WidgetChrome(kind: .analysis, manager: manager) { isExpanded in
            AnalysisOverlayView(
                analysis: appState.lastAnalysis,
                displayMode: appState.analysisDisplayMode,
                isVisible: appState.analysisOverlayVisible
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(isExpanded ? 1.3 : 1.0)
            .animation(.easeInOut(duration: 0.18), value: isExpanded)
        }
    }
}
