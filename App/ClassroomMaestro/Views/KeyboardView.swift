import SwiftUI
import MusicRendering
import AppCore

public struct KeyboardView: View {
    public let pressedMIDI: Set<Int>
    public let staccatoMIDI: Set<Int>
    public let handPosition: HandPosition?
    public let lowMIDI: Int
    public let highMIDI: Int
    public let pressedColor: Color
    public let isHidden: Bool

    public init(
        pressedMIDI: Set<Int> = [],
        staccatoMIDI: Set<Int> = [],
        handPosition: HandPosition? = nil,
        lowMIDI: Int = 48,
        highMIDI: Int = 84,
        pressedColor: Color = .accentColor,
        isHidden: Bool = false
    ) {
        self.pressedMIDI = pressedMIDI
        self.staccatoMIDI = staccatoMIDI
        self.handPosition = handPosition
        self.lowMIDI = lowMIDI
        self.highMIDI = highMIDI
        self.pressedColor = pressedColor
        self.isHidden = isHidden
    }

    public var body: some View {
        if isHidden {
            emptyPlaceholder
        } else {
            GeometryReader { proxy in
                let availableWidth = proxy.size.width
                let availableHeight = proxy.size.height
                let intrinsicWidth = computedKeyboardWidth(forHeight: availableHeight)
                let needsScroll = intrinsicWidth > availableWidth

                if needsScroll {
                    ScrollView(.horizontal, showsIndicators: false) {
                        keyboardCanvas(width: intrinsicWidth, height: availableHeight)
                            .frame(width: intrinsicWidth, height: availableHeight)
                    }
                } else {
                    keyboardCanvas(width: availableWidth, height: availableHeight)
                }
            }
            .frame(minHeight: 80)
        }
    }

    // White-key aspect ratio: ~1:5 (height:width) for a tighter on-screen
    // appearance than the real-world ~1:6.4 ratio.
    private func computedKeyboardWidth(forHeight height: CGFloat) -> CGFloat {
        let whiteCount = KeyboardLayout.whiteKeyCount(from: lowMIDI, to: highMIDI)
        let whiteWidth = max(20, height / 5)
        return CGFloat(whiteCount) * whiteWidth
    }

