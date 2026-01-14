//
//  SettingsView.swift
//  transcriber
//
//  Settings/preferences view
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var permissionsManager: PermissionsManager
    
    var body: some View {
        TabView {
            GeneralSettingsView(permissionsManager: permissionsManager)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @ObservedObject var permissionsManager: PermissionsManager
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("transcriptionMode") private var transcriptionMode: String = TranscriptionMode.full.rawValue
    
    var body: some View {
        Form {
            Section("Transcription Mode") {
                Picker("Mode", selection: $transcriptionMode) {
                    ForEach(TranscriptionMode.allCases) { mode in
                        VStack(alignment: .leading) {
                            Text(mode.displayName)
                        }
                        .tag(mode.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)
                
                Text(currentModeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Permissions") {
                HStack {
                    Image(systemName: permissionsManager.hasMicrophonePermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(permissionsManager.hasMicrophonePermission ? .green : .red)
                    Text("Microphone")
                    Spacer()
                    if !permissionsManager.hasMicrophonePermission {
                        Button("Grant") {
                            Task {
                                await permissionsManager.requestMicrophonePermission()
                            }
                        }
                    }
                }
                
                HStack {
                    Image(systemName: permissionsManager.hasAccessibilityPermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(permissionsManager.hasAccessibilityPermission ? .green : .red)
                    Text("Accessibility")
                    Spacer()
                    if !permissionsManager.hasAccessibilityPermission {
                        Button("Open Settings") {
                            permissionsManager.openAccessibilitySettings()
                        }
                    }
                }
                
                Button("Refresh Permissions") {
                    permissionsManager.refreshPermissions()
                }
            }
            
            Section("Startup") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private var currentModeDescription: String {
        TranscriptionMode(rawValue: transcriptionMode)?.description ?? ""
    }
}

// MARK: - Shortcuts Settings

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section("Activation Hotkey") {
                HStack {
                    Image(systemName: "option")
                        .font(.title2)
                    Text("Right Option Key")
                        .font(.headline)
                }
                
                Text("Hold the RIGHT ⌥ key to start recording")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("How it works") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Press and hold the Right ⌥ key")
                    Text("2. Speak naturally")
                    Text("3. Release to paste transcription")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("Transcriber")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Voice-to-Text for macOS")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.horizontal, 40)
            
            VStack(spacing: 4) {
                Text("Powered by Parakeet TDT v3")
                    .font(.caption)
                Text("FluidAudio SDK")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    SettingsView(
        appState: AppState(),
        permissionsManager: PermissionsManager()
    )
}
