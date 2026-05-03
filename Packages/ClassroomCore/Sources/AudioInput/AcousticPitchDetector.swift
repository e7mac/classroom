import Foundation
import AVFoundation

public actor AcousticPitchDetector {

    // MARK: Types

    public struct Configuration: Sendable {
        public var algorithm: any PitchDetectionAlgorithm
        public var confidenceThreshold: Float
        public var onsetEnergyThreshold: Float
        public var maxCentsOff: Float
        public var sustainFrameCountForRelease: Int

        public init(
            algorithm: any PitchDetectionAlgorithm = YINDetector(),
            confidenceThreshold: Float = 0.85,
            onsetEnergyThreshold: Float = 0.02,
            maxCentsOff: Float = 35,
            sustainFrameCountForRelease: Int = 6
        ) {
            self.algorithm = algorithm
            self.confidenceThreshold = confidenceThreshold
            self.onsetEnergyThreshold = onsetEnergyThreshold
            self.maxCentsOff = maxCentsOff
            self.sustainFrameCountForRelease = sustainFrameCountForRelease
        }
    }

    public enum PitchDetectorError: Error, Sendable {
        case microphonePermissionDenied
        case audioEngineStartFailed(NSError)
        case unsupportedFormat
    }

    // MARK: Storage

    private nonisolated let _events: AsyncStream<NoteEvent>
    private nonisolated let eventsContinuation: AsyncStream<NoteEvent>.Continuation
    private nonisolated let _inputLevel: AsyncStream<Float>
    private nonisolated let levelContinuation: AsyncStream<Float>.Continuation

    private let engine = AVAudioEngine()
    private var configuration: Configuration
    private var tapInstalled = false
    private var isRunning = false

    // Detection state machine
    private var currentNote: Int?
    private var framesSilent: Int = 0
    private var onsetState = OnsetDetector.State()

    // MARK: Initialization

    public init(configuration: Configuration = .init()) {
        var ec: AsyncStream<NoteEvent>.Continuation!
        self._events = AsyncStream { ec = $0 }
        self.eventsContinuation = ec
        var lc: AsyncStream<Float>.Continuation!
        self._inputLevel = AsyncStream { lc = $0 }
        self.levelContinuation = lc
        self.configuration = configuration
    }

    deinit {
        eventsContinuation.finish()
        levelContinuation.finish()
    }

    // MARK: Public API

    public nonisolated var events: AsyncStream<NoteEvent> { _events }
    public nonisolated var inputLevel: AsyncStream<Float> { _inputLevel }

    public func start() async throws {
        guard !isRunning else { return }
        try await requestMicPermission()
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetooth, .mixWithOthers])
        try session.setActive(true)
        #endif
        installTapIfNeeded()
        do {
            try engine.start()
        } catch {
            throw PitchDetectorError.audioEngineStartFailed(error as NSError)
        }
        isRunning = true
    }

    public func stop() async {
        if tapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        if engine.isRunning {
            engine.stop()
        }
        currentNote = nil
        framesSilent = 0
        onsetState = OnsetDetector.State()
        isRunning = false
    }

    public func updateConfiguration(_ config: Configuration) async throws {
        let wasRunning = isRunning
        if wasRunning {
            await stop()
        }
        self.configuration = config
        if wasRunning {
            try await start()
        }
    }

    // MARK: Private — engine

    private func requestMicPermission() async throws {
        #if os(iOS)
        let granted = await AVAudioApplication.requestRecordPermission()
        #else
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        #endif
        if !granted {
            throw PitchDetectorError.microphonePermissionDenied
        }
    }

    private func installTapIfNeeded() {
        guard !tapInstalled else { return }
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        let bufferSize = AVAudioFrameCount(configuration.algorithm.bufferSize)
        let expectedSampleRate = configuration.algorithm.sampleRate

        inputNode.installTap(
            onBus: 0,
            bufferSize: bufferSize,
            format: format
        ) { [weak self] buffer, _ in
            guard let self else { return }
            // Extract samples on the audio thread into a Sendable [Float] before
            // hopping into the actor — AVAudioPCMBuffer itself is not Sendable.
            guard let mono = Self.extractMono(from: buffer) else { return }
            let bufferSampleRate = buffer.format.sampleRate
            Task.detached(priority: .userInitiated) {
                await self.process(
                    samples: mono,
                    sampleRate: bufferSampleRate,
                    expectedSampleRate: expectedSampleRate
                )
            }
        }
        tapInstalled = true
    }

    private static func extractMono(from buffer: AVAudioPCMBuffer) -> [Float]? {
        guard let channelData = buffer.floatChannelData else { return nil }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return nil }
        let channelCount = Int(buffer.format.channelCount)

        var mono = [Float](repeating: 0, count: count)
        if channelCount == 1 {
            mono.withUnsafeMutableBufferPointer { dst in
                dst.baseAddress!.update(from: channelData[0], count: count)
            }
        } else {
            for i in 0..<count {
                var sum: Float = 0
                for ch in 0..<channelCount {
                    sum += channelData[ch][i]
                }
                mono[i] = sum / Float(channelCount)
            }
        }
        return mono
    }

    // MARK: Private — DSP pipeline

    private func process(samples: [Float], sampleRate: Double, expectedSampleRate: Double) {
        let count = samples.count
        guard count > 0 else { return }

        guard abs(sampleRate - expectedSampleRate) < 0.5 else {
            print("AcousticPitchDetector: sample rate mismatch (\(sampleRate) vs \(expectedSampleRate)); skipping buffer")
            return
        }

        let algorithm = configuration.algorithm
        let result: (rms: Float, detection: (frequency: Float, confidence: Float)?) =
            samples.withUnsafeBufferPointer { buf in
                var sumSquares: Float = 0
                for i in 0..<count {
                    sumSquares += buf[i] * buf[i]
                }
                let rms = sqrt(sumSquares / Float(count))
                let detection = algorithm.detectPitch(in: buf.baseAddress!, count: count)
                return (rms, detection)
            }

        let rms = result.rms
        let detection = result.detection
        levelContinuation.yield(min(1, max(0, rms)))

        let onsetDetector = OnsetDetector(energyThreshold: configuration.onsetEnergyThreshold)
        let (isOnset, newOnsetState) = onsetDetector.process(rms: rms, state: onsetState)
        onsetState = newOnsetState

        // Detection state machine: gate on confidence + tuning, then route to noteOn/noteOff.
        if let (frequency, confidence) = detection,
           confidence >= configuration.confidenceThreshold {
            let midi = FrequencyToMIDI.midi(from: frequency)
            let centsOff = abs(FrequencyToMIDI.cents(from: frequency, midi: midi))
            if centsOff <= configuration.maxCentsOff {
                let velocity = UInt8(min(127, max(1, Int(rms * 127 * 4))))
                if currentNote == nil || isOnset || midi != currentNote {
                    if let prev = currentNote, prev != midi {
                        eventsContinuation.yield(
                            NoteEvent(
                                kind: .noteOff,
                                midi: prev,
                                velocity: 0,
                                source: .acoustic(confidence: confidence)
                            )
                        )
                    }
                    eventsContinuation.yield(
                        NoteEvent(
                            kind: .noteOn,
                            midi: midi,
                            velocity: velocity,
                            source: .acoustic(confidence: confidence)
                        )
                    )
                    currentNote = midi
                    framesSilent = 0
                } else {
                    framesSilent = 0
                }
                return
            }
        }

        framesSilent += 1
        if let note = currentNote,
           framesSilent >= configuration.sustainFrameCountForRelease {
            eventsContinuation.yield(
                NoteEvent(
                    kind: .noteOff,
                    midi: note,
                    velocity: 0,
                    source: .acoustic(confidence: 0)
                )
            )
            currentNote = nil
        }
    }
}
