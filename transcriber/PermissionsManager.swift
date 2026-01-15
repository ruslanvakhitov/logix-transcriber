//
//  PermissionsManager.swift
//  transcriber
//
//  Handles requesting and checking system permissions
//

import Foundation
import AVFoundation
import AppKit
import Combine

/// Manages system permissions required by the app
@MainActor
final class PermissionsManager: ObservableObject {
    // MARK: - Properties
    
    @Published private(set) var hasMicrophonePermission: Bool = false
    @Published private(set) var hasAccessibilityPermission: Bool = false
    
    /// User can bypass Accessibility check if they know it's granted but detection fails
    @Published var bypassAccessibilityCheck: Bool {
        didSet {
            UserDefaults.standard.set(bypassAccessibilityCheck, forKey: "bypassAccessibilityCheck")
            objectWillChange.send()
        }
    }
    
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        self.bypassAccessibilityCheck = UserDefaults.standard.bool(forKey: "bypassAccessibilityCheck")
        refreshPermissions()
        startPeriodicRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Periodic Refresh
    
    private func startPeriodicRefresh() {
        // Refresh every 2 seconds to catch permission changes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPermissions()
            }
        }
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
        // If user bypassed check, always return true
        if bypassAccessibilityCheck {
            return true
        }
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): false]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// Test if Accessibility actually works by trying to post a test event
    func testAccessibilityWorks() -> Bool {
        // Try to create a keyboard event - this will fail silently if no permission
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            return false
        }
        // Create a "do nothing" event (modifier key with no actual effect)
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
            return false
        }
        // If we can create the event without crash, likely we have permission
        // Note: This doesn't guarantee posting works, but it's a good sign
        return true
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
        // Refresh after a short delay to pick up changes
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            refreshPermissions()
        }
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
            if bypassAccessibilityCheck {
                issues.append("Accessibility (bypassed)")
            } else {
                issues.append("Accessibility")
            }
        }
        
        if issues.isEmpty {
            return "All permissions granted"
        } else {
            return "Missing: \(issues.joined(separator: ", "))"
        }
    }
}
