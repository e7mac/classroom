import SwiftUI
import MusicTheory
import AppCore

public struct AnalysisOverlayView: View {
    public let analysis: Analysis
    public let displayMode: AnalysisDisplayMode
    public let isVisible: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        analysis: Analysis,
        displayMode: AnalysisDisplayMode = .popJazz,
        isVisible: Bool = true
    ) {
        self.analysis = analysis
        self.displayMode = displayMode
        self.isVisible = isVisible
    }

    public var body: some View {
        // Always render the card with a fixed minimum height so the layout
        // doesn't jump when an analysis appears or disappears.
        content
            .frame(maxWidth: .infinity)
            .frame(minHeight: 92)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .cornerRadius(12)
            .opacity(isVisible ? 1 : 0)
            .animation(.reduceMotionAware(.easeInOut(duration: 0.18), reduceMotion: reduceMotion), value: primaryText)
            .animation(.reduceMotionAware(.easeInOut(duration: 0.18), reduceMotion: reduceMotion), value: secondaryText)
            .animation(.reduceMotionAware(.easeInOut(duration: 0.18), reduceMotion: reduceMotion), value: isVisible)
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 4) {
            Text(primaryText)
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .minimumScaleFactor(0.5)
                .foregroundStyle(analysis.isEmpty ? .secondary : .primary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .accessibilityIdentifier("analysis-primary")

            if let secondaryText {
                Text(secondaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                    .accessibilityIdentifier("analysis-secondary")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var primaryText: String {
        guard !analysis.isEmpty else { return "—" }

        if let chord = analysis.chord {
            switch displayMode {
            case .popJazz:
                return chord.symbol
            case .romanNumeral:
                return analysis.romanNumeral?.displayString ?? chord.symbol
            }
        }

        if let interval = analysis.interval {
            return interval.shortName
        }

        if let scale = analysis.scale {
            return "\(scale.tonic.description) \(scale.name)"
        }

        return "—"
    }

    private var secondaryText: String? {
        guard !analysis.isEmpty else { return nil }

        if let chord = analysis.chord {
            switch displayMode {
            case .popJazz:
                return longChordName(chord)
            case .romanNumeral:
                return chord.symbol
            }
        }

        if let interval = analysis.interval {
            return longIntervalName(interval)
        }

        return nil
    }

    private var accessibilityDescription: String {
        if analysis.isEmpty { return "Analysis: no content" }
        if let chord = analysis.chord {
            let long = longChordName(chord)
            if let roman = analysis.romanNumeral?.displayString {
                return "Analysis: \(long) chord, Roman numeral \(roman)"
            }
            return "Analysis: \(long) chord"
        }
        if let interval = analysis.interval {
            return "Analysis: \(longIntervalName(interval))"
        }
        if let scale = analysis.scale {
            return "Analysis: \(scale.tonic.description) \(scale.name) scale"
        }
        if let secondaryText {
            return "\(primaryText). \(secondaryText)"
        }
        return primaryText
    }

    private func longIntervalName(_ interval: Interval) -> String {
        let qualityWord: String
        switch interval.quality {
        case .perfect: qualityWord = "Perfect"
        case .major: qualityWord = "Major"
        case .minor: qualityWord = "Minor"
        case .augmented: qualityWord = "Augmented"
        case .diminished: qualityWord = "Diminished"
        case .doubleAugmented: qualityWord = "Doubly Augmented"
        case .doubleDiminished: qualityWord = "Doubly Diminished"
        }
        let numberWord: String
        switch interval.number {
        case 1: numberWord = "Unison"
        case 2: numberWord = "2nd"
        case 3: numberWord = "3rd"
        case 4: numberWord = "4th"
        case 5: numberWord = "5th"
        case 6: numberWord = "6th"
        case 7: numberWord = "7th"
        case 8: numberWord = "Octave"
        default: numberWord = "\(interval.number)th"
        }
        return "\(qualityWord) \(numberWord)"
    }

    private func longChordName(_ chord: Chord) -> String {
        let qualityWord: String
        switch chord.quality {
        case .major: qualityWord = "Major"
        case .minor: qualityWord = "Minor"
        case .diminished: qualityWord = "Diminished"
        case .augmented: qualityWord = "Augmented"
        case .dominant7: qualityWord = "Dominant 7"
        case .major7: qualityWord = "Major 7"
        case .minor7: qualityWord = "Minor 7"
        case .halfDiminished7: qualityWord = "Half-Diminished 7"
        case .diminished7: qualityWord = "Fully Diminished 7"
        case .sus2: qualityWord = "Sus2"
        case .sus4: qualityWord = "Sus4"
        }
        let rootSymbol = "\(chord.root.pitchClass.letterName)\(chord.root.accidental.displaySymbol)"
        return "\(rootSymbol) \(qualityWord)"
    }
}

#Preview("Empty") {
    AnalysisOverlayView(analysis: .empty)
        .padding()
}

#Preview("Chord — pop/jazz") {
    let chord = Chord(root: Note(midi: 60), quality: .major7)
    return AnalysisOverlayView(
        analysis: Analysis(chord: chord),
        displayMode: .popJazz
    ).padding()
}

#Preview("Chord — Roman numeral") {
    let chord = Chord(root: Note(midi: 67), quality: .dominant7)
    let roman = RomanNumeral(symbol: "V", qualityModifier: "7")
    return AnalysisOverlayView(
        analysis: Analysis(chord: chord, romanNumeral: roman),
        displayMode: .romanNumeral
    ).padding()
}

#Preview("Interval") {
    let interval = Interval(from: Note(midi: 60), to: Note(midi: 67))
    return AnalysisOverlayView(analysis: Analysis(interval: interval)).padding()
}

#Preview("Scale") {
    let scale = Scale.major(tonic: Note(midi: 60))
    return AnalysisOverlayView(analysis: Analysis(scale: scale)).padding()
}

#Preview("Hidden") {
    AnalysisOverlayView(
        analysis: Analysis(chord: Chord(root: Note(midi: 60), quality: .major)),
        isVisible: false
    ).padding()
}
