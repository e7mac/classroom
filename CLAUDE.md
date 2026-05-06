# ClassroomMaestro

Native macOS/iOS SwiftUI app for music teachers: real-time staff/keyboard display and music theory analysis from MIDI or acoustic piano input, with floating always-on-top widgets for use over Zoom/Meet.

## Building

```bash
# Regenerate Xcode project after editing project.yml or adding files
cd App && xcodegen generate

# Open workspace (includes both app and package)
open ClassroomMaestro.xcworkspace

# Run package tests (no Xcode needed)
cd Packages/ClassroomCore && swift test
```

Requirements: Xcode 26+, Swift 6.0, `brew install xcodegen`.

**CLI builds via `xcodebuild` are unreliable** — use Xcode for building and running the app. Package tests (`swift test`) work fine from CLI.

## Project Layout

```
classroom/
├── ClassroomMaestro.xcworkspace    Open this in Xcode
├── App/
│   ├── project.yml                 XcodeGen spec — edit this, not the .xcodeproj
│   └── ClassroomMaestro/
│       ├── Views/                  SwiftUI views (staff, keyboard, analysis, widgets)
│       ├── Widgets/                macOS floating window system
│       ├── State/                  AppStateContainer (bridges engines → SwiftUI)
│       └── Input/                  Keyboard shortcuts
└── Packages/ClassroomCore/         Swift Package — testable core (no UIKit/AppKit)
    ├── Sources/
    │   ├── MusicTheory/            Pure theory primitives + engine
    │   ├── MusicRendering/         Layout math (no SwiftUI/UIKit)
    │   ├── AudioInput/             CoreMIDI + AVAudioEngine + YIN pitch detection
    │   └── AppCore/                AppState + display modes + analysis
    └── Tests/                      25 test files, Swift Testing framework
```

## Architecture

### Layer model
```
MusicTheory (pure, no deps)
    ↓
MusicRendering + AudioInput (depend on MusicTheory only)
    ↓
AppCore (depends on all three — state management)
    ↓
App (SwiftUI + AppKit, macOS/iOS UI + widgets)
```

### Concurrency (Swift 6.0 strict)
- `MIDIEngine` and `AcousticPitchDetector` are **actors** that emit `AsyncStream<NoteEvent>`
- `AppState` and `AppStateContainer` are `@MainActor` classes
- Event flow: `for await event in engine.events { appState.handle(event) }`
- Never call actor methods from `@MainActor` contexts synchronously — use `await`

### State management
- `AppStateContainer` (in `AppStateBindings.swift`) owns the audio engines and exposes them to SwiftUI via `@StateObject`
- `AppState` (`AppCore`) receives `NoteEvent`s and recomputes the display (active notes, chord, scale, analysis) based on the current `DisplayMode`
- Views bind directly to `@Published` properties — no separate ViewModel layer

### Widget system (macOS only)
- `WidgetManager` opens/closes `NSWindow`s wrapping SwiftUI content; persists frames to UserDefaults
- `WidgetWindowController` controls transparency, click-through, and always-on-top level
- `StageMode` hides chrome and snaps to grid for clean screen recording
- Conditional compilation: `#if os(macOS)` gates the entire widget stack

## Key Types

| Type | File | Role |
|---|---|---|
| `MusicTheoryEngine` | `MusicTheory/MusicTheoryEngine.swift` | Facade: `spell()`, `identifyChord()`, `identifyScales()`, `romanNumeral()` |
| `AppState` | `AppCore/AppState.swift` | `@MainActor` — ingests `NoteEvent`, drives all display state |
| `DisplayMode` | `AppCore/DisplayMode.swift` | Enum: singleNote, interval, chord, scale, chordProgression, handPosition |
| `MIDIEngine` | `AudioInput/MIDIEngine.swift` | Actor wrapping CoreMIDI; `AsyncStream<NoteEvent>` |
| `AcousticPitchDetector` | `AudioInput/AcousticPitchDetector.swift` | Actor; AVAudioEngine tap → YIN → NoteEvent stream |
| `StaffLayout` | `MusicRendering/StaffLayout.swift` | Coordinate math for note placement on staff |
| `WidgetManager` | `Widgets/WidgetManager.swift` | Open/close/persist floating NSWindows |

## Adding Source Files

After adding a `.swift` file, regenerate the project:
```bash
cd App && xcodegen generate
```
The Ruby scripts in `App/ClassroomMaestro/` (if present) can help register files across targets.

## Testing

Tests live in `Packages/ClassroomCore/Tests/` and use **Swift Testing** (`@Suite`, `@Test`, `#expect()`).

```bash
cd Packages/ClassroomCore && swift test

# Single test suite
swift test --filter MusicTheoryTests
```

Coverage: MusicTheory (10 files), AudioInput (7), MusicRendering (4), AppCore (4).

Tests must not import AppKit/UIKit — keep the package layer free of platform UI dependencies.

## Key Constraints

- **Microphone permission** required for acoustic pitch detection — declared in `Info.plist`, requested at runtime
- **App sandbox** is enabled; only audio input and USB device entitlements are granted
- **Bravura.otf** (SMuFL) is the music notation font — use `BravuraFont.swift` glyph constants, not Unicode literals
- `MusicRendering` must stay free of SwiftUI/UIKit imports (layout math only) so tests can run anywhere
- Swift 6.0 strict concurrency is enforced across all targets — avoid `nonisolated(unsafe)` hacks
