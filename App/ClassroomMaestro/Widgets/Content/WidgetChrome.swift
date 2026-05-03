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

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)

            content(isExpanded)
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isHovering {
                controlBar
                    .padding(6)
                    .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onHover { isHovering = $0 }
        .onTapGesture(count: 2) {
            withAnimation(.easeInOut(duration: 0.18)) {
                isExpanded.toggle()
            }
        }
        .animation(.easeInOut(duration: 0.12), value: isHovering)
    }

    private var controlBar: some View {
        HStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { manager.opacity(for: kind) },
                    set: { manager.setOpacity($0, for: kind) }
                ),
                in: 0.5...1.0
            )
            .controlSize(.mini)
            .frame(width: 80)
            .help("Opacity")

            Button {
                manager.setClickThrough(!manager.clickThrough(for: kind), for: kind)
            } label: {
                Image(systemName: manager.clickThrough(for: kind) ? "cursorarrow.slash" : "cursorarrow")
            }
            .buttonStyle(.borderless)
            .help("Click-through")

            Button {
                manager.close(kind)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Close")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.thinMaterial)
        .clipShape(Capsule())
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
