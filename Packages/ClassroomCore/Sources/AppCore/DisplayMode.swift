public enum DisplayMode: Int, CaseIterable, Sendable, Hashable {
    case singleNote = 1
    case interval = 2
    case chord = 3
    case scale = 4
    case chordProgression = 5
    case handPosition = 6

    public var maxConcurrentNotes: Int {
        switch self {
        case .singleNote:        return 1
        case .interval:          return 2
        case .chord:             return 4
        case .scale:             return 8
        case .chordProgression:  return 4
        case .handPosition:      return 5
        }
    }

    public var displayName: String {
        switch self {
        case .singleNote:        return "Single Note"
        case .interval:          return "Interval"
        case .chord:             return "Chord"
        case .scale:             return "Scale"
        case .chordProgression:  return "Chord Progression"
        case .handPosition:      return "Hand Position"
        }
    }
}
