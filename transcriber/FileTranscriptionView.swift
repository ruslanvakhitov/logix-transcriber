//
//  FileTranscriptionView.swift
//  transcriber
//
//  Drag-and-drop file transcription window
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct FileTranscriptionView: View {
    @ObservedObject var transcriptionManager: TranscriptionManager
    
    @State private var isDropTargeted = false
    @State private var isProcessing = false
    @State private var transcribedText = ""
    @State private var errorMessage: String?
    @State private var currentFileName: String?
    @State private var processingProgress: Double = 0.0
    @State private var processingStatus: String = ""
    @State private var estimatedTimeRemaining: String = ""
    @State private var fileDuration: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title2)
                Text("File Transcription")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Drop zone or result
            if transcribedText.isEmpty && !isProcessing {
                dropZone
            } else if isProcessing {
                processingView
            } else {
                resultView
            }
        }
        .frame(minWidth: 450, minHeight: 350)
        .background(Color(nsColor: .textBackgroundColor))
    }
    
    // MARK: - Drop Zone
    
    private var dropZone: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [8])
                    )
                    .foregroundColor(isDropTargeted ? .accentColor : .secondary.opacity(0.5))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isDropTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                    )
                
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 48))
                        .foregroundColor(isDropTargeted ? .accentColor : .secondary)
                    
                    Text("Drop audio file here")
                        .font(.headline)
                    
                    Text("MP3, WAV, M4A, AIFF, FLAC, OGG")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 200)
            .padding()
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                handleDrop(providers)
            }
            
            // Or select file button
            Button("Select File...") {
                selectFile()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Processing View
    
    private var processingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // File info
            if let fileName = currentFileName {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.accentColor)
                    Text(fileName)
                        .font(.headline)
                }
            }
            
            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: processingProgress, total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(width: 300)
                
                HStack {
                    Text(processingStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(processingProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                .frame(width: 300)
            }
            
            // Time estimate
            if !estimatedTimeRemaining.isEmpty {
                Text(estimatedTimeRemaining)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Animated dots
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                        .opacity(processingProgress > Double(i) * 0.3 ? 1.0 : 0.3)
                }
            }
            .animation(.easeInOut(duration: 0.5).repeatForever(), value: processingProgress)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Result View
    
    private var resultView: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                if let fileName = currentFileName {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(fileName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    copyToClipboard()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                
                Button {
                    reset()
                } label: {
                    Label("New File", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Transcription text
            ScrollView {
                Text(transcribedText)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        // Check if it can provide a file URL
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    Task { @MainActor in
                        await transcribeFile(at: url)
                    }
                } else if let url = item as? URL {
                    Task { @MainActor in
                        await transcribeFile(at: url)
                    }
                }
            }
            return true
        }
        return false
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mp3, .wav, .aiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select an audio file to transcribe"
        
        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await transcribeFile(at: url)
            }
        }
    }
    
    private func transcribeFile(at url: URL) async {
        isProcessing = true
        errorMessage = nil
        currentFileName = url.lastPathComponent
        processingProgress = 0.0
        processingStatus = "Loading audio file..."
        
        do {
            // Get file duration for progress estimation
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration)
            fileDuration = CMTimeGetSeconds(duration)
            
            let durationString = formatDuration(fileDuration)
            estimatedTimeRemaining = "File duration: \(durationString)"
            
            processingProgress = 0.1
            processingStatus = "Preparing..."
            
            // Check if models are loaded
            if !transcriptionManager.isLoaded {
                processingProgress = 0.2
                processingStatus = "Loading AI models..."
                try await transcriptionManager.loadModels()
            }
            
            processingProgress = 0.3
            processingStatus = "Transcribing audio..."
            
            // Estimate: transcription usually takes ~10-20% of audio duration
            let estimatedSeconds = max(1, Int(fileDuration * 0.15))
            estimatedTimeRemaining = "Estimated time: ~\(estimatedSeconds)s"
            
            // Start progress animation
            startProgressAnimation()
            
            let text = try await transcriptionManager.transcribeFile(at: url)
            
            processingProgress = 1.0
            processingStatus = "Complete!"
            
            try? await Task.sleep(nanoseconds: 300_000_000) // Brief pause to show 100%
            
            transcribedText = text
            isProcessing = false
        } catch {
            errorMessage = error.localizedDescription
            isProcessing = false
            processingProgress = 0
        }
    }
    
    private func startProgressAnimation() {
        // Animate progress from 0.3 to 0.9 during transcription
        Task {
            while isProcessing && processingProgress < 0.9 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                if isProcessing {
                    processingProgress = min(0.9, processingProgress + 0.05)
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        }
        return "\(secs)s"
    }
    
    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcribedText, forType: .string)
    }
    
    private func reset() {
        transcribedText = ""
        currentFileName = nil
        errorMessage = nil
        processingProgress = 0
        estimatedTimeRemaining = ""
    }
}

#Preview {
    FileTranscriptionView(transcriptionManager: TranscriptionManager())
}
