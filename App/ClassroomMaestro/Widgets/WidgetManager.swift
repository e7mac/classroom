import SwiftUI
import AppKit
import Combine
import AppCore

@MainActor
final class WidgetManager: ObservableObject {
    @Published private(set) var openWidgets: Set<WidgetKind> = []

    private let appState: AppState
    private var controllers: [WidgetKind: WidgetWindowController] = [:]
    private let defaults: UserDefaults

    init(appState: AppState, defaults: UserDefaults = .standard) {
        self.appState = appState
        self.defaults = defaults
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
        let controller = WidgetWindowController(kind: kind, initialFrame: frame) {
            WidgetPlaceholderView(kind: kind)
                .environmentObject(appState)
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

// MARK: - Placeholder content (M12 stub; real widget views land in M13)

private struct WidgetPlaceholderView: View {
    let kind: WidgetKind
    @State private var opacity: Double = 1.0
    @State private var clickThrough: Bool = false
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: kind.sfSymbol)
                    Text(kind.displayName)
                        .font(.headline)
                    Spacer()
                }
                Spacer()
                Text("\(kind.displayName)Widget — coming in M13")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                Spacer()
                widgetControls
            }
            .padding(10)
        }
    }

    // M12 STUB: this slider visually adjusts the panel via its bound state but
    // does NOT call WidgetManager.setOpacity, so opacity changes do not persist
    // across app launches. The proper wiring (slider -> WidgetManager) lands in
    // M13 when each widget gets a real content view that can receive the
    // WidgetManager via @EnvironmentObject.
    private var widgetControls: some View {
        HStack(spacing: 8) {
            Slider(value: $opacity, in: 0.5...1.0)
                .frame(width: 100)
                .help("Opacity (stub – will persist in M13)")
            Toggle(isOn: $clickThrough) {
                Image(systemName: clickThrough ? "cursorarrow.slash" : "cursorarrow")
            }
            .toggleStyle(.button)
            .help("Click-through (stub – will persist in M13)")
        }
    }
}

private struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
