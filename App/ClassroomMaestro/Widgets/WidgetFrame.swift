#if os(macOS)
import Foundation
import CoreGraphics

public struct WidgetFrame: Codable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var opacity: Double
    public var clickThrough: Bool

    public init(rect: CGRect, opacity: Double = 1.0, clickThrough: Bool = false) {
        self.x = Double(rect.origin.x)
        self.y = Double(rect.origin.y)
        self.width = Double(rect.size.width)
        self.height = Double(rect.size.height)
        self.opacity = opacity
        self.clickThrough = clickThrough
    }

    public var rect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

#endif
