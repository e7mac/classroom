import Foundation
import CoreMIDI

public enum MIDIEngineError: Error, Sendable {
    case clientCreationFailed(OSStatus)
    case portCreationFailed(OSStatus)
}

/// CoreMIDI client that emits parsed `NoteEvent`s as an `AsyncStream`.
///
/// Usage:
///   let engine = MIDIEngine()
///   try await engine.start()
///   for await event in engine.events {
///       print(event)
///   }
public actor MIDIEngine {

    // MARK: Storage

    // Holds CoreMIDI handles + the source map shared with the receive block.
    // @unchecked Sendable: writes are only performed during start()/stop() from the
    // actor body; reads from the C callback happen after writes are complete and the
    // map is treated as a read-only snapshot for the lifetime of the connection.
    private final class Storage: @unchecked Sendable {
        var client: MIDIClientRef = 0
        var port: MIDIPortRef = 0
        var sourceMap: [Int: String] = [:]

        func disposeClientAndPort() {
            if port != 0 {
                MIDIPortDispose(port)
                port = 0
            }
            if client != 0 {
                MIDIClientDispose(client)
                client = 0
            }
            sourceMap.removeAll()
        }
    }

    // MARK: Properties

    private nonisolated let storage = Storage()
    private nonisolated let stream: AsyncStream<NoteEvent>
    private nonisolated let continuation: AsyncStream<NoteEvent>.Continuation
    private let parser = MIDIPacketParser()
    private var disabledDeviceIDs: Set<String> = []
    private var connectedDeviceIDs: [String] = []
    private var isRunning = false

    // MARK: Initialization

    public init() {
        var localContinuation: AsyncStream<NoteEvent>.Continuation!
        self.stream = AsyncStream { localContinuation = $0 }
        self.continuation = localContinuation
    }

    deinit {
        storage.disposeClientAndPort()
        continuation.finish()
    }

    // MARK: Public API

    /// First consumer wins; v1 expects a single consumer.
    public nonisolated var events: AsyncStream<NoteEvent> { stream }

    public func devices() -> [MIDIDevice] {
        Self.enumerateDevices()
    }

    public func start() throws {
        guard !isRunning else { return }

        var client: MIDIClientRef = 0
        let clientStatus = MIDIClientCreateWithBlock(
            "ClassroomMaestro" as CFString,
            &client,
            { _ in }
        )
        guard clientStatus == noErr else {
            throw MIDIEngineError.clientCreationFailed(clientStatus)
        }

        // We use the deprecated MIDIInputPortCreateWithBlock to get classic
        // MIDIPacketList delivery. The modern UMP-based API is significantly
        // more complex and offers no benefit for MIDI 1.0 input in v1.
        var port: MIDIPortRef = 0
        let storageRef = self.storage
        let parserRef = self.parser
        let continuationRef = self.continuation

        let portStatus = MIDIInputPortCreateWithBlock(
            client,
            "ClassroomMaestro Input" as CFString,
            &port
        ) { packetListPtr, srcConnRefCon in
            let index = Int(bitPattern: srcConnRefCon)
            guard index > 0 else { return }
            guard let deviceID = storageRef.sourceMap[index] else { return }

            let timestamp = Date()
            let packetList = packetListPtr.pointee
            let packetCount = Int(packetList.numPackets)
            guard packetCount > 0 else { return }

            var packet = packetList.packet
            for _ in 0..<packetCount {
                let bytes = packet.bytes()
                let events = parserRef.parse(
                    bytes: bytes,
                    deviceID: deviceID,
                    timestamp: timestamp
                )
                for event in events {
                    continuationRef.yield(event)
                }
                packet = withUnsafePointer(to: &packet) { MIDIPacketNext($0).pointee }
            }
        }

        guard portStatus == noErr else {
            MIDIClientDispose(client)
            throw MIDIEngineError.portCreationFailed(portStatus)
        }

        storage.client = client
        storage.port = port

        connectSources()
        isRunning = true
    }

    public func stop() {
        storage.disposeClientAndPort()
        connectedDeviceIDs.removeAll()
        isRunning = false
    }

    public func setEnabled(_ enabled: Bool, for deviceID: String) {
        if enabled {
            disabledDeviceIDs.remove(deviceID)
        } else {
            disabledDeviceIDs.insert(deviceID)
        }
    }

    // MARK: Private

    private func connectSources() {
        let count = MIDIGetNumberOfSources()
        guard count > 0 else { return }

        var map: [Int: String] = [:]
        var ids: [String] = []

        for i in 0..<count {
            let endpoint = MIDIGetSource(i)
            let deviceID = Self.uniqueID(of: endpoint) ?? "unknown-\(i)"
            let refConIndex = i + 1
            let refCon = UnsafeMutableRawPointer(bitPattern: refConIndex)
            let status = MIDIPortConnectSource(storage.port, endpoint, refCon)
            if status == noErr {
                map[refConIndex] = deviceID
                ids.append(deviceID)
            } else {
                print("MIDIEngine: failed to connect source \(i): \(status)")
            }
        }

        storage.sourceMap = map
        connectedDeviceIDs = ids
    }

    // The continuation is only yielded to from the receive block, which has no
    // access to actor-isolated state. Filtering by disabled device must happen
    // here if we want it to be authoritative — but doing so requires hopping
    // into the actor on every packet, which adds latency. v1 trade-off:
    // disable is best-effort via consumer-side filtering. We expose the set so
    // a consumer can drop filtered events itself.
    public func disabledDevices() -> Set<String> {
        disabledDeviceIDs
    }

    // MARK: Static helpers

    private static func enumerateDevices() -> [MIDIDevice] {
        let count = MIDIGetNumberOfSources()
        var devices: [MIDIDevice] = []
        devices.reserveCapacity(count)

        for i in 0..<count {
            let endpoint = MIDIGetSource(i)
            let id = uniqueID(of: endpoint) ?? "unknown-\(i)"
            let name = stringProperty(of: endpoint, key: kMIDIPropertyDisplayName)
                ?? stringProperty(of: endpoint, key: kMIDIPropertyName)
                ?? "Unknown MIDI Source"
            let offline = integerProperty(of: endpoint, key: kMIDIPropertyOffline) ?? 0
            devices.append(
                MIDIDevice(
                    id: id,
                    name: name,
                    isOnline: offline == 0
                )
            )
        }
        return devices
    }

    private static func uniqueID(of endpoint: MIDIEndpointRef) -> String? {
        var uid: Int32 = 0
        let status = MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &uid)
        guard status == noErr else { return nil }
        return String(uid)
    }

    private static func stringProperty(of endpoint: MIDIEndpointRef, key: CFString) -> String? {
        var result: Unmanaged<CFString>?
        let status = MIDIObjectGetStringProperty(endpoint, key, &result)
        guard status == noErr, let cf = result?.takeRetainedValue() else { return nil }
        return cf as String
    }

    private static func integerProperty(of endpoint: MIDIEndpointRef, key: CFString) -> Int32? {
        var value: Int32 = 0
        let status = MIDIObjectGetIntegerProperty(endpoint, key, &value)
        guard status == noErr else { return nil }
        return value
    }
}

extension MIDIPacket {
    fileprivate func bytes() -> [UInt8] {
        let length = Int(self.length)
        guard length > 0 else { return [] }
        return withUnsafeBytes(of: self.data) { rawBuffer in
            let base = rawBuffer.bindMemory(to: UInt8.self)
            return (0..<length).map { base[$0] }
        }
    }
}
