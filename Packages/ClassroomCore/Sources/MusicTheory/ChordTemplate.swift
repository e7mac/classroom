import Foundation

public struct ChordTemplate: Sendable, Hashable {
    public let quality: Chord.Quality
    public let intervalsFromRoot: [Int]

    public static let all: [ChordTemplate] = [
        ChordTemplate(quality: .major, intervalsFromRoot: [0, 4, 7]),
        ChordTemplate(quality: .minor, intervalsFromRoot: [0, 3, 7]),
        ChordTemplate(quality: .diminished, intervalsFromRoot: [0, 3, 6]),
        ChordTemplate(quality: .augmented, intervalsFromRoot: [0, 4, 8]),
        ChordTemplate(quality: .dominant7, intervalsFromRoot: [0, 4, 7, 10]),
        ChordTemplate(quality: .major7, intervalsFromRoot: [0, 4, 7, 11]),
        ChordTemplate(quality: .minor7, intervalsFromRoot: [0, 3, 7, 10]),
        ChordTemplate(quality: .halfDiminished7, intervalsFromRoot: [0, 3, 6, 10]),
        ChordTemplate(quality: .diminished7, intervalsFromRoot: [0, 3, 6, 9]),
        ChordTemplate(quality: .sus2, intervalsFromRoot: [0, 2, 7]),
        ChordTemplate(quality: .sus4, intervalsFromRoot: [0, 5, 7]),
    ]
}
