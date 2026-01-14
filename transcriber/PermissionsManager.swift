//
//  PermissionsManager.swift
//  transcriber
//
//  Handles requesting and checking system permissions
//

import Foundation
import AVFoundation
import AppKit

/// Manages system permissions required by the app
@MainActor
final class PermissionsManager: ObservableObject {
    // MARK: - Properties
    
    @Published private(set) var hasMicrophonePermission: Bool = false
    @Published private(set) var hasAccessibilityPermission: Bool = false
    
    // MARK: - Initialization
    
    init() {
        refreshPermissions()
    }
    
    // MARK: - Permission Checks
    
    /// Refresh all permission statuses
    func refreshPermissions() {
        hasMicrophonePermission = checkMicrophonePermission()
        hasAccessibilityPermission = checkAccessibilityPermission()
    }
    
    /// Check microphone permission status
    func checkMicrophonePermission() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
    
    /// Check accessibility permission status
    func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): false]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    // MARK: - Permission Requests
    
    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool {
        let granted = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
        hasMicrophonePermission = granted
        return granted
    }
    
    /// Request accessibility permission (opens System Settings)
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    /// Open System Settings to Privacy & Security > Accessibility
    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Open System Settings to Privacy & Security > Microphone
    func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Computed Properties
    
    var allPermissionsGranted: Bool {
        return hasMicrophonePermission && hasAccessibilityPermission
    }
    
    var permissionStatusText: String {
        var issues: [String] = []
        if !hasMicrophonePermission {
            issues.append("Microphone")
        }
        if !hasAccessibilityPermission {
            issues.append("Accessibility")
        }
        
        if issues.isEmpty {
            return "All permissions granted"
        } else {
            return "Missing: \(issues.joined(separator: ", "))"
        }
    }
}
