@_exported import AudioEngine

/// Back-compat alias — Classroom historically used `MIDIEngine` for
/// what MusicCore now calls `MIDIInput`. Same actor, same API, just
/// renamed to be more descriptive of its role (input client) rather
/// than implying a heavyweight engine.
public typealias MIDIEngine = MIDIInput

public extension MIDIInput {
    /// Default-init for Classroom call sites — `MusicCore.MIDIInput`
    /// requires a `clientName`, but Classroom historically called
    /// `MIDIEngine()` with no arguments.
    init() {
        self.init(clientName: "ClassroomMaestro")
    }
}
