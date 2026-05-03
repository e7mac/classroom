import Foundation
import Testing
@testable import AppCore
import MusicTheory
import MusicRendering
import AudioInput

private func midiNoteOn(_ midi: Int) -> NoteEvent {
    .init(kind: .noteOn, midi: midi, velocity: 100, source: .midi(deviceID: "test"))
}

private func midiNoteOff(_ midi: Int) -> NoteEvent {
    .init(kind: .noteOff, midi: midi, velocity: 0, source: .midi(deviceID: "test"))
}

private func pedal(_ down: Bool) -> NoteEvent {
    .init(kind: .sustainPedal(down: down), midi: 0, velocity: 0, source: .midi(deviceID: "test"))
}

private let bbMajor = KeySignature(tonic: .b, accidental: .flat, mode: .major)

@Suite @MainActor
struct AppStateTests {

    // MARK: - Initial state

    @Test func initialStateIsEmpty() {
        let state = AppState()
        #expect(state.activeMIDINotes.isEmpty)
        #expect(state.displayedNotes.isEmpty)
        #expect(state.lastAnalysis.isEmpty)
        #expect(state.progression.isEmpty)
    }

    @Test func initialModeIsSingleNote() {
        let state = AppState()
        #expect(state.displayMode == .singleNote)
    }

    @Test func initialKeyIsCMajor() {
        let state = AppState()
        #expect(state.keySignature == .cMajor)
    }

    @Test func initialFreezeIsClear() {
        let state = AppState()
        #expect(state.freeze.isFrozen == false)
    }

    @Test func initialClefIsGrand() {
        let state = AppState()
        #expect(state.clefMode == .grand)
    }

    @Test func initialAnalysisDisplayIsPopJazz() {
        let state = AppState()
        #expect(state.analysisDisplayMode == .popJazz)
    }

    @Test func initialOverlayVisible() {
        let state = AppState()
        #expect(state.analysisOverlayVisible == true)
    }

    // MARK: - Basic note on/off

    @Test func noteOnUpdatesActiveAndDisplayedInSingleNote() {
        let state = AppState()
        state.handle(midiNoteOn(60))
        #expect(state.activeMIDINotes == [60])
        #expect(state.displayedNotes == [Note(pitchClass: .c, octave: 4)])
        #expect(state.lastAnalysis.isEmpty)
    }

