//
//  TranscriptionManager.swift
//  transcriber
//
//  Handles speech-to-text transcription using FluidAudio/Parakeet models
//

import Foundation
import FluidAudio

/// Manages transcription using CoreML-optimized Parakeet TDT models
@MainActor
final class TranscriptionManager: ObservableObject {
    // MARK: - Properties
    
    private var asrManager: AsrManager?
    private var models: AsrModels?
    
    /// Whether models are loaded
    @Published private(set) var isLoaded: Bool = false
    
    /// Loading progress (0.0 - 1.0)
    @Published private(set) var loadingProgress: Double = 0.0
    
    /// Loading status message
    @Published private(set) var statusMessage: String = ""
    
    /// Track already typed text for streaming mode
    private var lastTypedText: String = ""
    
    // MARK: - Model Loading
    
    /// Load the Parakeet TDT v3 models
    func loadModels() async throws {
        statusMessage = "Downloading models..."
        loadingProgress = 0.1
        
        // Download and load models
        // Using v3 for multilingual support (25 European languages)
        models = try await AsrModels.downloadAndLoad(version: .v3)
        
        loadingProgress = 0.7
        statusMessage = "Initializing ASR engine..."
        
        // Initialize ASR manager
        asrManager = AsrManager(config: .default)
        try await asrManager?.initialize(models: models!)
        
        loadingProgress = 1.0
        statusMessage = "Ready"
        isLoaded = true
    }
    
    // MARK: - Transcription
    
    /// Transcribe audio samples to text (batch mode)
    /// - Parameter samples: Audio samples (16kHz mono Float32)
    /// - Returns: Transcribed text
    func transcribe(_ samples: [Float]) async throws -> String {
        guard let asrManager = asrManager, isLoaded else {
            throw TranscriptionError.modelNotLoaded
        }
        
        guard !samples.isEmpty else {
            throw TranscriptionError.emptyAudio
        }
        
        statusMessage = "Transcribing..."
        lastTypedText = ""
        
        let result = try await asrManager.transcribe(samples)
        
        statusMessage = "Ready"
        return result.text
    }
    
    /// Transcribe audio samples with streaming partial results
    /// - Parameters:
    ///   - samples: Audio samples (16kHz mono Float32)
    ///   - chunkDuration: Duration of each chunk in seconds (e.g., 2.0)
    ///   - onChunk: Callback for each transcribed chunk (newText, fullText)
    /// - Returns: Full transcribed text
    func transcribeStreaming(
        _ samples: [Float],
        chunkDuration: Double = 2.0,
        onChunk: @escaping (String, String) -> Void
    ) async throws -> String {
        guard let asrManager = asrManager, isLoaded else {
            throw TranscriptionError.modelNotLoaded
        }
        
        guard !samples.isEmpty else {
            throw TranscriptionError.emptyAudio
        }
        
        statusMessage = "Transcribing..."
        lastTypedText = ""
        
        let sampleRate = 16000.0
        let chunkSize = Int(chunkDuration * sampleRate)
        var fullText = ""
        var previousText = ""
        
        // Process in chunks
        var offset = 0
        while offset < samples.count {
            let endOffset = min(offset + chunkSize, samples.count)
            let chunk = Array(samples[0..<endOffset]) // Always include all audio up to this point
            
            // Transcribe accumulated audio
            let result = try await asrManager.transcribe(chunk)
            let currentText = result.text
            
            // Find the new text that wasn't in previous result
            if currentText.count > previousText.count {
                let newText = String(currentText.dropFirst(previousText.count))
                onChunk(newText.trimmingCharacters(in: .whitespaces), currentText)
            }
            
            fullText = currentText
            previousText = currentText
            offset = endOffset
        }
        
        statusMessage = "Ready"
        return fullText
    }
    
    /// Reset streaming state
    func resetStreamingState() {
        lastTypedText = ""
    }
    
    /// Transcribe audio file
    /// - Parameter url: URL to audio file
    /// - Returns: Transcribed text
    func transcribeFile(at url: URL) async throws -> String {
        guard let asrManager = asrManager, isLoaded else {
            throw TranscriptionError.modelNotLoaded
        }
        
        statusMessage = "Transcribing file..."
        
        let result = try await asrManager.transcribe(url)
        
        statusMessage = "Ready"
        return result.text
    }
}

// MARK: - Errors

enum TranscriptionError: LocalizedError {
    case modelNotLoaded
    case emptyAudio
    case transcriptionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Models not loaded. Please wait for initialization."
        case .emptyAudio:
            return "No audio to transcribe"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        }
    }
}