    @ViewBuilder
    private func keyboardCanvas(width: CGFloat, height: CGFloat) -> some View {
        Canvas(rendersAsynchronously: false) { context, size in
            drawKeyboard(in: &context, size: size)
        }
        .frame(width: width, height: height)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.primary.opacity(0.3), lineWidth: 1)
        )
        .animation(.easeOut(duration: 0.08), value: pressedMIDI)
        .animation(.easeOut(duration: 0.08), value: staccatoMIDI)
    }

    private func drawKeyboard(in context: inout GraphicsContext, size: CGSize) {
        let totalWidth = size.width
        let totalHeight = size.height

        for midi in lowMIDI...highMIDI {
            guard !KeyboardLayout.isBlackKey(midi) else { continue }
            let rect = KeyboardLayout.keyRect(
                for: midi,
                lowMIDI: lowMIDI,
                highMIDI: highMIDI,
                totalWidth: totalWidth,
                totalHeight: totalHeight
            )
            let isPressed = pressedMIDI.contains(midi)
            let isStaccato = staccatoMIDI.contains(midi)

            let fill: Color
            if isPressed {
                fill = pressedColor
            } else if isStaccato {
                fill = pressedColor.opacity(0.5)
            } else {
                fill = Color(white: 0.98)
            }
            context.fill(Path(rect), with: .color(fill))
            context.stroke(Path(rect), with: .color(.primary.opacity(0.25)), lineWidth: 0.5)
        }

        for midi in lowMIDI...highMIDI {
            guard KeyboardLayout.isBlackKey(midi) else { continue }
            let rect = KeyboardLayout.keyRect(
                for: midi,
                lowMIDI: lowMIDI,
                highMIDI: highMIDI,
                totalWidth: totalWidth,
                totalHeight: totalHeight
            )
            let isPressed = pressedMIDI.contains(midi)
            let isStaccato = staccatoMIDI.contains(midi)

            let fill: Color
            if isPressed {
                fill = pressedColor
            } else if isStaccato {
                fill = pressedColor.opacity(0.5)
            } else {
                fill = Color(white: 0.12)
            }
            context.fill(Path(rect), with: .color(fill))
            context.stroke(Path(rect), with: .color(.primary.opacity(0.4)), lineWidth: 0.5)
        }

        if let handPosition,
           let bracketRect = KeyboardLayout.handPositionBracket(
                startMIDI: handPosition.startMIDI,
                fingerCount: handPosition.fingerCount,
                lowMIDI: lowMIDI,
                highMIDI: highMIDI,
                totalWidth: totalWidth,
                totalHeight: totalHeight
           )
        {
            drawHandBracket(in: &context, rect: bracketRect, fingerCount: handPosition.fingerCount)
        }

        drawOctaveLabels(in: &context, size: size)
    }

    private func drawHandBracket(in context: inout GraphicsContext, rect: CGRect, fingerCount: Int) {
        let strokeColor = Color.orange.opacity(0.85)
        let fillColor = Color.orange.opacity(0.10)

        let shape = RoundedRectangle(cornerRadius: 4)
        let path = shape.path(in: rect)
        context.fill(path, with: .color(fillColor))
        context.stroke(path, with: .color(strokeColor), lineWidth: 2)

        let whiteWidth = rect.width / CGFloat(fingerCount)
        for i in 0..<fingerCount {
            let centerX = rect.minX + whiteWidth * (CGFloat(i) + 0.5)
            let label = "\(i + 1)"
            let txt = context.resolve(
                Text(label)
                    .font(.system(size: min(14, rect.height * 0.12), weight: .semibold))
                    .foregroundColor(.orange)
            )
            context.draw(txt, at: CGPoint(x: centerX, y: rect.minY + 8), anchor: .top)
        }
    }

    private func drawOctaveLabels(in context: inout GraphicsContext, size: CGSize) {
        for midi in lowMIDI...highMIDI {
            guard midi % 12 == 0 else { continue }
            let rect = KeyboardLayout.keyRect(
                for: midi,
                lowMIDI: lowMIDI,
                highMIDI: highMIDI,
                totalWidth: size.width,
                totalHeight: size.height
            )
            let octave = midi / 12 - 1
            let label = "C\(octave)"
            // 0.45 keeps the C-label comfortably narrower than the white key.
            let fontSize = min(11, rect.width * 0.45)
            guard fontSize >= 8 else { return }
            let txt = context.resolve(
                Text(label)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(.secondary)
            )
            context.draw(txt, at: CGPoint(x: rect.midX, y: rect.maxY - 10), anchor: .bottom)
        }
    }

    private var emptyPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary.opacity(0.08))
            .overlay(
                Text("Keyboard hidden")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .medium))
            )
            .frame(minHeight: 80)
    }
}

#Preview("Empty 3-octave") {
    KeyboardView()
        .frame(width: 600, height: 120)
        .padding()
}

#Preview("C major triad pressed") {
    KeyboardView(pressedMIDI: [60, 64, 67])
        .frame(width: 600, height: 120)
        .padding()
}

#Preview("Staccato + pressed mix") {
    KeyboardView(
        pressedMIDI: [60, 64],
        staccatoMIDI: [67, 70]
    )
    .frame(width: 600, height: 120)
    .padding()
}

#Preview("Hand position C major") {
    KeyboardView(
        pressedMIDI: [60],
        handPosition: HandPosition(startMIDI: 60, fingerCount: 5)
    )
    .frame(width: 600, height: 120)
    .padding()
}

#Preview("Hidden (quiz mode)") {
    KeyboardView(pressedMIDI: [60, 64, 67], isHidden: true)
        .frame(width: 600, height: 120)
        .padding()
}

#Preview("Full piano (scrollable)") {
    KeyboardView(
        pressedMIDI: [21, 60, 108],
        lowMIDI: 21,
        highMIDI: 108
    )
    .frame(width: 600, height: 120)
    .padding()
}

#Preview("Custom color (red, dark mode)") {
    KeyboardView(
        pressedMIDI: [60, 64, 67],
        pressedColor: .red
    )
    .frame(width: 600, height: 120)
    .padding()
    .preferredColorScheme(.dark)
}
