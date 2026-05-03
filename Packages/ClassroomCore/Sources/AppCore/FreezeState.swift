public struct FreezeState: Sendable, Equatable {
    public var capsLockFrozen: Bool
    public var pedalFrozen: Bool

    public init(capsLockFrozen: Bool = false, pedalFrozen: Bool = false) {
        self.capsLockFrozen = capsLockFrozen
        self.pedalFrozen = pedalFrozen
    }

    public var isFrozen: Bool { capsLockFrozen || pedalFrozen }
}
