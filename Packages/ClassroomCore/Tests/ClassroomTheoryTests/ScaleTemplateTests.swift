import Testing
 import ClassroomTheory

@Suite
struct ScaleTemplateTests {
    @Test func atLeastThirtyTemplates() {
        #expect(ScaleTemplate.all.count >= 30)
    }

    @Test func majorTemplateIntervals() {
        let major = ScaleTemplate.all.first { $0.name == "Major" }
        #expect(major != nil)
        #expect(major?.intervalsFromTonic == [0, 2, 4, 5, 7, 9, 11])
    }

    @Test func allTemplatesStartWithZero() {
        for template in ScaleTemplate.all {
            #expect(template.intervalsFromTonic.first == 0, "\(template.name) should start with 0")
        }
    }

    @Test func allTemplatesAreStrictlyAscending() {
        for template in ScaleTemplate.all {
            let intervals = template.intervalsFromTonic
            for i in 1..<intervals.count {
                #expect(intervals[i] > intervals[i - 1], "\(template.name) intervals not strictly ascending at index \(i)")
            }
        }
    }

    @Test func allTemplatesWithinOneOctave() {
        for template in ScaleTemplate.all {
            for offset in template.intervalsFromTonic {
                #expect(offset >= 0 && offset <= 11, "\(template.name) has out-of-range offset \(offset)")
            }
        }
    }

    @Test func wholeToneHasSixNotes() {
        let wholeTone = ScaleTemplate.all.first { $0.name == "Whole Tone" }
        #expect(wholeTone?.intervalsFromTonic.count == 6)
    }

    @Test func chromaticHasTwelveNotes() {
        let chromatic = ScaleTemplate.all.first { $0.name == "Chromatic" }
        #expect(chromatic?.intervalsFromTonic.count == 12)
    }

    @Test func ionianAndMajorAreDuplicates() {
        let major = ScaleTemplate.all.first { $0.name == "Major" }
        let ionian = ScaleTemplate.all.first { $0.name == "Ionian" }
        #expect(major?.intervalsFromTonic == ionian?.intervalsFromTonic)
    }
}
