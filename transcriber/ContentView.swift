//
//  ContentView.swift
//  transcriber
//
//  Main content view (used for onboarding/settings window)
//

import SwiftUI

struct ContentView: View {
    @StateObject private var permissionsManager = PermissionsManager()
    
    var body: some View {
        VStack(spacing: 20) {
            // App icon
            Image(systemName: "mic.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Transcriber")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Voice-to-Text with Parakeet TDT")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.vertical)
            
            // Permissions status
            VStack(alignment: .leading, spacing: 12) {
                PermissionRow(
                    title: "Microphone",
                    description: "Required for voice input",
                    isGranted: permissionsManager.hasMicrophonePermission,
                    action: {
                        Task {
                            await permissionsManager.requestMicrophonePermission()
                        }
                    }
                )
                
                PermissionRow(
                    title: "Accessibility",
                    description: "Required for global hotkey & text pasting",
                    isGranted: permissionsManager.hasAccessibilityPermission,
                    action: {
                        permissionsManager.requestAccessibilityPermission()
                    }
                )
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
            
            Spacer()
            
            // Instructions
            VStack(spacing: 8) {
                Text("How to use:")
                    .font(.headline)
                
                Text("1. Grant permissions above")
                Text("2. Press ⌥ Space to start recording")
                Text("3. Speak naturally")
                Text("4. Release to paste transcription")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(width: 400, height: 500)
        .onAppear {
            permissionsManager.refreshPermissions()
        }
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isGranted ? .green : .red)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isGranted {
                Button("Grant") {
                    action()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