    @Test func noteOffClearsActiveAndDisplayed() {
        let state = AppState()
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOff(60))
        #expect(state.activeMIDINotes.isEmpty)
        #expect(state.displayedNotes.isEmpty)
    }

    @Test func spellingFollowsKeySignature() {
        let state = AppState(keySignature: bbMajor)
        state.handle(midiNoteOn(70))
        #expect(state.displayedNotes == [Note(pitchClass: .b, accidental: .flat, octave: 4)])
    }

    // MARK: - SingleNote mode

    @Test func singleNoteShowsLatestNoteOn() {
        let state = AppState()
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(64))
        #expect(state.displayedNotes == [Note(pitchClass: .e, octave: 4)])
    }

    @Test func singleNoteRevertsToPriorHeldOnRelease() {
        let state = AppState()
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(64))
        state.handle(midiNoteOff(64))
        #expect(state.displayedNotes == [Note(pitchClass: .c, octave: 4)])
    }

    @Test func singleNoteEmptyWhenAllReleased() {
        let state = AppState()
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(64))
        state.handle(midiNoteOff(60))
        state.handle(midiNoteOff(64))
        #expect(state.displayedNotes.isEmpty)
    }

    // MARK: - Interval mode

    @Test func intervalModeShowsTwoLowestNotes() {
        let state = AppState(displayMode: .interval)
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(67))
        #expect(state.displayedNotes.count == 2)
        #expect(state.lastAnalysis.interval?.shortName == "P5")
    }

    @Test func intervalModeWithSingleHeldNoteHasNoInterval() {
        let state = AppState(displayMode: .interval)
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(67))
        state.handle(midiNoteOff(67))
        #expect(state.displayedNotes == [Note(pitchClass: .c, octave: 4)])
        #expect(state.lastAnalysis.interval == nil)
    }

    @Test func intervalModeMajorThird() {
        let state = AppState(displayMode: .interval)
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(64))
        #expect(state.lastAnalysis.interval?.shortName == "M3")
    }

    // MARK: - Chord mode

    @Test func chordModeIdentifiesCMajor() {
        let state = AppState(displayMode: .chord)
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(64))
        state.handle(midiNoteOn(67))
        #expect(state.displayedNotes.count == 3)
        let chord = state.lastAnalysis.chord
        #expect(chord?.root.pitchClass == .c)
        #expect(chord?.quality == .major)
    }

    @Test func chordModeIdentifiesC7() {
        let state = AppState(displayMode: .chord)
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(64))
        state.handle(midiNoteOn(67))
        state.handle(midiNoteOn(70))
        let chord = state.lastAnalysis.chord
        #expect(chord?.root.pitchClass == .c)
        #expect(chord?.quality == .dominant7)
    }

    @Test func chordModeProvidesRomanNumeral() {
        let state = AppState(displayMode: .chord)
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(64))
        state.handle(midiNoteOn(67))
        #expect(state.lastAnalysis.romanNumeral != nil)
        #expect(state.lastAnalysis.romanNumeral?.symbol == "I")
    }

    // MARK: - Scale mode

    @Test func scaleModeIdentifiesAScaleForCMajorPitchSet() {
        let state = AppState(displayMode: .scale)
        // C major scale pitch set: C D E F G A B (also matches modes).
        for midi in [60, 62, 64, 65, 67, 69, 71] {
            state.handle(midiNoteOn(midi))
        }
        let scale = state.lastAnalysis.scale
        #expect(scale != nil)
        // Engine returns the first match; just confirm we got a 7-note scale on a played tonic.
        #expect(scale?.intervalsFromTonic.count == 7)
        let playedPitchClasses: Set<PitchClass> = [.c, .d, .e, .f, .g, .a, .b]
        #expect(scale.map { playedPitchClasses.contains($0.tonic.pitchClass) } == true)
    }

    @Test func scaleModeEmptyAnalysisWithFewNotes() {
        let state = AppState(displayMode: .scale)
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(62))
        #expect(state.lastAnalysis.scale == nil)
    }

    // MARK: - ChordProgression mode + sustain pedal

    @Test func progressionEmptyByDefault() {
        let state = AppState(displayMode: .chordProgression)
        #expect(state.progression.isEmpty)
    }

    @Test func chordProgressionShowsLiveChordBeforePedal() {
        let state = AppState(displayMode: .chordProgression)
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(64))
        state.handle(midiNoteOn(67))
        let chord = state.lastAnalysis.chord
        #expect(chord?.root.pitchClass == .c)
        #expect(chord?.quality == .major)
        #expect(state.progression.isEmpty)
    }

    @Test func pedalDownFreezesPedalFlag() {
        let state = AppState(displayMode: .chordProgression)
        state.handle(pedal(true))
        #expect(state.freeze.pedalFrozen == true)
        #expect(state.freeze.isFrozen == true)
    }

    @Test func pedalSustainsHeldNotesAcrossNoteOff() {
        let state = AppState(displayMode: .chord)
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(64))
        state.handle(midiNoteOn(67))
        state.handle(pedal(true))
        // Release fingers, but pedal sustains.
        state.handle(midiNoteOff(60))
        state.handle(midiNoteOff(64))
        state.handle(midiNoteOff(67))
        #expect(state.activeMIDINotes == [60, 64, 67])
    }

    @Test func pedalUpReleasesSustainedNotes() {
        let state = AppState(displayMode: .chord)
        state.handle(midiNoteOn(60))
        state.handle(pedal(true))
        state.handle(midiNoteOff(60))
        state.handle(pedal(false))
        #expect(state.activeMIDINotes.isEmpty)
        #expect(state.freeze.pedalFrozen == false)
    }

    @Test func pedalUpKeepsPhysicallyHeldNotes() {
        let state = AppState(displayMode: .chord)
        state.handle(midiNoteOn(60))
        state.handle(pedal(true))
        // Note still physically held; pedal up shouldn't drop it.
        state.handle(pedal(false))
        #expect(state.activeMIDINotes == [60])
    }

    @Test func progressionCommitsChordOnPedalUp() {
        let state = AppState(displayMode: .chordProgression)
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(64))
        state.handle(midiNoteOn(67))
        state.handle(pedal(true))
        state.handle(midiNoteOff(60))
        state.handle(midiNoteOff(64))
        state.handle(midiNoteOff(67))
        state.handle(pedal(false))
        #expect(state.progression.count == 1)
        #expect(state.progression[0].root.pitchClass == .c)
        #expect(state.progression[0].quality == .major)
    }

    @Test func progressionAccumulatesMultipleChords() {
        let state = AppState(displayMode: .chordProgression)
        // First chord: C major
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(64))
        state.handle(midiNoteOn(67))
        state.handle(pedal(true))
        state.handle(midiNoteOff(60))
        state.handle(midiNoteOff(64))
        state.handle(midiNoteOff(67))
        state.handle(pedal(false))
        // Second chord: F major (65, 69, 72)
        state.handle(midiNoteOn(65))
        state.handle(midiNoteOn(69))
        state.handle(midiNoteOn(72))
        state.handle(pedal(true))
        state.handle(midiNoteOff(65))
        state.handle(midiNoteOff(69))
        state.handle(midiNoteOff(72))
        state.handle(pedal(false))

        #expect(state.progression.count == 2)
        #expect(state.progression[0].root.pitchClass == .c)
        #expect(state.progression[1].root.pitchClass == .f)
        #expect(state.progression[1].quality == .major)
    }

    @Test func clearProgressionEmptiesIt() {
        let state = AppState(displayMode: .chordProgression)
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(64))
        state.handle(midiNoteOn(67))
        state.handle(pedal(true))
        state.handle(midiNoteOff(60))
        state.handle(midiNoteOff(64))
        state.handle(midiNoteOff(67))
        state.handle(pedal(false))
        #expect(state.progression.count == 1)
        state.clearProgression()
        #expect(state.progression.isEmpty)
    }

    @Test func pedalUpDoesNotCommitWhenNoChordIdentifiable() {
        let state = AppState(displayMode: .chordProgression)
        state.handle(midiNoteOn(60))
        state.handle(pedal(true))
        state.handle(midiNoteOff(60))
        state.handle(pedal(false))
        #expect(state.progression.isEmpty)
    }

    @Test func pedalUpInNonProgressionModeDoesNotAffectProgression() {
        let state = AppState(displayMode: .chord)
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(64))
        state.handle(midiNoteOn(67))
        state.handle(pedal(true))
        state.handle(midiNoteOff(60))
        state.handle(midiNoteOff(64))
        state.handle(midiNoteOff(67))
        state.handle(pedal(false))
        #expect(state.progression.isEmpty)
    }

    // MARK: - Caps Lock freeze

    @Test func toggleCapsLockTurnsFreezeOn() {
        let state = AppState()
        state.toggleCapsLockFreeze()
        #expect(state.freeze.capsLockFrozen == true)
        #expect(state.freeze.isFrozen == true)
    }

    @Test func toggleCapsLockTwiceRestoresUnfrozen() {
        let state = AppState()
        state.toggleCapsLockFreeze()
        state.toggleCapsLockFreeze()
        #expect(state.freeze.capsLockFrozen == false)
    }

    @Test func capsLockFreezeBlocksDisplayUpdates() {
        let state = AppState()
        state.toggleCapsLockFreeze()
        state.handle(midiNoteOn(60))
        // activeMIDINotes still tracks internally...
        #expect(state.activeMIDINotes == [60])
        // ...but displayedNotes does not update.
        #expect(state.displayedNotes.isEmpty)
    }

    @Test func unfreezingCapsLockRecomputesFromHeldNotes() {
        let state = AppState()
        state.toggleCapsLockFreeze()
        state.handle(midiNoteOn(60))
        #expect(state.displayedNotes.isEmpty)
        state.toggleCapsLockFreeze()
        #expect(state.displayedNotes == [Note(pitchClass: .c, octave: 4)])
    }

    // MARK: - Enharmonic cycling

    @Test func cycleEnharmonicGoesFromSharpToFlat() {
        let state = AppState()
        state.handle(midiNoteOn(61))
        #expect(state.displayedNotes == [Note(pitchClass: .c, accidental: .sharp, octave: 4)])
        state.cycleEnharmonic()
        #expect(state.displayedNotes == [Note(pitchClass: .d, accidental: .flat, octave: 4)])
    }

    @Test func cycleEnharmonicWrapsBackToOriginal() {
        let state = AppState()
        state.handle(midiNoteOn(61))
        state.cycleEnharmonic()
        state.cycleEnharmonic()
        #expect(state.displayedNotes == [Note(pitchClass: .c, accidental: .sharp, octave: 4)])
    }

    @Test func enharmonicCycleResetsOnNoteChange() {
        let state = AppState()
        state.handle(midiNoteOn(61))
        state.cycleEnharmonic()
        // Release and play a different note.
        state.handle(midiNoteOff(61))
        state.handle(midiNoteOn(60))
        // Now displayed notes should be the natural key spelling, not a cycled one.
        #expect(state.displayedNotes == [Note(pitchClass: .c, octave: 4)])
    }

    @Test func cycleEnharmonicWithEmptyDisplayedDoesNothing() {
        let state = AppState()
        state.cycleEnharmonic()
        #expect(state.displayedNotes.isEmpty)
    }

    // MARK: - Hand position

    @Test func setHandPositionStoresPosition() {
        let state = AppState(displayMode: .handPosition)
        state.setHandPosition(startMIDI: 60)
        #expect(state.handPosition?.startMIDI == 60)
        #expect(state.handPosition?.fingerCount == 5)
        #expect(state.handPosition?.source == .userSpecified)
    }

    @Test func clearHandPositionRemovesIt() {
        let state = AppState(displayMode: .handPosition)
        state.setHandPosition(startMIDI: 60)
        state.clearHandPosition()
        #expect(state.handPosition == nil)
    }

    @Test func handPositionModeShowsNotesWithoutAnalysis() {
        let state = AppState(displayMode: .handPosition)
        state.handle(midiNoteOn(64))
        #expect(state.displayedNotes == [Note(pitchClass: .e, octave: 4)])
        #expect(state.lastAnalysis.isEmpty)
    }

    // MARK: - Mode switching

    @Test func changingDisplayModeRecomputesDisplay() {
        let state = AppState(displayMode: .singleNote)
        state.handle(midiNoteOn(60))
        state.handle(midiNoteOn(64))
        state.handle(midiNoteOn(67))
        #expect(state.displayedNotes.count == 1)
        state.displayMode = .chord
        #expect(state.displayedNotes.count == 3)
        #expect(state.lastAnalysis.chord?.root.pitchClass == .c)
    }

    @Test func changingKeyRecomputesSpelling() {
        let state = AppState()
        state.handle(midiNoteOn(70))
        #expect(state.displayedNotes == [Note(pitchClass: .a, accidental: .sharp, octave: 4)])
        state.keySignature = bbMajor
        #expect(state.displayedNotes == [Note(pitchClass: .b, accidental: .flat, octave: 4)])
    }

    // MARK: - Pedal interaction with re-attack

    @Test func reAttackRemovesNoteFromSustainedSet() {
        let state = AppState(displayMode: .chord)
        state.handle(midiNoteOn(60))
        state.handle(pedal(true))
        state.handle(midiNoteOff(60))
        // 60 is in sustained set now. Re-attack...
        state.handle(midiNoteOn(60))
        // Now a noteOff with no pedal up should have it... wait, pedal is still down.
        // So when pedal lifts, 60 is physically held → stays in active.
        state.handle(pedal(false))
        #expect(state.activeMIDINotes == [60])
    }
}
