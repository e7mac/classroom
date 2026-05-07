#if os(macOS)
import SwiftUI
import AppKit
import Combine
import AppCore

@MainActor
final class WidgetManager: ObservableObject {
    @Published private(set) var openWidgets: Set<WidgetKind> = []
    @Published var stageMode = StageModeSettings()
    @Published private(set) var savedPresets: [LayoutPreset] = []
    @Published private(set) var visualSettings: [WidgetKind: WidgetVisualSettings] = [:]

    private let appState: AppState
    private var controllers: [WidgetKind: WidgetWindowController] = [:]
    private let defaults: UserDefaults

    init(appState: AppState, defaults: UserDefaults = .standard) {
        self.appState = appState
        self.defaults = defaults
        loadPresets()
        loadVisualSettings()
    }

    // MARK: - Open / close

    func toggle(_ kind: WidgetKind) {
        if openWidgets.contains(kind) {
            close(kind)
        } else {
            open(kind)
        }
    }

    func open(_ kind: WidgetKind) {
        guard controllers[kind] == nil else { return }
        let frame = loadFrame(for: kind) ?? defaultFrame(for: kind)
        let appState = self.appState
        let manager = self
        let controller = WidgetWindowController(kind: kind, initialFrame: frame) {
            widgetContent(for: kind, manager: manager, appState: appState)
        }
        controller.onFrameChange = { [weak self] rect in
            guard let self else { return }
            var f = self.loadFrame(for: kind) ?? frame
            f.x = Double(rect.origin.x)
            f.y = Double(rect.origin.y)
            f.width = Double(rect.size.width)
            f.height = Double(rect.size.height)
            self.saveFrame(f, for: kind)
        }
        controller.onOpacityChange = { [weak self] value in
            guard let self else { return }
            var f = self.loadFrame(for: kind) ?? frame
            f.opacity = value
            self.saveFrame(f, for: kind)
        }
        controller.onClickThroughChange = { [weak self] enabled in
            guard let self else { return }
            var f = self.loadFrame(for: kind) ?? frame
            f.clickThrough = enabled
            self.saveFrame(f, for: kind)
        }
        controller.onClose = { [weak self] in
            self?.handlePanelClosed(kind: kind)
        }
        controllers[kind] = controller
        controller.applyStageMode(stageMode)
        controller.show()
        openWidgets.insert(kind)
        saveFrame(frame, for: kind)
        saveOpenSet()
    }

    func close(_ kind: WidgetKind) {
        controllers[kind]?.close()
    }

    func closeAll() {
        for kind in Array(openWidgets) {
            close(kind)
        }
    }

    private func handlePanelClosed(kind: WidgetKind) {
        controllers.removeValue(forKey: kind)
        openWidgets.remove(kind)
        saveOpenSet()
    }

    // MARK: - Configuration

    func setOpacity(_ value: Double, for kind: WidgetKind) {
        controllers[kind]?.setOpacity(value)
    }

    func setClickThrough(_ enabled: Bool, for kind: WidgetKind) {
        controllers[kind]?.setClickThrough(enabled)
    }

    func opacity(for kind: WidgetKind) -> Double {
        controllers[kind].map { $0.opacity } ?? loadFrame(for: kind)?.opacity ?? 1.0
    }

    func clickThrough(for kind: WidgetKind) -> Bool {
        controllers[kind].map { $0.clickThrough } ?? loadFrame(for: kind)?.clickThrough ?? false
    }

    // MARK: - Stage Mode

    func toggleStageMode() {
        stageMode.enabled.toggle()
        applyStageModeToAllControllers()
    }

    private func applyStageModeToAllControllers() {
        for (kind, controller) in controllers {
            controller.applyStageMode(stageMode)
            if stageMode.enabled {
                let snapped = controller.panel.frame.snappedToGrid(stageMode.snapGridSize)
                controller.panel.setFrame(snapped, display: true, animate: true)
                if var f = loadFrame(for: kind) {
                    f.x = Double(snapped.origin.x)
                    f.y = Double(snapped.origin.y)
                    saveFrame(f, for: kind)
                }
            }
        }
    }

    // MARK: - Recording border / visual settings

    func setRecordingBorderEnabled(_ enabled: Bool, for kind: WidgetKind) {
        var s = visualSettings[kind] ?? WidgetVisualSettings()
        s.recordingBorderEnabled = enabled
        visualSettings[kind] = s
        saveVisualSettings()
    }

    func setRecordingBorderColor(_ hex: String, for kind: WidgetKind) {
        var s = visualSettings[kind] ?? WidgetVisualSettings()
        s.recordingBorderColorHex = hex
        visualSettings[kind] = s
        saveVisualSettings()
    }

    func visualSettings(for kind: WidgetKind) -> WidgetVisualSettings {
        visualSettings[kind] ?? WidgetVisualSettings()
    }

