import SwiftUI
import AppCore
import MusicTheory
import MusicRendering
import AudioInput

struct MainView: View {
    @EnvironmentObject private var container: AppStateContainer
    @EnvironmentObject private var appState: AppState

    @State private var keySignaturePopoverVisible = false
    @State private var shortcuts: KeyboardShortcutsMonitor?

    var body: some View {
        VStack(spacing: 12) {
            topBar
            ToolPaletteView(
                displayMode: $appState.displayMode,
                keySignature: $appState.keySignature,
                clefMode: $appState.clefMode,
                analysisDisplayMode: $appState.analysisDisplayMode,
                analysisOverlayVisible: $appState.analysisOverlayVisible,
                hideKeySignatureFromStaff: $appState.hideKeySignatureFromStaff,
                freeze: appState.freeze,
                onCycleEnharmonic: { appState.cycleEnharmonic() },
                onClearProgression: { appState.clearProgression() }
            )
            WidgetDockView(manager: container.widgetManager)
            AnalysisOverlayView(
                analysis: appState.lastAnalysis,
                displayMode: appState.analysisDisplayMode,
                isVisible: appState.analysisOverlayVisible
            )
            StaffView(
                notes: appState.displayedNotes,
                keySignature: appState.keySignature,
                clef: appState.clefMode,
                showKeySignature: !appState.hideKeySignatureFromStaff
            )
            .frame(maxWidth: 720, minHeight: 280)
            KeyboardView(
                pressedMIDI: appState.activeMIDINotes,
                handPosition: appState.handPosition,
                lowMIDI: 48,
                highMIDI: 84
            )
            .frame(maxWidth: 720, minHeight: 100, maxHeight: 120)
            progressionStrip
            Spacer(minLength: 0)
        }
        .padding()
        .onAppear {
            let monitor = KeyboardShortcutsMonitor(appState: appState)
            monitor.install()
            shortcuts = monitor
        }
        .onDisappear {
            shortcuts?.uninstall()
            container.widgetManager.closeAll()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openKeySignaturePicker)) { _ in
            keySignaturePopoverVisible = true
        }
        .popover(isPresented: $keySignaturePopoverVisible) {
            KeySignaturePicker(selection: $appState.keySignature) {
                keySignaturePopoverVisible = false
            }
            .padding()
        }
        .alert(
            "Startup Error",
            isPresented: Binding(
                get: { container.startupError != nil },
                set: { if !$0 { container.startupError = nil } }
            ),
            actions: {
                Button("OK") { container.startupError = nil }
            },
            message: {
                Text(container.startupError ?? "")
            }
        )
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Text("ClassroomMaestro")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            Spacer()
            inputSourceControls
            Spacer()
            statusIndicator
        }
        .padding(.horizontal, 8)
    }

    private var inputSourceControls: some View {
        HStack(spacing: 8) {
            Menu {
                if container.midiDevices.isEmpty {
                    Text("No MIDI devices detected").foregroundStyle(.secondary)
                } else {
                    ForEach(container.midiDevices, id: \.id) { device in
                        Text(device.name)
                    }
                }
                Divider()
                Button("Refresh") {
                    Task { await container.refreshDevices() }
                }
            } label: {
                Label(container.midiActive ? "MIDI On" : "MIDI Off",
                      systemImage: "pianokeys")
            }
            .help("Connected MIDI devices")

            Toggle(isOn: Binding(
                get: { container.acousticEnabled },
                set: { newValue in
                    Task {
                        if newValue {
                            await container.startAcoustic()
                        } else {
                            await container.stopAcoustic()
                        }
                    }
                }
            )) {
                Label("Mic", systemImage: "mic")
            }
            .toggleStyle(.button)
            .help("Toggle acoustic piano detection (microphone)")
        }
    }

    private var statusIndicator: some View {
        HStack(spacing: 8) {
            if container.acousticEnabled {
                inputLevelMeter
            }
            if appState.freeze.isFrozen {
                Image(systemName: "snowflake")
                    .foregroundStyle(.blue)
                    .accessibilityLabel("Frozen")
            }
        }
        .frame(minWidth: 80)
    }

    private var inputLevelMeter: some View {
        GeometryReader { proxy in
            let level = max(0, min(1, container.inputLevel))
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.2))
                Capsule()
                    .fill(level > 0.7 ? Color.red : Color.green)
                    .frame(width: proxy.size.width * CGFloat(level))
                    .animation(.easeOut(duration: 0.05), value: level)
            }
        }
        .frame(width: 60, height: 6)
        .accessibilityLabel("Microphone input level")
    }

    private var progressionStrip: some View {
        Group {
            if appState.displayMode == .chordProgression && !appState.progression.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(appState.progression.enumerated()), id: \.offset) { _, chord in
                            chordChip(chord)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(height: 36)
            } else {
                EmptyView()
            }
        }
    }

    private func chordChip(_ chord: Chord) -> some View {
        Text(chord.symbol)
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.regularMaterial)
            .clipShape(Capsule())
    }
}

#Preview {
    let container = AppStateContainer()
    return MainView()
        .environmentObject(container)
        .environmentObject(container.appState)
        .frame(width: 900, height: 720)
}

struct WidgetDockView: View {
    @ObservedObject var manager: WidgetManager

    var body: some View {
        HStack(spacing: 8) {
            Text("Widgets:")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(WidgetKind.allCases) { kind in
                Toggle(isOn: Binding(
                    get: { manager.openWidgets.contains(kind) },
                    set: { _ in manager.toggle(kind) }
                )) {
                    Image(systemName: kind.sfSymbol)
                }
                .toggleStyle(.button)
                .help(kind.displayName)
                .accessibilityLabel("\(kind.displayName) widget")
            }
        }
        .padding(.horizontal, 8)
    }
}
