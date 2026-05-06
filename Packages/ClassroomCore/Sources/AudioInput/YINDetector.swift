@_exported import AudioEngine

// YINDetector and PitchDetectionAlgorithm are re-exported from
// MusicCore.AudioEngine. The previous local implementations were
// promoted into MusicCore (commit `22b40b0` on github.com/e7mac/MusicCore`)
// — keeping a single shared algorithm avoids drift and lets RET /
// Rhythmist pick up improvements without a Classroom-side change.
