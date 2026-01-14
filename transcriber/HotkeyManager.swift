//
//  HotkeyManager.swift
//  transcriber
//
//  Handles global hotkey registration and monitoring (Right Option key)
//

import Foundation
import AppKit
import Carbon.HIToolbox

/// Manages global hotkey for hold-to-dictate (Right Option key)
@MainActor
final class HotkeyManager: ObservableObject {
    // MARK: - Properties
    
    /// Whether the right Option key is currently held
    @Published private(set) var isKeyHeld: Bool = false
    
    /// Event tap for monitoring modifier keys
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    /// Callbacks
    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?
    
    /// Track the previous state of right option
    private var wasRightOptionPressed: Bool = false
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Monitoring Control
    
    /// Start monitoring for the right Option key
    func startMonitoring() {
        // Create event tap for modifier key changes
        let eventMask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)
        
        // Create callback as a C function
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            guard let refcon = refcon else { return Unmanaged.passRetained(event) }
            
            let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
            
            // Handle tap disabled events
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = manager.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passRetained(event)
            }
            
            // Check modifier flags
            let flags = event.flags
            let isRightOptionPressed = flags.contains(.maskAlternate) && 
                                        (event.getIntegerValueField(.keyboardEventKeycode) == 61) // Right Option keycode
            
            // Alternative: check raw flags for right option specifically
            let rawFlags = flags.rawValue
            let rightOptionMask: UInt64 = 0x40  // NX_DEVICERALTKEYMASK
            let isRightOption = (rawFlags & (UInt64(NX_DEVICERALTKEYMASK))) != 0
            
            Task { @MainActor in
                if isRightOption && !manager.wasRightOptionPressed {
                    // Right Option pressed
                    manager.wasRightOptionPressed = true
                    manager.isKeyHeld = true
                    print("HotkeyManager: Right Option DOWN")
                    manager.onKeyDown?()
                } else if !isRightOption && manager.wasRightOptionPressed {
                    // Right Option released
                    manager.wasRightOptionPressed = false
                    manager.isKeyHeld = false
                    print("HotkeyManager: Right Option UP")
                    manager.onKeyUp?()
                }
            }
            
            return Unmanaged.passRetained(event)
        }
        
        // Create the event tap
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: refcon
        )
        
        guard let eventTap = eventTap else {
            print("HotkeyManager: Failed to create event tap. Check Accessibility permission.")
            return
        }
        
        // Create run loop source
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        
        guard let runLoopSource = runLoopSource else {
            print("HotkeyManager: Failed to create run loop source")
            return
        }
        
        // Add to run loop
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("HotkeyManager: Started monitoring Right Option key")
    }
    
    /// Stop monitoring
    func stopMonitoring() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
        
        print("HotkeyManager: Stopped monitoring")
    }
    
    // MARK: - Permissions
    
    /// Check if accessibility permission is granted
    func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): false]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// Request accessibility permission
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
