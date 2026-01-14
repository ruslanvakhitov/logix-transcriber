//
//  MenuBarView.swift
//  transcriber
//
//  Menu bar popup content view
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var transcriptionManager: TranscriptionManager
    @ObservedObject var hotkeyManager: HotkeyManager
    @ObservedObject var permissionsManager: PermissionsManager
    
    // Overlay window controller
    @StateObject private var overlayController = OverlayWindowController()
    
    // Transcription mode setting
    @AppStorage("transcriptionMode") private var transcriptionModeRaw: String = TranscriptionMode.full.rawValue
    
    private var transcriptionMode: TranscriptionMode {
        TranscriptionMode(rawValue: transcriptionModeRaw) ?? .full
    }
    
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with status
            headerSection
            
            Divider()
            
            // Permissions warning if needed
            if !permissionsManager.allPermissionsGranted {
                permissionsWarning
                Divider()
            }
            
            // Model loading status
            if !transcriptionManager.isLoaded {
                modelLoadingSection
                Divider()
            }
            
            // Quick actions
            actionButtons
            
            Divider()
            
            // Recent transcriptions
            if !appState.transcriptionHistory.isEmpty {
                recentTranscriptions
                Divider()
            }
            
            // Footer
            footerSection
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            setupHotkeyHandlers()
            Task {
                await initializeApp()
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading) {
                Text("Logix Transcriber")
                    .font(.headline)
                Text(appState.statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if appState.state == .listening {
                // Audio level indicator
                WaveformView(level: audioManager.audioLevel)
                    .frame(width: 40, height: 20)
            }
        }
    }
    
    private var permissionsWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Permissions Required", systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.subheadline)
            
            if !permissionsManager.hasMicrophonePermission {
                Button("Grant Microphone Access") {
                    Task {
                        await permissionsManager.requestMicrophonePermission()
                    }
                }
            }
            
            if !permissionsManager.hasAccessibilityPermission {
                Button("Grant Accessibility Access") {
                    permissionsManager.requestAccessibilityPermission()
                }
                .help("Required for global hotkey and text pasting")
            }
        }
    }
    
    private var modelLoadingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if transcriptionManager.loadingProgress > 0 && transcriptionManager.loadingProgress < 1 {
                    ProgressView(value: transcriptionManager.loadingProgress)
                        .progressViewStyle(.linear)
                } else {
                    Text(transcriptionManager.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Load Models") {
                Task {
                    try? await transcriptionManager.loadModels()
                    appState.isModelLoaded = true
                }
            }
            .disabled(transcriptionManager.loadingProgress > 0 && transcriptionManager.loadingProgress < 1)
        }
    }
    
    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hold Right ⌥ to dictate")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button {
                // Manual trigger for testing
                if appState.state == .idle {
                    startRecording()
                } else if appState.state == .listening {
                    stopRecording()
                }
            } label: {
                Label(
                    appState.state == .listening ? "Stop Recording" : "Start Recording",
                    systemImage: appState.state == .listening ? "stop.fill" : "mic.fill"
                )
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(!transcriptionManager.isLoaded) // Allow force start even if permissions check fails
            
            Divider()
            
            Button {
                openWindow(id: "file-transcription")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Transcribe File...", systemImage: "doc.text.magnifyingglass")
            }
            .keyboardShortcut("o", modifiers: .command)
        }
    }
    
    private var recentTranscriptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(appState.transcriptionHistory.prefix(3)) { entry in
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(entry.text, forType: .string)
                } label: {
                    VStack(alignment: .leading) {
                        Text(entry.text)
                            .lineLimit(1)
                            .font(.subheadline)
                        Text(entry.formattedTimestamp)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var footerSection: some View {
        HStack {
            Button("Settings...") {
                openSettingsWindow()
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Spacer()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
    
    private func openSettingsWindow() {
        print("Settings button clicked")
        openWindow(id: "settings")
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: String {
        switch appState.state {
        case .idle: return "mic"
        case .loading: return "arrow.down.circle"
        case .listening: return "mic.fill"
        case .processing: return "waveform"
        case .pasting: return "doc.on.clipboard"
        case .error: return "exclamationmark.triangle"
        }
    }
    
    private var statusColor: Color {
        switch appState.state {
        case .idle: return .primary
        case .listening: return .red
        case .processing: return .blue
        case .error: return .orange
        default: return .secondary
        }
    }
    
    // MARK: - Methods
    
    private func setupHotkeyHandlers() {
        hotkeyManager.onKeyDown = { [weak appState] in
            guard let appState = appState else { return }
            if appState.state == .idle {
                startRecording()
            }
        }
        
        hotkeyManager.onKeyUp = { [weak appState] in
            guard let appState = appState else { return }
            if appState.state == .listening {
                stopRecording()
            }
        }
        
        hotkeyManager.startMonitoring()
    }
    
    private func initializeApp() async {
        permissionsManager.refreshPermissions()
        
        if permissionsManager.hasMicrophonePermission && !transcriptionManager.isLoaded {
            do {
                try await transcriptionManager.loadModels()
                appState.isModelLoaded = true
            } catch {
                appState.state = .error(error.localizedDescription)
            }
        }
    }
    
    private func startRecording() {
        let isStreaming = transcriptionMode == .streaming
        
        Task { @MainActor in
            do {
                appState.state = .listening
                overlayController.show()
                
                if isStreaming {
                    // Set up real-time transcription callback
                    setupStreamingCallback()
                }
                
                try audioManager.startCapture(streaming: isStreaming)
            } catch {
                overlayController.hide()
                appState.state = .error(error.localizedDescription)
            }
        }
    }
    
    /// Track what text has already been typed in streaming mode
    @State private var lastTypedLength: Int = 0
    
    private func setupStreamingCallback() {
        // Capture managers we need (can't use weak self with struct)
        let transcriptionMgr = transcriptionManager
        let overlayCtrl = overlayController
        
        audioManager.onAudioChunk = { samples in
            Task { @MainActor in
                // Skip if not enough audio (need at least 1 second = 16000 samples)
                guard samples.count >= 16000 else { return }
                
                do {
                    // Transcribe accumulated audio
                    let text = try await transcriptionMgr.transcribe(samples)
                    
                    // Find new text by comparing lengths
                    // We use UserDefaults to persist the typed length since struct can't hold state
                    let typedLength = UserDefaults.standard.integer(forKey: "streamingTypedLength")
                    
                    if text.count > typedLength {
                        let newText = String(text.dropFirst(typedLength))
                        let trimmed = newText.trimmingCharacters(in: .whitespaces)
                        
                        if !trimmed.isEmpty {
                            overlayCtrl.updatePreview(text)
                            try? await TextInjector.shared.typeText(trimmed + " ")
                            UserDefaults.standard.set(text.count, forKey: "streamingTypedLength")
                        }
                    }
                } catch {
                    print("Streaming transcription error: \(error)")
                }
            }
        }
    }
    
    private func stopRecording() {
        let mode = transcriptionMode
        
        // Clear streaming callback
        audioManager.onAudioChunk = nil
        
        Task { @MainActor in
            let (samples, duration) = audioManager.stopCapture()
            
            // Minimum 1 second duration required
            guard duration >= 1.0 else {
                overlayController.hide()
                appState.state = .idle
                UserDefaults.standard.set(0, forKey: "streamingTypedLength")
                print("Recording too short (\(String(format: "%.1f", duration))s), ignoring")
                return
            }
            
            guard !samples.isEmpty else {
                overlayController.hide()
                appState.state = .idle
                UserDefaults.standard.set(0, forKey: "streamingTypedLength")
                return
            }
            
            switch mode {
            case .streaming:
                // In streaming mode, we already typed most text during recording
                // Just do final transcription to catch any remaining words
                overlayController.updateStatus("Finalizing...")
                
                do {
                    let finalText = try await transcriptionManager.transcribe(samples)
                    let typedLength = UserDefaults.standard.integer(forKey: "streamingTypedLength")
                    
                    // Type any remaining text not yet typed
                    if finalText.count > typedLength {
                        let remaining = String(finalText.dropFirst(typedLength))
                        let trimmed = remaining.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            try? await TextInjector.shared.typeText(trimmed)
                        }
                    }
                    
                    appState.currentTranscription = finalText
                    appState.addToHistory(finalText, duration: duration)
                } catch {
                    // Already typed partial text, just log error
                    print("Final transcription error: \(error)")
                }
                
                UserDefaults.standard.set(0, forKey: "streamingTypedLength")
                overlayController.hide()
                appState.state = .idle
                appState.clearCurrentTranscription()
                
            case .full:
                // Full mode: transcribe all then paste
                overlayController.updateStatus("Processing...")
                appState.state = .processing
                
                do {
                    let text = try await transcriptionManager.transcribe(samples)
                    
                    if !text.isEmpty {
                        appState.currentTranscription = text
                        appState.addToHistory(text, duration: duration)
                        
                        overlayController.updateStatus("Pasting...")
                        appState.state = .pasting
                        try await TextInjector.shared.pasteText(text)
                    }
                    
                    overlayController.hide()
                    appState.state = .idle
                    appState.clearCurrentTranscription()
                } catch {
                    overlayController.hide()
                    appState.state = .error(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Waveform View

struct WaveformView: View {
    let level: Float
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.red)
                        .frame(width: 4)
                        .frame(height: barHeight(for: index, in: geometry.size.height))
                }
            }
            .frame(height: geometry.size.height)
        }
    }
    
    private func barHeight(for index: Int, in maxHeight: CGFloat) -> CGFloat {
        let baseHeight = maxHeight * 0.3
        let variableHeight = maxHeight * 0.7 * CGFloat(level)
        let offset = sin(Double(index) * 0.8) * 0.3 + 0.7
        return baseHeight + variableHeight * CGFloat(offset)
    }
}

#Preview {
    MenuBarView(
        appState: AppState(),
        audioManager: AudioManager(),
        transcriptionManager: TranscriptionManager(),
        hotkeyManager: HotkeyManager(),
        permissionsManager: PermissionsManager()
    )
}
