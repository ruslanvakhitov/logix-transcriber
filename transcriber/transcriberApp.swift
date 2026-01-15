//
//  transcriberApp.swift
//  transcriber
//
//  Menu bar voice transcription app using Parakeet TDT
//

import SwiftUI

@main
struct transcriberApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var audioManager = AudioManager()
    @StateObject private var transcriptionManager = TranscriptionManager()
    @StateObject private var hotkeyManager = HotkeyManager()
    @StateObject private var permissionsManager = PermissionsManager()
    
    init() {
        // Models will be loaded once transcriptionManager is initialized
        // We need to trigger loading after the StateObjects are created
    }
    
    var body: some Scene {
        // Menu bar app
        MenuBarExtra {
            MenuBarView(
                appState: appState,
                audioManager: audioManager,
                transcriptionManager: transcriptionManager,
                hotkeyManager: hotkeyManager,
                permissionsManager: permissionsManager
            )
            .task {
                // Load models at app startup, not when menu opens
                await loadModelsIfNeeded()
            }
        } label: {
            Label {
                Text("Transcriber")
            } icon: {
                if appState.state == .idle {
                    Image("MenuBarIcon")
                } else {
                    Image(systemName: menuBarIcon)
                }
            }
        }
        .menuBarExtraStyle(.window)
        
        // Settings window (use Window instead of Settings for menu bar apps)
        Window("Settings", id: "settings") {
            SettingsView(
                appState: appState,
                permissionsManager: permissionsManager
            )
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 400)
        
        // File Transcription window
        Window("Transcribe File", id: "file-transcription") {
            FileTranscriptionView(transcriptionManager: transcriptionManager)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 400)
    }
    
    private var menuBarIcon: String {
        switch appState.state {
        case .listening:
            return "mic.fill"
        case .processing:
            return "waveform"
        case .loading:
            return "arrow.down.circle"
        case .error:
            return "exclamationmark.triangle"
        default:
            return "mic" // Fallback, though we use Image("MenuBarIcon") for idle
        }
    }
    
    /// Load models automatically at app startup
    @MainActor
    private func loadModelsIfNeeded() async {
        // Only load if microphone permission is granted and models not already loaded
        guard permissionsManager.hasMicrophonePermission else { return }
        guard !transcriptionManager.isLoaded else { return }
        
        do {
            try await transcriptionManager.loadModels()
            appState.isModelLoaded = true
        } catch {
            appState.state = .error(error.localizedDescription)
        }
    }
}
