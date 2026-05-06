import Foundation
import ClassroomTheory

public struct HistoryEntry: Sendable, Hashable, Identifiable {
    public let id: UUID
    public let label: String
    public let timestamp: Date

    public init(label: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.label = label
        self.timestamp = timestamp
    }
}
