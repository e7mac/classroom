# ClassroomMaestro

A native macOS SwiftUI app for music teachers — real-time staff/keyboard display and music theory analysis from MIDI or acoustic-piano input, with always-on-top floating widgets for use over Zoom/Meet.

## Layout

```
classroom-master/
├── ClassroomMaestro.xcworkspace    Open this in Xcode
├── App/
│   ├── project.yml                  xcodegen spec for the app target
│   └── ClassroomMaestro/            App sources (regenerate project from project.yml)
└── Packages/
    └── ClassroomCore/               Swift Package — testable core
        ├── MusicTheory/             Pure theory primitives + engine
        ├── MusicRendering/          Layout math (no SwiftUI imports)
        ├── AudioInput/              CoreMIDI + AVAudioEngine + YIN/CREPE
        └── AppCore/                 AppState + display modes
```

## Requirements
- macOS 14+
- Xcode 26+ (Swift 6.0)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Building

### Open in Xcode
```sh
open ClassroomMaestro.xcworkspace
```

### Regenerate the Xcode project
After editing `App/project.yml` or adding new source files:
```sh
cd App && xcodegen generate
```

### Run package tests from CLI
```sh
cd Packages/ClassroomCore && swift test
```

## Status

Milestone 1 (project skeleton) — complete.
See `~/.claude/projects/-Users-mayank10-Developer-classroom-master/memory/project_overview.md` for the architecture plan and milestone roadmap.
