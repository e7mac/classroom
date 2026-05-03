import Foundation

public struct ClefSet: Sendable, Hashable {
    public let showsTreble: Bool
    public let showsBass: Bool

    public init(showsTreble: Bool, showsBass: Bool) {
        self.showsTreble = showsTreble
        self.showsBass = showsBass
    }

    public static let trebleOnly = ClefSet(showsTreble: true, showsBass: false)
    public static let bassOnly   = ClefSet(showsTreble: false, showsBass: true)
    public static let grand      = ClefSet(showsTreble: true, showsBass: true)

    public init(clef: StaffLayout.Clef) {
        switch clef {
        case .treble: self.init(showsTreble: true, showsBass: false)
        case .bass:   self.init(showsTreble: false, showsBass: true)
        case .grand:  self.init(showsTreble: true, showsBass: true)
        }
    }
}
