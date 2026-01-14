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
        } label: {
            Label {
                Text("Transcriber")
            } icon: {
                Image(systemName: menuBarIcon)
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
            return "mic"
        }
    }
}
