import Foundation

public struct ScaleTemplate: Sendable, Hashable {
    public let name: String
    public let intervalsFromTonic: [Int]

    public init(name: String, intervalsFromTonic: [Int]) {
        self.name = name
        self.intervalsFromTonic = intervalsFromTonic
    }

    public static let all: [ScaleTemplate] = [
        ScaleTemplate(name: "Major", intervalsFromTonic: [0, 2, 4, 5, 7, 9, 11]),
        ScaleTemplate(name: "Natural Minor", intervalsFromTonic: [0, 2, 3, 5, 7, 8, 10]),
        ScaleTemplate(name: "Harmonic Minor", intervalsFromTonic: [0, 2, 3, 5, 7, 8, 11]),
        ScaleTemplate(name: "Melodic Minor", intervalsFromTonic: [0, 2, 3, 5, 7, 9, 11]),

        ScaleTemplate(name: "Ionian", intervalsFromTonic: [0, 2, 4, 5, 7, 9, 11]),
        ScaleTemplate(name: "Dorian", intervalsFromTonic: [0, 2, 3, 5, 7, 9, 10]),
        ScaleTemplate(name: "Phrygian", intervalsFromTonic: [0, 1, 3, 5, 7, 8, 10]),
        ScaleTemplate(name: "Lydian", intervalsFromTonic: [0, 2, 4, 6, 7, 9, 11]),
        ScaleTemplate(name: "Mixolydian", intervalsFromTonic: [0, 2, 4, 5, 7, 9, 10]),
        ScaleTemplate(name: "Aeolian", intervalsFromTonic: [0, 2, 3, 5, 7, 8, 10]),
        ScaleTemplate(name: "Locrian", intervalsFromTonic: [0, 1, 3, 5, 6, 8, 10]),

        ScaleTemplate(name: "Major Pentatonic", intervalsFromTonic: [0, 2, 4, 7, 9]),
        ScaleTemplate(name: "Minor Pentatonic", intervalsFromTonic: [0, 3, 5, 7, 10]),
        ScaleTemplate(name: "Blues", intervalsFromTonic: [0, 3, 5, 6, 7, 10]),
        ScaleTemplate(name: "Major Blues", intervalsFromTonic: [0, 2, 3, 4, 7, 9]),

        ScaleTemplate(name: "Whole Tone", intervalsFromTonic: [0, 2, 4, 6, 8, 10]),
        ScaleTemplate(name: "Chromatic", intervalsFromTonic: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]),
        ScaleTemplate(name: "Diminished (W-H)", intervalsFromTonic: [0, 2, 3, 5, 6, 8, 9, 11]),
        ScaleTemplate(name: "Diminished (H-W)", intervalsFromTonic: [0, 1, 3, 4, 6, 7, 9, 10]),

        ScaleTemplate(name: "Bebop Dominant", intervalsFromTonic: [0, 2, 4, 5, 7, 9, 10, 11]),
        ScaleTemplate(name: "Bebop Major", intervalsFromTonic: [0, 2, 4, 5, 7, 8, 9, 11]),
        ScaleTemplate(name: "Bebop Minor", intervalsFromTonic: [0, 2, 3, 5, 7, 8, 10, 11]),
        ScaleTemplate(name: "Bebop Dorian", intervalsFromTonic: [0, 2, 3, 4, 5, 7, 9, 10]),

        ScaleTemplate(name: "Lydian Dominant", intervalsFromTonic: [0, 2, 4, 6, 7, 9, 10]),
        ScaleTemplate(name: "Altered", intervalsFromTonic: [0, 1, 3, 4, 6, 8, 10]),
        ScaleTemplate(name: "Phrygian Dominant", intervalsFromTonic: [0, 1, 4, 5, 7, 8, 10]),
        ScaleTemplate(name: "Hungarian Minor", intervalsFromTonic: [0, 2, 3, 6, 7, 8, 11]),
        ScaleTemplate(name: "Double Harmonic", intervalsFromTonic: [0, 1, 4, 5, 7, 8, 11]),

        ScaleTemplate(name: "Hirajoshi", intervalsFromTonic: [0, 2, 3, 7, 8]),
        ScaleTemplate(name: "In Sen", intervalsFromTonic: [0, 1, 5, 7, 10]),
    ]
}
