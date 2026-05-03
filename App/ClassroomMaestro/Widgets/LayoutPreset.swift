#if os(macOS)
import Foundation

// `[WidgetKind: WidgetFrame]` is awkward to round-trip via Codable because
// dictionary handling for non-String keys varies across encoders/decoders, so
// the on-disk shape is a sorted array of explicit (kind, frame) entries.
public struct LayoutPreset: Codable, Hashable, Sendable, Identifiable {
    public var id: String { name }
    public let name: String
    public let entries: [Entry]
    public let createdAt: Date

    public struct Entry: Codable, Hashable, Sendable {
        public let kind: WidgetKind
        public let frame: WidgetFrame
    }

    public init(name: String, widgets: [WidgetKind: WidgetFrame], createdAt: Date = Date()) {
        self.name = name
        self.entries = widgets
            .map { Entry(kind: $0.key, frame: $0.value) }
            .sorted { $0.kind.rawValue < $1.kind.rawValue }
        self.createdAt = createdAt
    }

    public var widgets: [WidgetKind: WidgetFrame] {
        Dictionary(uniqueKeysWithValues: entries.map { ($0.kind, $0.frame) })
    }
}

#endif
