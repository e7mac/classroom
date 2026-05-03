import SwiftUI

extension Animation {
    /// Returns the given animation, or `nil` if the user has Reduce Motion enabled.
    /// Use with `.animation(_:value:)`: nil disables animation entirely.
    static func reduceMotionAware(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}
