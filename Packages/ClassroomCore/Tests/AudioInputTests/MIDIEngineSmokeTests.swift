import Foundation
import Testing
@testable import AudioInput

@Suite
struct MIDIEngineSmokeTests {
    @Test func initializationDoesNotCrash() async {
        _ = MIDIEngine()
    }

    @Test func eventsExposesAsyncStream() async {
        let engine = MIDIEngine()
        let stream: AsyncStream<NoteEvent> = engine.events
        _ = stream
    }

    @Test func devicesReturnsArray() async {
        let engine = MIDIEngine()
        let devices: [MIDIDevice] = await engine.devices()
        _ = devices
    }

    @Test func startAndStopRoundTrips() async throws {
        let engine = MIDIEngine()
        try await engine.start()
        await engine.stop()
    }
}
