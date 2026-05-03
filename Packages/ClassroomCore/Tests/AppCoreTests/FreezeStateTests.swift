import Testing
@testable import AppCore

@Suite
struct FreezeStateTests {
    @Test func defaultIsNotFrozen() {
        let state = FreezeState()
        #expect(state.isFrozen == false)
    }

    @Test func capsLockAloneIsFrozen() {
        let state = FreezeState(capsLockFrozen: true, pedalFrozen: false)
        #expect(state.isFrozen == true)
    }

    @Test func pedalAloneIsFrozen() {
        let state = FreezeState(capsLockFrozen: false, pedalFrozen: true)
        #expect(state.isFrozen == true)
    }

    @Test func bothIsFrozen() {
        let state = FreezeState(capsLockFrozen: true, pedalFrozen: true)
        #expect(state.isFrozen == true)
    }
}
