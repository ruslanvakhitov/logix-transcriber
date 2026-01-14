//
//  AppState.swift
//  transcriber
//
//  Central state management for the voice transcription app
//

import SwiftUI
import Combine

/// Represents the current state of the transcription workflow
enum TranscriptionState: Equatable {
    case idle
    case loading       // Model loading
    case listening     // Recording audio
    case processing    // Transcribing
    case pasting       // Injecting text
    case error(String) // Error state
    
    static func == (lhs: TranscriptionState, rhs: TranscriptionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.listening, .listening),
             (.processing, .processing), (.pasting, .pasting):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

/// Transcription output mode
enum TranscriptionMode: String, CaseIterable, Identifiable {
    case streaming = "streaming"  // Type words as they're recognized
    case full = "full"            // Paste complete text at end
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .streaming: return "Streaming (real-time)"
        case .full: return "Full (after release)"
        }
    }
    
    var description: String {
        switch self {
        case .streaming: return "Words appear as you speak"
        case .full: return "Text pasted when you release"
        }
    }
}

/// Central state management class for the app
@MainActor
final class AppState: ObservableObject {
    // MARK: - Published Properties
    
    /// Current transcription workflow state
    @Published var state: TranscriptionState = .idle
    
    /// Current/partial transcription text
    @Published var currentTranscription: String = ""
    
    /// Whether models are loaded and ready
    @Published var isModelLoaded: Bool = false
    
    /// Model download/loading progress (0.0 - 1.0)
    @Published var loadingProgress: Double = 0.0
    
    /// Loading status message
    @Published var loadingMessage: String = ""
    
    /// Whether the listening overlay is visible
    @Published var showListeningOverlay: Bool = false
    
    /// Whether permissions have been granted
    @Published var hasMicrophonePermission: Bool = false
    @Published var hasAccessibilityPermission: Bool = false
    
    // MARK: - Transcription History
    
    /// Recent transcription entries (last 50)
    @Published var transcriptionHistory: [TranscriptionEntry] = []
    
    // MARK: - Computed Properties
    
    var isReady: Bool {
        isModelLoaded && hasMicrophonePermission && hasAccessibilityPermission
    }
    
    var statusText: String {
        switch state {
        case .idle:
            return "Ready"
        case .loading:
            return loadingMessage
        case .listening:
            return "Listening..."
        case .processing:
            return "Processing..."
        case .pasting:
            return "Pasting..."
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    // MARK: - Methods
    
    func addToHistory(_ text: String, duration: TimeInterval) {
        let entry = TranscriptionEntry(
            id: UUID(),
            text: text,
            timestamp: Date(),
            duration: duration
        )
        transcriptionHistory.insert(entry, at: 0)
        
        // Keep only last 50 entries
        if transcriptionHistory.count > 50 {
            transcriptionHistory = Array(transcriptionHistory.prefix(50))
        }
    }
    
    func clearCurrentTranscription() {
        currentTranscription = ""
    }
}

/// Represents a single transcription entry in history
struct TranscriptionEntry: Identifiable, Codable {
    let id: UUID
    let text: String
    let timestamp: Date
    let duration: TimeInterval
    
    var formattedDuration: String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
    
    var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
