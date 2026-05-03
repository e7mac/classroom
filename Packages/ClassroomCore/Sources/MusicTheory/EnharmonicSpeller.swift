import Foundation

public struct EnharmonicSpeller: Sendable {
    public init() {}

    public func alternatives(for note: Note, includeDoubles: Bool = false) -> [Note] {
        let target = note.midiNumber
        let inputLetter = note.pitchClass

        var candidates: [Note] = []

        for letter in PitchClass.allCases {
            let baseSemitone = letter.naturalSemitones
            // Try every accidental in -2...+2; pick the one whose written semitone aligns to target mod 12.
            for accRaw in -2...2 {
                guard let accidental = Accidental(rawValue: accRaw) else { continue }
                if !includeDoubles && (accidental == .doubleFlat || accidental == .doubleSharp) {
                    continue
                }

                let writtenSemitone = baseSemitone + accidental.semitoneOffset
                // Determine octave so candidate.midiNumber == target.
                // candidate.midiNumber = 12*(octave+1) + writtenSemitone
                // octave = (target - writtenSemitone) / 12 (must divide evenly)
                let raw = target - writtenSemitone
                guard raw % 12 == 0 else { continue }
                let octave = raw / 12 - 1

                let candidate = Note(pitchClass: letter, accidental: accidental, octave: octave)
                if candidate.midiNumber != target { continue }
                if candidate == note { continue }
                candidates.append(candidate)
            }
        }

        return candidates.sorted { lhs, rhs in
            let lhsTier = naturalnessTier(lhs.accidental)
            let rhsTier = naturalnessTier(rhs.accidental)
            if lhsTier != rhsTier { return lhsTier < rhsTier }
            let lhsDist = letterDistance(from: inputLetter, to: lhs.pitchClass)
            let rhsDist = letterDistance(from: inputLetter, to: rhs.pitchClass)
            if lhsDist != rhsDist { return lhsDist < rhsDist }
            return lhs.pitchClass.rawValue < rhs.pitchClass.rawValue
        }
    }

    private func naturalnessTier(_ accidental: Accidental) -> Int {
        switch accidental {
        case .natural: return 0
        case .sharp, .flat: return 1
        case .doubleSharp, .doubleFlat: return 2
        }
    }

    private func letterDistance(from a: PitchClass, to b: PitchClass) -> Int {
        let diff = abs(a.rawValue - b.rawValue)
        return min(diff, 7 - diff)
    }
}