    private func loadVisualSettings() {
        guard let data = defaults.data(forKey: visualSettingsKey),
              let raw = try? JSONDecoder().decode([String: WidgetVisualSettings].self, from: data)
        else { return }
        var loaded: [WidgetKind: WidgetVisualSettings] = [:]
        for (key, value) in raw {
            if let kind = WidgetKind(rawValue: key) {
                loaded[kind] = value
            }
        }
        visualSettings = loaded
    }

    private func saveVisualSettings() {
        let raw = Dictionary(uniqueKeysWithValues: visualSettings.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(raw) {
            defaults.set(data, forKey: visualSettingsKey)
        }
    }

    // MARK: - Layout Presets

    func saveCurrentLayoutAsPreset(name: String) {
        var widgets: [WidgetKind: WidgetFrame] = [:]
        for kind in openWidgets {
            if let frame = loadFrame(for: kind) {
                widgets[kind] = frame
            }
        }
        let preset = LayoutPreset(name: name, widgets: widgets)
        savedPresets.removeAll { $0.name == name }
        savedPresets.append(preset)
        savedPresets.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        savePresets()
    }

    func deletePreset(name: String) {
        savedPresets.removeAll { $0.name == name }
        savePresets()
    }

    func loadPreset(_ preset: LayoutPreset) {
        let presetKinds = Set(preset.widgets.keys)
        for kind in openWidgets where !presetKinds.contains(kind) {
            close(kind)
        }
        for (kind, frame) in preset.widgets {
            let safeFrame = ensureOnVisibleScreen(frame, for: kind)
            saveFrame(safeFrame, for: kind)
            if openWidgets.contains(kind), let controller = controllers[kind] {
                controller.panel.setFrame(safeFrame.rect, display: true, animate: true)
            } else {
                open(kind)
            }
        }
    }

    private func loadPresets() {
        guard let data = defaults.data(forKey: presetsKey) else { return }
        if let presets = try? JSONDecoder().decode([LayoutPreset].self, from: data) {
            savedPresets = presets
        }
    }

    private func savePresets() {
        if let data = try? JSONEncoder().encode(savedPresets) {
            defaults.set(data, forKey: presetsKey)
        }
    }

    // MARK: - Restore on app launch

    func restorePreviouslyOpenWidgets() {
        guard let data = defaults.data(forKey: openSetKey),
              let kinds = try? JSONDecoder().decode([WidgetKind].self, from: data)
        else { return }
        for kind in kinds {
            open(kind)
        }
    }

    // MARK: - Persistence

    private let openSetKey = "widget.openSet"
    private let presetsKey = "widget.presets"
    private let visualSettingsKey = "widget.visualSettings"

    private func frameKey(for kind: WidgetKind) -> String {
        "widget.frame.\(kind.rawValue)"
    }

    private func loadFrame(for kind: WidgetKind) -> WidgetFrame? {
        guard let data = defaults.data(forKey: frameKey(for: kind)),
              let f = try? JSONDecoder().decode(WidgetFrame.self, from: data)
        else { return nil }
        return ensureOnVisibleScreen(f, for: kind)
    }

    private func saveFrame(_ frame: WidgetFrame, for kind: WidgetKind) {
        guard let data = try? JSONEncoder().encode(frame) else { return }
        defaults.set(data, forKey: frameKey(for: kind))
    }

    private func saveOpenSet() {
        let arr = Array(openWidgets)
        guard let data = try? JSONEncoder().encode(arr) else { return }
        defaults.set(data, forKey: openSetKey)
    }

    /// Multi-monitor safety: if a saved frame is on a screen that's no longer
    /// attached, snap it to the primary screen. (M0 product decision, 2026-05-03.)
    private func ensureOnVisibleScreen(_ frame: WidgetFrame, for kind: WidgetKind) -> WidgetFrame {
        let isVisible = NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(frame.rect)
        }
        if isVisible { return frame }
        var snapped = frame
        if let primary = NSScreen.main {
            snapped.x = primary.visibleFrame.midX - frame.width / 2
            snapped.y = primary.visibleFrame.midY - frame.height / 2
        }
        return snapped
    }

    private func defaultFrame(for kind: WidgetKind) -> WidgetFrame {
        let size = kind.defaultSize
        let primary = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
        let x = primary.midX - size.width / 2
        let y = primary.midY - size.height / 2
        return WidgetFrame(rect: CGRect(x: x, y: y, width: size.width, height: size.height))
    }
}

// Free function so the @ViewBuilder switch returns an opaque `some View`
// without needing `AnyView` erasure inside WidgetManager.
@ViewBuilder
@MainActor
private func widgetContent(
    for kind: WidgetKind,
    manager: WidgetManager,
    appState: AppState
) -> some View {
    switch kind {
    case .staff:
        StaffWidgetContent(manager: manager, appState: appState)
    case .grandStaff:
        GrandStaffWidgetContent(manager: manager, appState: appState)
    case .keyboard:
        KeyboardWidgetContent(manager: manager, appState: appState)
    case .analysis:
        AnalysisWidgetContent(manager: manager, appState: appState)
    case .combo:
        ComboWidgetContent(manager: manager, appState: appState)
    }
}

#endif
