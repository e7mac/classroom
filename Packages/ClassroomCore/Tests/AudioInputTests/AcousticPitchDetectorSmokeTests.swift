import Foundation
import Testing
@testable import AudioInput

@Suite
struct AcousticPitchDetectorSmokeTests {
    // Note: we don't call .start() in CI — it would prompt for mic permission and
    // depend on hardware. We only verify the public surface compiles and the
    // streams are exposed.

    @Test func initializationDoesNotCrash() async {
        _ = AcousticPitchDetector()
    }

    @Test func initializationWithCustomConfigDoesNotCrash() async {
        let config = AcousticPitchDetector.Configuration(
            algorithm: YINDetector(bufferSize: 1024),
            confidenceThreshold: 0.7
        )
        _ = AcousticPitchDetector(configuration: config)
    }

    @Test func eventsExposesAsyncStream() async {
        let det = AcousticPitchDetector()
        let stream: AsyncStream<NoteEvent> = det.events
        _ = stream
    }

    @Test func inputLevelExposesAsyncStream() async {
        let det = AcousticPitchDetector()
        let stream: AsyncStream<Float> = det.inputLevel
        _ = stream
    }
}
