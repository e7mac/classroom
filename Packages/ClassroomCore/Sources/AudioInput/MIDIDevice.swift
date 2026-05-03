import Foundation

public struct MIDIDevice: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let isOnline: Bool

    public init(id: String, name: String, isOnline: Bool) {
        self.id = id
        self.name = name
        self.isOnline = isOnline
    }
}
