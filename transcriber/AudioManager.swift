//
//  AudioManager.swift
//  transcriber
//
//  Handles microphone input capture using AVAudioEngine
//

import Foundation
import AVFoundation

/// Manages audio capture from the microphone
final class AudioManager: ObservableObject {
    // MARK: - Properties
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    
    /// Collected audio samples (16kHz mono Float32)
    private(set) var audioBuffer: [Float] = []
    
    /// Whether audio capture is active
    @Published private(set) var isCapturing: Bool = false
    
    /// Audio levels for visualization (0.0 - 1.0)
    @Published private(set) var audioLevel: Float = 0.0
    
    /// Recording start timestamp
    private var recordingStartTime: Date?
    
    /// Callback for streaming transcription - called periodically with accumulated samples
    var onAudioChunk: (([Float]) -> Void)?
    
    /// Interval for streaming audio chunks (in seconds)
    private let streamingChunkInterval: Double = 2.0
    
    /// Last time we sent audio chunk for streaming
    private var lastChunkTime: Date?
    
    // MARK: - Configuration
    
    /// Target sample rate for transcription (Parakeet expects 16kHz)
    private let targetSampleRate: Double = 16000.0
    
    // MARK: - Initialization
    
    init() {
        // Audio engine setup is deferred until first use
        // This avoids errors when microphone permission isn't granted yet
    }
    
    deinit {
        _ = stopCapture()
    }
    
    // MARK: - Setup
    
    private func setupAudioEngineIfNeeded() throws {
        guard audioEngine == nil else { return }
        
        // Check permission first
        guard checkMicrophonePermission() else {
            throw AudioManagerError.permissionDenied
        }
        
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        // Verify we have valid audio input
        guard let inputNode = inputNode else {
            throw AudioManagerError.noInputDevice
        }
        
        let format = inputNode.outputFormat(forBus: 0)
        print("AudioManager: Input format - \(format.sampleRate)Hz, \(format.channelCount) channel(s)")
    }
    
    // MARK: - Permission Handling
    
    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    /// Check if microphone permission is granted
    func checkMicrophonePermission() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
    
    // MARK: - Capture Control
    
    /// Start capturing audio from the microphone
    /// - Parameter streaming: If true, periodically calls onAudioChunk with accumulated audio
    func startCapture(streaming: Bool = false) throws {
        guard !isCapturing else { return }
        
        // Initialize audio engine if needed (deferred until first use)
        try setupAudioEngineIfNeeded()
        
        guard let audioEngine = audioEngine, let inputNode = inputNode else {
            throw AudioManagerError.engineNotInitialized
        }
        
        // Clear previous buffer
        audioBuffer.removeAll()
        recordingStartTime = Date()
        lastChunkTime = streaming ? Date() : nil
        
        // Get input format
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Create output format (16kHz mono)
        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioManagerError.formatCreationFailed
        }
        
        // Create converter if needed
        let converter = AVAudioConverter(from: inputFormat, to: outputFormat)
        
        // Install tap on input node
        let bufferSize: AVAudioFrameCount = 4096
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer, converter: converter, outputFormat: outputFormat, streaming: streaming)
        }
        
        // Start the engine
        audioEngine.prepare()
        try audioEngine.start()
        
        Task { @MainActor in
            self.isCapturing = true
        }
    }
    
    /// Stop capturing audio
    func stopCapture() -> (samples: [Float], duration: TimeInterval) {
        guard isCapturing else { return ([], 0) }
        
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        
        let duration: TimeInterval
        if let startTime = recordingStartTime {
            duration = Date().timeIntervalSince(startTime)
        } else {
            duration = 0
        }
        
        let samples = audioBuffer
        lastChunkTime = nil
        
        Task { @MainActor in
            self.isCapturing = false
            self.audioLevel = 0.0
        }
        
        return (samples, duration)
    }
    
    /// Get current accumulated audio for streaming transcription
    func getCurrentAudio() -> [Float] {
        return audioBuffer
    }
    
    // MARK: - Audio Processing
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, converter: AVAudioConverter?, outputFormat: AVAudioFormat, streaming: Bool) {
        // Calculate audio level for visualization
        if let channelData = buffer.floatChannelData?[0] {
            let frameCount = Int(buffer.frameLength)
            var sum: Float = 0.0
            for i in 0..<frameCount {
                sum += abs(channelData[i])
            }
            let level = sum / Float(frameCount)
            
            Task { @MainActor in
                self.audioLevel = min(level * 5, 1.0) // Amplify for visualization
            }
        }
        
        // Convert to 16kHz mono if converter exists
        if let converter = converter {
            let ratio = targetSampleRate / buffer.format.sampleRate
            let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
            
            guard let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: outputFormat,
                frameCapacity: outputFrameCapacity
            ) else { return }
            
            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            
            converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
            
            if error == nil, let channelData = outputBuffer.floatChannelData?[0] {
                let samples = Array(UnsafeBufferPointer(start: channelData, count: Int(outputBuffer.frameLength)))
                audioBuffer.append(contentsOf: samples)
            }
        } else {
            // No conversion needed, copy directly
            if let channelData = buffer.floatChannelData?[0] {
                let samples = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
                audioBuffer.append(contentsOf: samples)
            }
        }
        
        // For streaming mode, periodically trigger transcription callback
        if streaming, let lastChunk = lastChunkTime, let callback = onAudioChunk {
            let now = Date()
            if now.timeIntervalSince(lastChunk) >= streamingChunkInterval {
                lastChunkTime = now
                let currentSamples = audioBuffer
                // Call on main thread
                DispatchQueue.main.async {
                    callback(currentSamples)
                }
            }
        }
    }
}

// MARK: - Errors

enum AudioManagerError: LocalizedError {
    case engineNotInitialized
    case formatCreationFailed
    case captureAlreadyActive
    case permissionDenied
    case noInputDevice
    
    var errorDescription: String? {
        switch self {
        case .engineNotInitialized:
            return "Audio engine not initialized"
        case .formatCreationFailed:
            return "Failed to create audio format"
        case .captureAlreadyActive:
            return "Audio capture already active"
        case .permissionDenied:
            return "Microphone permission denied. Please grant access in System Settings."
        case .noInputDevice:
            return "No microphone found"
        }
    }
}
