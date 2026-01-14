# Logix Transcriber

🎤 **macOS Voice-to-Text** — Local speech transcription powered by Neural Engine

## Features

- **Hold-to-Dictate**: Hold Right ⌥ Option → speak → release → text is inserted
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

1. Click 🎤 in the menu bar
2. Hold the **Right ⌥ Option** key for >1 second
3. Speak naturally
4. Release — text appears in the active input field

## Tech Stack

- **FluidAudio SDK** — Parakeet TDT v3 ASR models
- **SwiftUI** — Native macOS UI
- **AVFoundation** — Audio capture
- **CoreML + Neural Engine** — Model inference

## Settings

- **Transcription Mode**: Streaming (real-time) / Full (after release)
- **Permissions**: Microphone, Accessibility

## License

MIT
