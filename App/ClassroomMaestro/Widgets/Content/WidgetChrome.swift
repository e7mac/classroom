import SwiftUI
import AppKit
import AppCore

@MainActor
struct WidgetChrome<Content: View>: View {
    let kind: WidgetKind
    @ObservedObject var manager: WidgetManager
    @ViewBuilder let content: (Bool) -> Content

    @State private var isExpanded = false
    @State private var isHovering = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var stageModeActive: Bool {
        manager.stageMode.enabled && manager.stageMode.hideChrome
    }

    private var settings: WidgetVisualSettings {
        manager.visualSettings[kind] ?? WidgetVisualSettings()
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if !stageModeActive {
                VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
            }

            content(isExpanded)
                .padding(stageModeActive ? 0 : 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !stageModeActive && isHovering {
                controlBar
                    .padding(6)
                    .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: stageModeActive ? 0 : 12))
        .overlay {
            if settings.recordingBorderEnabled {
                Rectangle()
                    .strokeBorder(settings.recordingBorderColor, lineWidth: 4)
                    .allowsHitTesting(false)
            }
        }
        .onHover { isHovering = $0 }
        .onTapGesture(count: 2) {
            if reduceMotion {
                isExpanded.toggle()
            } else {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isExpanded.toggle()
                }
            }
        }
        .animation(.reduceMotionAware(.easeInOut(duration: 0.12), reduceMotion: reduceMotion), value: isHovering)
    }

    private var controlBar: some View {
        HStack(spacing: 6) {
            opacitySlider
            clickThroughToggle
            recordingBorderControls
            closeButton
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }

    private var opacitySlider: some View {
        Slider(
            value: Binding(
                get: { manager.opacity(for: kind) },
                set: { manager.setOpacity($0, for: kind) }
            ),
            in: 0.5...1.0
        )
        .controlSize(.mini)
        .frame(width: 80)
        .help("Opacity (50%–100%) — make widget translucent over slides")
    }

    private var clickThroughToggle: some View {
        Button {
            manager.setClickThrough(!manager.clickThrough(for: kind), for: kind)
        } label: {
            Image(systemName: manager.clickThrough(for: kind) ? "cursorarrow.slash" : "cursorarrow")
        }
        .buttonStyle(.borderless)
        .help(manager.clickThrough(for: kind)
              ? "Click-through ON — clicks pass through to apps below; click again to interact"
              : "Click-through OFF — click to make this widget pass mouse events to the app below")
    }

    private var recordingBorderControls: some View {
        HStack(spacing: 4) {
            Toggle(isOn: Binding(
                get: { settings.recordingBorderEnabled },
                set: { manager.setRecordingBorderEnabled($0, for: kind) }
            )) {
                Image(systemName: settings.recordingBorderEnabled
                      ? "rectangle.dashed.badge.record"
                      : "rectangle.dashed")
            }
            .toggleStyle(.button)
            .help(settings.recordingBorderEnabled
                  ? "Recording border ON — colored outline for cropping in OBS/screen recording"
                  : "Show colored border around this widget — useful as a crop guide for screen recording")

            if settings.recordingBorderEnabled {
                Menu {
                    ForEach(borderColorChoices, id: \.0) { name, hex in
                        Button(name) { manager.setRecordingBorderColor(hex, for: kind) }
                    }
                } label: {
                    Circle()
                        .fill(settings.recordingBorderColor)
                        .overlay(Circle().strokeBorder(.secondary, lineWidth: 0.5))
                        .frame(width: 14, height: 14)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 22)
                .help("Choose border color")
            }
        }
    }

    private var closeButton: some View {
        Button {
            manager.close(kind)
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .help("Close this widget")
    }

    private var borderColorChoices: [(String, String)] {
        [
            ("Red",    "#FF3B30"),
            ("Orange", "#FF9500"),
            ("Yellow", "#FFCC00"),
            ("Green",  "#34C759"),
            ("Blue",   "#0A84FF"),
            ("Purple", "#AF52DE"),
            ("White",  "#FFFFFF"),
            ("Black",  "#000000"),
        ]
    }
}

struct VisualEffectBackground: NSViewRepresentable {
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
