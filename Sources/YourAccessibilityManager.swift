import Cocoa

class AccessibilityManager {
    static let shared = AccessibilityManager()
    
    private var accessibilityMonitorTimer: Timer?
    
    /// Checks if the app has accessibility permissions and requests them if needed
    /// - Returns: A boolean indicating whether accessibility is enabled
    func requestAccessibilityPermissions() -> Bool {
        // Check current accessibility status
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let options = [checkOptPrompt: true] as CFDictionary
        let status = AXIsProcessTrustedWithOptions(options)
        
        if !status {
            // Show custom explanation dialog before system prompt
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions Required"
            alert.informativeText = """
        This app requires accessibility permissions to function properly.
        
        You will be prompted to grant access in System Settings.
        Please click "Open System Settings" and enable this app under:
        
        Privacy & Security → Accessibility
        """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                // Open directly to Accessibility preferences
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
        
        return status
    }
    
    /// Continuously monitors accessibility status changes
    /// - Parameter completion: Callback with updated status
    func startAccessibilityMonitoring(completion: @escaping (Bool) -> Void) {
        stopAccessibilityMonitoring()
        
        accessibilityMonitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
            guard let self else { return }
            let status = AXIsProcessTrusted()
            completion(status)
            
            // Optionally stop monitoring once permission is granted
            if status {
                self.stopAccessibilityMonitoring()
            }
        })
    }
    
    /// Stops the accessibility monitoring timer
    func stopAccessibilityMonitoring() {
        accessibilityMonitorTimer?.invalidate()
        accessibilityMonitorTimer = nil
    }
}
