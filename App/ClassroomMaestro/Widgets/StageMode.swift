import Foundation
import AppKit

public struct StageModeSettings: Sendable, Equatable {
    public var enabled: Bool
    public var snapGridSize: CGFloat
    public var hideChrome: Bool

    public init(enabled: Bool = false, snapGridSize: CGFloat = 16, hideChrome: Bool = true) {
        self.enabled = enabled
        self.snapGridSize = snapGridSize
        self.hideChrome = hideChrome
    }
}

extension CGRect {
    /// Snap origin to a multiple of `gridSize`. Size is preserved.
    public func snappedToGrid(_ gridSize: CGFloat) -> CGRect {
        guard gridSize > 0 else { return self }
        let x = (origin.x / gridSize).rounded() * gridSize
        let y = (origin.y / gridSize).rounded() * gridSize
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }
}
