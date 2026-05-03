import SwiftUI
import AppCore

/// Auto-fading strip showing the most recently played notes/chords/intervals/scales.
/// Each chip starts opaque on appearance and fades to transparent over `lifetime` seconds.
/// TimelineView drives smooth per-frame opacity without needing per-chip timer state.
struct RecentHistoryStrip: View {
    @ObservedObject var appState: AppState

    /// How long each chip stays visible before fully fading.
    var lifetime: TimeInterval = 4

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { context in
            let now = context.date
            let visible = appState.recentHistory
                .map { entry -> (HistoryEntry, Double) in
                    let age = now.timeIntervalSince(entry.timestamp)
                    let remaining = max(0, 1 - age / lifetime)
                    return (entry, remaining)
                }
                .filter { $0.1 > 0 }

            HStack(spacing: 8) {
                if visible.isEmpty {
                    Text("Recent")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                ForEach(visible.map(\.0)) { entry in
                    let opacity = visible.first(where: { $0.0.id == entry.id })?.1 ?? 0
                    chip(entry.label)
                        .opacity(opacity)
                }
            }
            .frame(height: 28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
        }
    }

    private func chip(_ label: String) -> some View {
        Text(label)
            .font(.system(.callout, design: .rounded).weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .accessibilityLabel(label)
    }
}
