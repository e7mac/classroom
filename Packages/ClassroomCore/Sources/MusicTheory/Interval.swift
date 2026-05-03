import Foundation

public struct Interval: Hashable, Sendable {
    public enum Quality: Sendable, Hashable {
        case perfect, major, minor, augmented, diminished, doubleAugmented, doubleDiminished
    }

    public let number: Int
    public let quality: Quality
    public let semitones: Int

    public init(from low: Note, to high: Note) {
        let (lower, upper) = low.midiNumber <= high.midiNumber ? (low, high) : (high, low)

        let letterSteps = (upper.pitchClass.rawValue - lower.pitchClass.rawValue + 7) % 7
        let octaveDifference = upper.octave - lower.octave
        let lowerCrossesOctave = upper.pitchClass.rawValue < lower.pitchClass.rawValue
        let octaveSpans = lowerCrossesOctave ? max(0, octaveDifference - 1) : octaveDifference

        let number = letterSteps + 1 + 7 * octaveSpans
        let semitones = upper.midiNumber - lower.midiNumber

        self.number = number
        self.semitones = semitones
        self.quality = Self.quality(forNumber: number, semitones: semitones)
    }

    public var shortName: String {
        let prefix: String
        switch quality {
        case .perfect: prefix = "P"
        case .major: prefix = "M"
        case .minor: prefix = "m"
        case .augmented: prefix = "A"
        case .diminished: prefix = "d"
        case .doubleAugmented: prefix = "AA"
        case .doubleDiminished: prefix = "dd"
        }
        return "\(prefix)\(number)"
    }

    private static func quality(forNumber number: Int, semitones: Int) -> Quality {
        let simpleNumber = ((number - 1) % 7) + 1
        let octaves = (number - 1) / 7
        let simpleSemitones = semitones - 12 * octaves

        let perfectFamily: Set<Int> = [1, 4, 5]
        let perfectBase: [Int: Int] = [1: 0, 4: 5, 5: 7]
        let majorBase: [Int: Int] = [2: 2, 3: 4, 6: 9, 7: 11]

        if simpleNumber == 1 && octaves > 0 {
            // Octave-family (8, 15, ...) treated as perfect with base 12 per octave.
            let delta = semitones - 12 * octaves
            return perfectQuality(delta: delta)
        }

        if perfectFamily.contains(simpleNumber) {
            let delta = simpleSemitones - (perfectBase[simpleNumber] ?? 0)
            return perfectQuality(delta: delta)
        }

        let delta = simpleSemitones - (majorBase[simpleNumber] ?? 0)
        return majorMinorQuality(delta: delta)
    }

    private static func perfectQuality(delta: Int) -> Quality {
        switch delta {
        case 0: return .perfect
        case 1: return .augmented
        case 2: return .doubleAugmented
        case -1: return .diminished
        case -2: return .doubleDiminished
        default: return delta > 0 ? .doubleAugmented : .doubleDiminished
        }
    }

    private static func majorMinorQuality(delta: Int) -> Quality {
        switch delta {
        case 0: return .major
        case -1: return .minor
        case -2: return .diminished
        case -3: return .doubleDiminished
        case 1: return .augmented
        case 2: return .doubleAugmented
        default: return delta > 0 ? .doubleAugmented : .doubleDiminished
        }
    }
}
