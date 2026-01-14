//
//  ListeningOverlayView.swift
//  transcriber
//
//  Floating overlay shown during voice recording
//

import SwiftUI

struct ListeningOverlayView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var audioManager: AudioManager
    
    @State private var animationPhase: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Animated microphone icon
            ZStack {
                // Pulsing rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.red.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: 60 + CGFloat(index) * 20, height: 60 + CGFloat(index) * 20)
                        .scaleEffect(appState.state == .listening ? 1.0 + CGFloat(audioManager.audioLevel) * 0.3 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: audioManager.audioLevel)
                }
                
                // Center microphone
                Image(systemName: microphoneIcon)
                    .font(.system(size: 30))
                    .foregroundColor(microphoneColor)
            }
            
            // Status text
            Text(statusText)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Current transcription preview
            if !appState.currentTranscription.isEmpty {
                Text(appState.currentTranscription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Audio level indicator
            if appState.state == .listening {
                AudioLevelBar(level: audioManager.audioLevel)
                    .frame(height: 4)
                    .padding(.horizontal, 20)
            }
            
            // Hint text
            Text(hintText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(minWidth: 280, maxWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    
    private var microphoneIcon: String {
        switch appState.state {
        case .listening: return "mic.fill"
        case .processing: return "waveform"
        case .pasting: return "doc.on.clipboard.fill"
        default: return "mic"
        }
    }
    
    private var microphoneColor: Color {
        switch appState.state {
        case .listening: return .red
        case .processing: return .blue
        case .pasting: return .green
        default: return .primary
        }
    }
    
    private var statusText: String {
        switch appState.state {
        case .listening: return "Listening..."
        case .processing: return "Transcribing..."
        case .pasting: return "Pasting..."
        default: return "Ready"
        }
    }
    
    private var hintText: String {
        switch appState.state {
        case .listening: return "Release ⌥ Space to paste"
        case .processing: return "Please wait..."
        case .pasting: return "Done!"
        default: return "Hold ⌥ Space to start"
        }
    }
}

// MARK: - Audio Level Bar

struct AudioLevelBar: View {
    let level: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                
                // Level indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(levelColor)
                    .frame(width: geometry.size.width * CGFloat(level))
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
    }
    
    private var levelColor: Color {
        if level > 0.8 {
            return .red
        } else if level > 0.5 {
            return .orange
        } else {
            return .green
        }
    }
}

#Preview {
    ListeningOverlayView(
        appState: {
            let state = AppState()
            state.state = .listening
            state.currentTranscription = "Hello, this is a test transcription..."
            return state
        }(),
        audioManager: AudioManager()
    )
    .frame(width: 350, height: 250)
    .background(Color.gray)
}
