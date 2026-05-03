import Foundation

public enum Accidental: Int, Sendable, Hashable, CaseIterable {
    case doubleFlat = -2, flat = -1, natural = 0, sharp = 1, doubleSharp = 2

    public var semitoneOffset: Int { rawValue }

    public var symbol: String {
        switch self {
        case .doubleFlat: return "𝄫"
        case .flat: return "♭"
        case .natural: return "♮"
        case .sharp: return "♯"
        case .doubleSharp: return "𝄪"
        }
    }

    public var displaySymbol: String {
        self == .natural ? "" : symbol
    }
}
