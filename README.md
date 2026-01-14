# Logix Transcriber

🎤 **macOS Voice-to-Text** — Local speech transcription powered by Neural Engine

## Features

- **Hold-to-Dictate**: Hold Right ⌥ Option → speak → release → text is inserted
- **File Transcription**: Drag & drop audio files (MP3, WAV, M4A, FLAC, OGG) to transcribe
- **100% Local**: Parakeet TDT v3 model runs on-device (Neural Engine)
- **Two Modes**:
  - **Streaming**: Words appear in real-time while you speak
  - **Full**: Text is pasted all at once after you release
- **Menu Bar App**: Lives in the system tray, stays out of your way

## Requirements

- macOS 14.0+
- Apple Silicon (M1/M2/M3/M4)
- ~500MB for models (downloaded automatically on first run)

## Installation

1. Open `transcriber.xcodeproj` in Xcode
2. Build & Run (⌘R)
3. Grant Microphone and Accessibility permissions when prompted

## Usage

### Voice Dictation
1. Click 🎤 in the menu bar
2. Hold the **Right ⌥ Option** key for >1 second
3. Speak naturally
4. Release — text appears in the active input field

### File Transcription
1. Click 🎤 in the menu bar → **Transcribe File...** (⌘O)
2. Drag & drop audio file or click "Select File..."
3. Wait for transcription (progress bar shows status)
4. Copy result to clipboard

## Tech Stack

- **FluidAudio SDK** — Parakeet TDT v3 ASR models
- **SwiftUI** — Native macOS UI
- **AVFoundation** — Audio capture
- **CoreML + Neural Engine** — Model inference

## Changelog

### v1.1.0
- ✨ File transcription with drag & drop
- 📊 Progress bar with time estimate
- 🎵 Support for MP3, WAV, M4A, AIFF, FLAC, OGG

### v1.0.0
- 🎉 Initial release
- 🎤 Hold-to-dictate with Right Option key
- ⚡ Streaming and Full transcription modes
- 📋 Auto-paste to active input field

## License

MIT
