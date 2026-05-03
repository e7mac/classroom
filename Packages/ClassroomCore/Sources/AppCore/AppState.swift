import Foundation
import Combine
import MusicTheory
import MusicRendering
import AudioInput

@MainActor
public final class AppState: ObservableObject {
    // MARK: - Published live input

    @Published public private(set) var activeMIDINotes: Set<Int> = []
    @Published public private(set) var displayedNotes: [Note] = []
    @Published public private(set) var lastAnalysis: Analysis = .empty
    @Published public private(set) var progression: [Chord] = []
    @Published public private(set) var recentHistory: [HistoryEntry] = []

    // MARK: - Published configuration

    @Published public var displayMode: DisplayMode {
        didSet { recomputeIfNeeded() }
    }
    @Published public var keySignature: KeySignature {
        didSet { recomputeIfNeeded() }
    }
    @Published public var hideKeySignatureFromStaff: Bool = false
    @Published public var freeze: FreezeState = FreezeState()
    @Published public var analysisDisplayMode: AnalysisDisplayMode = .popJazz
    @Published public var analysisOverlayVisible: Bool = true
    @Published public var clefMode: StaffLayout.Clef
    @Published public var handPosition: HandPosition?

    // MARK: - Private state

    private let theory: MusicTheoryEngine

    // Physical state: which fingers are actually depressed.
    private var physicallyHeldMIDI: Set<Int> = []
    // Sustain state: notes still ringing because pedal kept them alive.
    private var sustainedMIDI: Set<Int> = []
    private var pedalDown: Bool = false

    // Most recent noteOn — used by SingleNote display.
    private var lastNoteOnMIDI: Int?
    // Order of note-ons for SingleNote fallback when last is released.
    private var noteOnHistory: [Int] = []

    // Enharmonic cycle: index per displayed-note slot (resets when notes change).
    private var enharmonicCycleIndex: Int = 0
    private var enharmonicBaseSpelling: [Note] = []

    // MARK: - Init

    public init(
        theory: MusicTheoryEngine = .init(),
        keySignature: KeySignature = .cMajor,
        displayMode: DisplayMode = .chord,
        clefMode: StaffLayout.Clef = .grand
    ) {
        self.theory = theory
        self.keySignature = keySignature
        self.displayMode = displayMode
        self.clefMode = clefMode
    }

    // MARK: - Event ingestion

    // TODO(M5/M6): engines call this on @MainActor from their AsyncStream<NoteEvent> consumers.
    public func handle(_ event: NoteEvent) {
        switch event.kind {
        case .noteOn:
            applyNoteOn(midi: event.midi)
        case .noteOff:
            applyNoteOff(midi: event.midi)
        case .sustainPedal(let down):
            applyPedal(down: down)
        }
    }

    // MARK: - User actions

    public func cycleEnharmonic() {
        guard !displayedNotes.isEmpty else { return }
        if enharmonicBaseSpelling.isEmpty {
            enharmonicBaseSpelling = displayedNotes
        }
        // Use the first note's alternatives count to size the cycle.
        let firstAlternatives = theory.enharmonicAlternatives(for: enharmonicBaseSpelling[0])
        let cycleLength = firstAlternatives.count + 1
        enharmonicCycleIndex = (enharmonicCycleIndex + 1) % cycleLength

        if enharmonicCycleIndex == 0 {
            displayedNotes = enharmonicBaseSpelling
        } else {
            displayedNotes = enharmonicBaseSpelling.map { base in
                let alts = theory.enharmonicAlternatives(for: base)
                let idx = enharmonicCycleIndex - 1
                return idx < alts.count ? alts[idx] : base
            }
        }
    }

    public func clearProgression() {
        progression = []
    }

    public func clearRecentHistory() {
        recentHistory = []
    }

    public func toggleCapsLockFreeze() {
        freeze.capsLockFrozen.toggle()
        recomputeIfNeeded()
    }

    public func setHandPosition(startMIDI: Int) {
        handPosition = HandPosition(startMIDI: startMIDI)
    }

    public func clearHandPosition() {
        handPosition = nil
    }

    // MARK: - Internal event handlers

    private func applyNoteOn(midi: Int) {
        physicallyHeldMIDI.insert(midi)
        sustainedMIDI.remove(midi)
        lastNoteOnMIDI = midi
        if let existing = noteOnHistory.firstIndex(of: midi) {
            noteOnHistory.remove(at: existing)
        }
        noteOnHistory.append(midi)
        recomputeActiveSet()
        recomputeIfNeeded()
    }

