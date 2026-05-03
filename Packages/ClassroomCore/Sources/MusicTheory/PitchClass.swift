import Foundation

public enum PitchClass: Int, CaseIterable, Sendable, Hashable {
    case c = 0, d, e, f, g, a, b

    public var naturalSemitones: Int {
        switch self {
        case .c: return 0
        case .d: return 2
        case .e: return 4
        case .f: return 5
        case .g: return 7
        case .a: return 9
        case .b: return 11
        }
    }

    public var letterName: String {
        switch self {
        case .c: return "C"
        case .d: return "D"
        case .e: return "E"
        case .f: return "F"
        case .g: return "G"
        case .a: return "A"
        case .b: return "B"
        }
    }

    public var nextLetter: PitchClass {
        PitchClass(rawValue: (rawValue + 1) % 7) ?? .c
    }

    public var previousLetter: PitchClass {
        PitchClass(rawValue: (rawValue + 6) % 7) ?? .b
    }
}
