import Foundation
import SwiftUI

public struct WidgetVisualSettings: Codable, Hashable, Sendable {
    public var recordingBorderEnabled: Bool
    public var recordingBorderColorHex: String

    public init(
        recordingBorderEnabled: Bool = false,
        recordingBorderColorHex: String = "#FF3B30"
    ) {
        self.recordingBorderEnabled = recordingBorderEnabled
        self.recordingBorderColorHex = recordingBorderColorHex
    }

    public var recordingBorderColor: Color {
        Color(hex: recordingBorderColorHex) ?? .red
    }
}

extension Color {
    /// Parses #RRGGBB or #RRGGBBAA hex string.
    init?(hex: String) {
        var s = hex.uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard let n = UInt32(s, radix: 16) else { return nil }
        let r, g, b, a: Double
        switch s.count {
        case 6:
            r = Double((n >> 16) & 0xFF) / 255
            g = Double((n >> 8)  & 0xFF) / 255
            b = Double( n        & 0xFF) / 255
            a = 1
        case 8:
            r = Double((n >> 24) & 0xFF) / 255
            g = Double((n >> 16) & 0xFF) / 255
            b = Double((n >> 8)  & 0xFF) / 255
            a = Double( n        & 0xFF) / 255
        default: return nil
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