    private func applyNoteOff(midi: Int) {
        physicallyHeldMIDI.remove(midi)
        if pedalDown {
            // Pedal keeps it sounding — track separately.
            sustainedMIDI.insert(midi)
        } else {
            // No pedal → fully released.
            sustainedMIDI.remove(midi)
            noteOnHistory.removeAll { $0 == midi }
            if lastNoteOnMIDI == midi {
                lastNoteOnMIDI = noteOnHistory.last
            }
        }
        recomputeActiveSet()
        recomputeIfNeeded()
    }

    private func applyPedal(down: Bool) {
        if down {
            pedalDown = true
            freeze.pedalFrozen = true
        } else {
            // Snapshot the audible chord *before* releasing sustain — that's what
            // gets committed to the progression per spec.
            let snapshotActive = activeMIDINotes
            pedalDown = false
            // Drop sustained-only notes; physically-held ones remain.
            sustainedMIDI.removeAll()
            // Clean up history for notes that are no longer audible.
            noteOnHistory.removeAll { !physicallyHeldMIDI.contains($0) }
            if let last = lastNoteOnMIDI, !physicallyHeldMIDI.contains(last) {
                lastNoteOnMIDI = noteOnHistory.last
            }
            freeze.pedalFrozen = false

            if displayMode == .chordProgression {
                commitProgressionChord(fromActive: snapshotActive)
            }

            recomputeActiveSet()
            recomputeIfNeeded()
        }
    }

    private func commitProgressionChord(fromActive active: Set<Int>) {
        let snapshotNotes = active.sorted().map { keySignature.spell(midi: $0) }
        guard let chord = theory.identifyChord(snapshotNotes) else { return }
        progression.append(chord)
    }

    // MARK: - Derived state

    private func recomputeActiveSet() {
        activeMIDINotes = physicallyHeldMIDI.union(sustainedMIDI)
    }

    private func recomputeIfNeeded() {
        guard !freeze.isFrozen else { return }

        // Active set changed → reset enharmonic cycle.
        enharmonicCycleIndex = 0
        enharmonicBaseSpelling = []

        let sortedActive = activeMIDINotes.sorted()
        let newDisplayed = computeDisplayedNotes(from: sortedActive)
        let newAnalysis = computeAnalysis(for: newDisplayed)

        // Capture the just-played snapshot in recent history when the user releases
        // (active set goes from non-empty to empty). One entry per "release event."
        if newDisplayed.isEmpty, !displayedNotes.isEmpty,
           let label = historyLabel(for: displayedNotes, analysis: lastAnalysis) {
            appendHistory(label: label)
        }

        displayedNotes = newDisplayed
        lastAnalysis = newAnalysis
    }

    private func historyLabel(for notes: [Note], analysis: Analysis) -> String? {
        if let chord = analysis.chord { return chord.symbol }
        if let interval = analysis.interval { return interval.shortName }
        if let scale = analysis.scale {
            return "\(scale.tonic.pitchClass.letterName)\(scale.tonic.accidental.displaySymbol) \(scale.name)"
        }
        if let note = notes.first { return note.description }
        return nil
    }

    private func appendHistory(label: String) {
        recentHistory.append(HistoryEntry(label: label))
        if recentHistory.count > 12 {
            recentHistory.removeFirst(recentHistory.count - 12)
        }
    }

    private func computeDisplayedNotes(from sortedActive: [Int]) -> [Note] {
        switch displayMode {
        case .singleNote:
            guard let midi = lastNoteOnMIDI, activeMIDINotes.contains(midi) else {
                return []
            }
            return [keySignature.spell(midi: midi)]

        case .interval:
            let pick = Array(sortedActive.prefix(2))
            return pick.map { keySignature.spell(midi: $0) }

        case .chord, .chordProgression:
            let pick = Array(sortedActive.prefix(displayMode.maxConcurrentNotes))
            return pick.map { keySignature.spell(midi: $0) }

        case .scale:
            let pick = Array(sortedActive.prefix(displayMode.maxConcurrentNotes))
            return pick.map { keySignature.spell(midi: $0) }

        case .handPosition:
            let pick = Array(sortedActive.prefix(displayMode.maxConcurrentNotes))
            return pick.map { keySignature.spell(midi: $0) }
        }
    }

    private func computeAnalysis(for notes: [Note]) -> Analysis {
        switch displayMode {
        case .singleNote:
            return .empty

        case .interval:
            guard notes.count == 2 else { return .empty }
            let interval = theory.interval(from: notes[0], to: notes[1])
            return Analysis(interval: interval)

        case .chord, .chordProgression:
            guard notes.count >= 2, let chord = theory.identifyChord(notes) else {
                return .empty
            }
            let roman = theory.romanNumeral(for: chord, in: keySignature)
            return Analysis(chord: chord, romanNumeral: roman)

        case .scale:
            guard notes.count >= 3 else { return .empty }
            let scales = theory.identifyScales(notes)
            return Analysis(scale: scales.first)

        case .handPosition:
            return .empty
        }
    }
}
