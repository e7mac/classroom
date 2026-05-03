import Foundation
import Testing
@testable import AudioInput

@Suite
struct MIDIDeviceTests {
    @Test func devicesWithSameIdentifierAreEqual() {
        let a = MIDIDevice(id: "uid-1", name: "Studiologic SL88", isOnline: true)
        let b = MIDIDevice(id: "uid-1", name: "Studiologic SL88", isOnline: true)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test func identifiableConformanceUsesId() {
        let device = MIDIDevice(id: "uid-42", name: "Test", isOnline: false)
        #expect(device.id == "uid-42")
    }

    @Test func differentNamesProduceDifferentDevices() {
        let a = MIDIDevice(id: "uid-1", name: "A", isOnline: true)
        let b = MIDIDevice(id: "uid-1", name: "B", isOnline: true)
        #expect(a != b)
    }
}
