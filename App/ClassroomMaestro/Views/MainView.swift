import SwiftUI
import AppCore
import MusicTheory
import MusicRendering
import AudioInput

struct MainView: View {
    @EnvironmentObject private var container: AppStateContainer
    @EnvironmentObject private var appState: AppState

    @State private var keySignaturePopoverVisible = false
    #if os(macOS)
    @State private var shortcuts: KeyboardShortcutsMonitor?
    #endif

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
            #if os(macOS)
            WidgetDockView(manager: container.widgetManager)
            #endif
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
            .frame(maxWidth: .infinity, minHeight: 280)
            KeyboardView(
                pressedMIDI: appState.activeMIDINotes,
                handPosition: appState.handPosition,
                lowMIDI: 21,
                highMIDI: 108
            )
            .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 160)
            RecentHistoryStrip(appState: appState)
                .frame(maxWidth: .infinity)
            progressionStrip
            Spacer(minLength: 0)
        }
        .padding()
        .onAppear {
            #if os(macOS)
            let monitor = KeyboardShortcutsMonitor(appState: appState)
            monitor.install()
            shortcuts = monitor
            #endif
        }
        .onDisappear {
            #if os(macOS)
            shortcuts?.uninstall()
            container.widgetManager.closeAll()
            #endif
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
            .help(container.midiActive
                  ? "MIDI is on — click to see connected devices"
                  : "MIDI is off")
            .accessibilityLabel("MIDI device list, currently \(container.midiDevices.count) devices")

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
            .help(container.acousticEnabled
                  ? "Microphone on — listening for acoustic piano"
                  : "Turn on microphone for acoustic piano detection")
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
            .font(.system(.body, design: .rounded).weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .accessibilityLabel(chord.symbol)
    }
}

#Preview {
    let container = AppStateContainer()
    return MainView()
        .environmentObject(container)
        .environmentObject(container.appState)
        .frame(width: 900, height: 720)
}

#if os(macOS)
struct WidgetDockView: View {
    @ObservedObject var manager: WidgetManager
    @State private var savePresetVisible = false
    @State private var newPresetName = ""

    var body: some View {
        HStack(spacing: 8) {
            Text("Widgets:")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(WidgetKind.allCases) { kind in
                widgetToggle(kind)
            }
            Divider().frame(height: 22)
            stageModeToggle
            Divider().frame(height: 22)
            presetMenu
            saveLayoutButton
        }
        .padding(.horizontal, 8)
        .alert("Save Layout", isPresented: $savePresetVisible) {
            TextField("Name", text: $newPresetName)
            Button("Save") {
                let name = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty {
                    manager.saveCurrentLayoutAsPreset(name: name)
                }
                newPresetName = ""
            }
            Button("Cancel", role: .cancel) {
                newPresetName = ""
            }
        } message: {
            Text("Capture currently open widgets and their positions.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSaveLayoutDialog)) { _ in
            savePresetVisible = true
        }
    }

    private func widgetToggle(_ kind: WidgetKind) -> some View {
        Toggle(isOn: Binding(
            get: { manager.openWidgets.contains(kind) },
            set: { _ in manager.toggle(kind) }
        )) {
            Image(systemName: kind.sfSymbol)
        }
        .toggleStyle(.button)
        .help(widgetTooltip(kind))
        .accessibilityLabel("\(kind.displayName) widget")
    }

    private func widgetTooltip(_ kind: WidgetKind) -> String {
        let action = manager.openWidgets.contains(kind) ? "Close" : "Open"
        switch kind {
        case .staff:      return "\(action) Staff widget — floating treble staff"
        case .keyboard:   return "\(action) Keyboard widget — floating piano keyboard"
        case .analysis:   return "\(action) Analysis widget — floating chord/Roman label"
        case .grandStaff: return "\(action) Grand Staff widget — floating treble + bass"
        case .combo:      return "\(action) Combo widget — staff stacked above keyboard"
        }
    }

    private var stageModeToggle: some View {
        Toggle(isOn: Binding(
            get: { manager.stageMode.enabled },
            set: { _ in manager.toggleStageMode() }
        )) {
            Image(systemName: "tv")
        }
        .toggleStyle(.button)
        .help(manager.stageMode.enabled
              ? "Exit Stage Mode — restore widget chrome"
              : "Stage Mode — hide chrome, snap to grid, float above all UI (for recording)")
        .accessibilityLabel("Stage Mode")
    }

    private var presetMenu: some View {
        Menu {
            if manager.savedPresets.isEmpty {
                Text("No saved layouts").foregroundStyle(.secondary)
            } else {
                ForEach(manager.savedPresets) { preset in
                    Button(preset.name) { manager.loadPreset(preset) }
                }
                Divider()
                Menu("Delete") {
                    ForEach(manager.savedPresets) { preset in
                        Button(preset.name) { manager.deletePreset(name: preset.name) }
                    }
                }
            }
        } label: {
            Label("Layouts", systemImage: "rectangle.stack")
                .labelStyle(.iconOnly)
        }
        .menuStyle(.borderlessButton)
        .frame(width: 28)
        .help("Load a saved layout preset")
    }

    private var saveLayoutButton: some View {
        Button {
            savePresetVisible = true
        } label: {
            Image(systemName: "plus.rectangle.on.rectangle")
        }
        .buttonStyle(.borderless)
        .help("Save current widget layout as a named preset (⌘⇧S)")
        .accessibilityLabel("Save current layout as preset")
    }
}

extension Notification.Name {
    static let openSaveLayoutDialog = Notification.Name("openSaveLayoutDialog")
}
#endif
