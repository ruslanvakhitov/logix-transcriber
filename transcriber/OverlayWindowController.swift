//
//  OverlayWindowController.swift
//  transcriber
//
//  Floating overlay window that shows during recording
//

import SwiftUI
import AppKit

/// Controller for the floating recording overlay
@MainActor
final class OverlayWindowController: ObservableObject {
    private var overlayWindow: NSWindow?
    private var hostingView: NSHostingView<OverlayContentView>?
    
    @Published var isVisible: Bool = false
    @Published var audioLevel: Float = 0.0
    @Published var statusText: String = "Listening..."
    @Published var transcriptionPreview: String = ""
    
    init() {}
    
    /// Show the overlay window
    func show() {
        guard overlayWindow == nil else {
            overlayWindow?.orderFront(nil)
            isVisible = true
            return
        }
        
        // Create the overlay content view
        let contentView = OverlayContentView(controller: self)
        hostingView = NSHostingView(rootView: contentView)
        
        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingView
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isMovableByWindowBackground = false
        window.ignoresMouseEvents = true
        
        // Position at top center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowWidth: CGFloat = 200
            let windowHeight: CGFloat = 80
            let x = screenFrame.origin.x + (screenFrame.width - windowWidth) / 2
            let y = screenFrame.origin.y + screenFrame.height - windowHeight - 100 // 100px from top
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        window.orderFront(nil)
        overlayWindow = window
        isVisible = true
        
        print("OverlayWindowController: Showing overlay")
    }
    
    /// Hide the overlay window
    func hide() {
        overlayWindow?.orderOut(nil)
        isVisible = false
        statusText = "Listening..."
        transcriptionPreview = ""
        print("OverlayWindowController: Hiding overlay")
    }
    
    /// Update status
    func updateStatus(_ status: String) {
        statusText = status
    }
    
    /// Update transcription preview
    func updatePreview(_ text: String) {
        transcriptionPreview = text
    }
    
    /// Cleanup
    func cleanup() {
        overlayWindow?.close()
        overlayWindow = nil
        hostingView = nil
    }
}

// MARK: - Overlay Content View

struct OverlayContentView: View {
    @ObservedObject var controller: OverlayWindowController
    
    var body: some View {
        HStack(spacing: 12) {
            // Pulsing microphone indicator
            ZStack {
                // Outer pulse ring
                Circle()
                    .stroke(Color.red.opacity(0.3), lineWidth: 2)
                    .frame(width: 44, height: 44)
                    .scaleEffect(1.0 + CGFloat(controller.audioLevel) * 0.3)
                    .animation(.easeOut(duration: 0.15), value: controller.audioLevel)
                
                // Inner circle
                Circle()
                    .fill(Color.red)
                    .frame(width: 36, height: 36)
                
                // Microphone icon
                Image(systemName: "mic.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(controller.statusText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                if !controller.transcriptionPreview.isEmpty {
                    Text(controller.transcriptionPreview)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 200, height: 60)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.5), lineWidth: 1.5)
        )
    }
}
