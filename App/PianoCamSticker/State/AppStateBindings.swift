import SwiftUI
import AppCore
import AudioInput

@MainActor
final class AppStateContainer: ObservableObject {
    let appState: AppState
    let midiEngine: MIDIEngine
    let acousticDetector: AcousticPitchDetector
    #if os(macOS)
    let widgetManager: WidgetManager
    #endif

    @Published var midiDevices: [MIDIDevice] = []
    @Published var inputLevel: Float = 0
    @Published var acousticEnabled: Bool = false
    @Published var midiActive: Bool = false
    @Published var startupError: String?

    private var midiTask: Task<Void, Never>?
    private var acousticEventsTask: Task<Void, Never>?
    private var acousticLevelTask: Task<Void, Never>?

    init() {
        let appState = AppState()
        self.appState = appState
        self.midiEngine = MIDIEngine()
        self.acousticDetector = AcousticPitchDetector()
        #if os(macOS)
        self.widgetManager = WidgetManager(appState: appState)
        #endif
    }

    func startMIDI() async {
        guard !midiActive else { return }
        do {
            try await midiEngine.start()
            midiActive = true
            startupError = nil
            await refreshDevices()
            midiTask = Task { @MainActor [weak self] in
                guard let self else { return }
                for await event in self.midiEngine.events {
                    self.appState.handle(event)
                }
            }
        } catch {
            startupError = "MIDI failed to start: \(error)"
        }
    }

    func stopMIDI() async {
        midiTask?.cancel()
        midiTask = nil
        await midiEngine.stop()
        midiActive = false
    }

    func startAcoustic() async {
        guard !acousticEnabled else { return }
        do {
            try await acousticDetector.start()
            acousticEnabled = true
            startupError = nil
            acousticEventsTask = Task { @MainActor [weak self] in
                guard let self else { return }
                for await event in self.acousticDetector.events {
                    self.appState.handle(event)
                }
            }
            acousticLevelTask = Task { @MainActor [weak self] in
                guard let self else { return }
                for await level in self.acousticDetector.inputLevel {
                    self.inputLevel = level
                }
            }
        } catch {
            startupError = "Acoustic failed to start: \(error)"
        }
    }

    func stopAcoustic() async {
        acousticEventsTask?.cancel()
        acousticEventsTask = nil
        acousticLevelTask?.cancel()
        acousticLevelTask = nil
        await acousticDetector.stop()
        acousticEnabled = false
        inputLevel = 0
    }

    func refreshDevices() async {
        midiDevices = await midiEngine.devices()
    }
}
