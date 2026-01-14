//
//  TextInjector.swift
//  transcriber
//
//  Handles injecting transcribed text into the active application
//

import Foundation
import AppKit
import Carbon.HIToolbox

/// Injects transcribed text into the currently active application
final class TextInjector {
    // MARK: - Singleton
    
    static let shared = TextInjector()
    
    private init() {}
    
    // MARK: - Text Injection
    
    /// Paste text into the currently active application
    /// - Parameter text: Text to paste
    @MainActor
    func pasteText(_ text: String) async throws {
        // Save current pasteboard contents
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)
        
        // Set new text to pasteboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Small delay to ensure pasteboard is updated
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Simulate Cmd+V
        try simulatePaste()
        
        // Restore previous pasteboard contents after a delay
        Task {
            try await Task.sleep(nanoseconds: 500_000_000) // 500ms
            if let previous = previousContents {
                pasteboard.clearContents()
                pasteboard.setString(previous, forType: .string)
            }
        }
    }
    
    /// Type text directly using CGEvents (character by character)
    /// Note: Slower but doesn't affect clipboard
    @MainActor
    func typeText(_ text: String) throws {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        for character in text {
            let string = String(character)
            
            // Create key events for this character
            guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                  let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            else {
                continue
            }
            
            // Set the Unicode string
            var unicodeChars = Array(string.utf16)
            keyDownEvent.keyboardSetUnicodeString(stringLength: unicodeChars.count, unicodeString: &unicodeChars)
            keyUpEvent.keyboardSetUnicodeString(stringLength: unicodeChars.count, unicodeString: &unicodeChars)
            
            // Post events
            keyDownEvent.post(tap: .cghidEventTap)
            keyUpEvent.post(tap: .cghidEventTap)
            
            // Small delay between characters
            usleep(5000) // 5ms
        }
    }
    
    // MARK: - Private Methods
    
    private func simulatePaste() throws {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Key code for 'V'
        let keyCode: CGKeyCode = 9
        
        // Create Cmd+V key down event
        guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) else {
            throw TextInjectorError.eventCreationFailed
        }
        keyDownEvent.flags = .maskCommand
        
        // Create Cmd+V key up event
        guard let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            throw TextInjectorError.eventCreationFailed
        }
        keyUpEvent.flags = .maskCommand
        
        // Post events
        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
    }
    
    // MARK: - Permissions
    
    /// Check if accessibility permission is required
    static func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): false]
        return AXIsProcessTrustedWithOptions(options)
    }
}

// MARK: - Errors

enum TextInjectorError: LocalizedError {
    case eventCreationFailed
    case pasteboardError
    
    var errorDescription: String? {
        switch self {
        case .eventCreationFailed:
            return "Failed to create keyboard event"
        case .pasteboardError:
            return "Failed to access pasteboard"
        }
    }
}
