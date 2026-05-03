import AppKit
import SwiftUI
import Combine

@MainActor
final class WidgetWindowController {
    let kind: WidgetKind
    let panel: FloatingPanel

    private var positionSaveTask: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []

    var onFrameChange: ((CGRect) -> Void)?
    var onClose: (() -> Void)?
    var onOpacityChange: ((Double) -> Void)?
    var onClickThroughChange: ((Bool) -> Void)?

    private(set) var opacity: Double {
        didSet {
            panel.alphaValue = CGFloat(opacity)
            onOpacityChange?(opacity)
        }
    }

    private(set) var clickThrough: Bool {
        didSet {
            panel.ignoresMouseEvents = clickThrough
            onClickThroughChange?(clickThrough)
        }
    }

    init<Content: View>(
        kind: WidgetKind,
        initialFrame: WidgetFrame,
        @ViewBuilder content: () -> Content
    ) {
        self.kind = kind
        self.opacity = initialFrame.opacity
        self.clickThrough = initialFrame.clickThrough

        let rect = NSRect(
            x: initialFrame.x,
            y: initialFrame.y,
            width: max(initialFrame.width, kind.minSize.width),
            height: max(initialFrame.height, kind.minSize.height)
        )
        self.panel = FloatingPanel(contentRect: rect)
        self.panel.contentMinSize = NSSize(width: kind.minSize.width, height: kind.minSize.height)
        self.panel.alphaValue = CGFloat(initialFrame.opacity)
        self.panel.ignoresMouseEvents = initialFrame.clickThrough

        let host = NSHostingView(rootView: AnyView(content()))
        host.frame = NSRect(origin: .zero, size: rect.size)
        host.autoresizingMask = [.width, .height]
        self.panel.contentView = host

        installObservers()
    }

    private func installObservers() {
        let nc = NotificationCenter.default
        // Notification callbacks are delivered on the main queue but are not
        // MainActor-isolated by the type system. assumeIsolated bridges them.
        observers.append(nc.addObserver(forName: NSWindow.didMoveNotification, object: panel, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.scheduleFrameSave()
            }
        })
        observers.append(nc.addObserver(forName: NSWindow.didResizeNotification, object: panel, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.scheduleFrameSave()
            }
        })
        observers.append(nc.addObserver(forName: NSWindow.willCloseNotification, object: panel, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.onClose?()
                self.removeObservers()
            }
        })
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func close() {
        // Observers are removed by handlePanelWillClose (triggered by panel.close()),
        // so the willClose callback still fires before they're torn down.
        panel.close()
    }

    private func removeObservers() {
        let nc = NotificationCenter.default
        for obs in observers { nc.removeObserver(obs) }
        observers.removeAll()
    }

    func setOpacity(_ value: Double) {
        opacity = max(0.5, min(1.0, value))
    }

    func setClickThrough(_ enabled: Bool) {
        clickThrough = enabled
    }

    func applyStageMode(_ settings: StageModeSettings) {
        if settings.enabled {
            // `.screenSaver + 1` floats above macOS notification banners and the menu bar
            // so a teacher's widgets stay visible during a class even when alerts arrive.
            panel.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
            panel.hasShadow = false
        } else {
            panel.level = .floating
            panel.hasShadow = true
        }
        panel.invalidateShadow()
    }

    private func scheduleFrameSave() {
        positionSaveTask?.cancel()
        positionSaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard let self else { return }
            self.onFrameChange?(self.panel.frame)
        }
    }

    deinit {
        // Observers are removed in close() (called before the controller is released
        // by WidgetManager). Touching @MainActor-isolated state from a non-isolated
        // deinit isn't allowed under Swift 6 strict concurrency anyway.
    }
}
