import SwiftUI
import WhisperKit
import AVFoundation
import Cocoa
import KeychainAccess
import Carbon.HIToolbox

// MARK: - Transcription Models
enum TranscriptionModel: String {
    case whisperLargeV3 = "whisper-large-v3"
    case whisperLargeV3Turbo = "whisper-large-v3-turbo"
    case distilWhisperLargeV3En = "distil-whisper-large-v3-en"
}

// MARK: - Transcription Response
struct TranscriptionResponse: Decodable {
    let text: String
}

enum TranscriptionMode: Identifiable, CaseIterable {
    var id: String {
        switch self {
        case .offline:
            return "offline"
        case .online:
            return "online"
        }
    }
    
    case offline
    case online
}

@MainActor
class TranscriptionService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    // MARK: - Published Properties
    @Published var hasInputMonitoringPermission = false
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var transcriptionResult = ""
    @Published var selectedTranscriptionModel: TranscriptionModel = .distilWhisperLargeV3En
    @Published var transcriptionMode: TranscriptionMode = .offline
    @Published private var isProcessing = false

    // MARK: - Private Properties
    private var whisperKit: WhisperKit?
    private var audioRecorder: AVAudioRecorder?
    private var keyboardMonitor: Any?
    private var recordingURL: URL?
    private let selectedModel: WhisperModel
    private let keychain = Keychain(service: GroqAPI.keychainService)

    // MARK: - Initialization
    init(model: WhisperModel = .base) {
        self.selectedModel = model
        print("🚀 TranscriptionService: Initializing...")

        super.init()
        setupWhisperKit()
    }

    private func setupWhisperKit() {
        Task {
            do {
                whisperKit = try await WhisperKit(model: selectedModel.rawValue)
                print("✅ WhisperKit setup completed successfully")
            } catch {
                print("❌ Error setting up WhisperKit:", error)
            }
        }
    }

    // MARK: - Keyboard Monitoring
    private func setupKeyboardMonitor() {
        print("⌨️ Setting up keyboard monitor...")
        print("🔐 Current accessibility permission status: \(AXIsProcessTrusted())")

        // Local monitor for when app is active
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            print("⌨️ Local keyboard event detected - keyCode: \(event.keyCode)")
            if event.keyCode == 96 || event.keyCode == 60 { // Both F5 and plain F5
                print("🎯 F5 key pressed (local)")
                self?.toggleRecording()
                return nil // Consume the event
            }
            return event
        }

        // Global monitor for when app is in background
        keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            print("⌨️ Global keyboard event detected - keyCode: \(event.keyCode)")
            if event.keyCode == 96 || event.keyCode == 60 { // Both F5 and plain F5
                print("🎯 F5 key pressed (global)")
                self?.toggleRecording()
            }
        }

        print("✅ Keyboard monitors successfully set up")
    }

    // MARK: - F5 Key Handling
    public func toggleRecording() {
        // Guard against multiple triggers while processing
        guard !isProcessing else {
            print("⚠️ Already processing a recording operation")
            return
        }
        
        guard !isTranscribing else {
            print("⚠️ Currently transcribing, please wait")
            return
        }

        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            if isRecording {
                print("🛑 Stopping recording...")
                isRecording = false
                transcriptionResult = "Transcribing..."
                pasteTranscribedText("Transcribing...")

                if let resultURL = await stopRecording() {
                    
                    isTranscribing = true
                    print("🔤 Starting transcription...")
                    
                    switch transcriptionMode {
                    case .offline:
                        do {
                            transcriptionResult = try await transcribeOffline(audio: resultURL)
                            pasteTranscribedText(transcriptionResult)
                        } catch {
                            print("❌ Offline transcription error: \(error)")
                            transcriptionResult = "Transcription failed"
                        }
                        isTranscribing = false
                    case .online:
                        do {
                            transcriptionResult = try await transcribeOnline(audio: resultURL)
                            pasteTranscribedText(transcriptionResult)
                        } catch {
                            print("❌ Online transcription error: \(error)")
                            transcriptionResult = "Transcription failed"
                        }
                        isTranscribing = false
                    }
                } else {
                    print("⚠️ Recording URL is nil, transcription skipped")
                    isTranscribing = false
                }

            } else {
                print("▶️ Starting recording...")
                isRecording = true
                transcriptionResult = ""
                pasteTranscribedText("Say something...")
                await startRecording()
            }
        }
    }

    // MARK: - Recording Functions
    private func configureAudioInput() -> Bool {
        // Get all audio devices
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        
        print("🎧 Available Audio Input Devices:")
        for device in discoverySession.devices {
            print("📱 Device: \(device.localizedName) (ID: \(device.uniqueID))")
            print("  Manufacturer: \(device.manufacturer)")
            print("  Connected: \(device.isConnected)")
        }
        
      return !discoverySession.devices.isEmpty
    }

    private func startRecording() async {
        print("🎙 Starting recording process...")
        
        guard configureAudioInput() else {
            print("❌ Failed to configure audio input")
            await MainActor.run {
                showNoAudioInputAlert()
                isRecording = false
            }
            return
        }
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC), // Using AAC for better Bluetooth compatibility
            AVSampleRateKey: 24000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 64000,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            recordingURL = documentsPath.appendingPathComponent("recording.m4a")

            if let url = recordingURL {
                print("📝 Recording to URL: \(url.path)")
                
                // Remove existing file if it exists
                try? FileManager.default.removeItem(at: url)
                
                audioRecorder = try AVAudioRecorder(url: url, settings: settings)
                audioRecorder?.delegate = self
                audioRecorder?.isMeteringEnabled = true
                
                if audioRecorder?.prepareToRecord() == true {
                    print("✅ Prepared to record")
                    if audioRecorder?.record() == true {
                        print("✅ Recording started successfully")
                        // Start monitoring audio levels
                        startAudioLevelMonitoring()
                    } else {
                        throw NSError(domain: "RecordingError", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "Failed to start recording"])
                    }
                } else {
                    throw NSError(domain: "RecordingError", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "Failed to prepare recording"])
                }
            }
        } catch {
            print("❌ Failed to start recording: \(error)")
            await MainActor.run {
                isRecording = false
            }
        }
    }

    private func startAudioLevelMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, self.isRecording else {
                timer.invalidate()
                return
            }
            self.audioRecorder?.updateMeters()
            let averagePower = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
            let peakPower = self.audioRecorder?.peakPower(forChannel: 0) ?? -160
            print("📊 Audio Levels - Avg: \(averagePower) dB, Peak: \(peakPower) dB")
        }
    }

    private func stopRecording() async -> URL? {
        print("🛑 Stopping recording process...")

        guard let recorder = audioRecorder, let url = recordingURL else {
            print("⚠️ No active recorder or URL found")
            return nil
        }

        recorder.stop()
        print("✅ Recording stopped successfully")
        print("📍 Recording saved at: \(url.path)")

        return url
    }

    // MARK: - API Key Management
    func setAPIKey(_ key: String) throws {
        try keychain.set(key, key: GroqAPI.keychainKey)
    }
    
    func getAPIKey() throws -> String {
        guard let apiKey = try keychain.get(GroqAPI.keychainKey) else {
            throw NSError(domain: "TranscriptionService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API key not found in keychain"])
        }
        return apiKey
    }
    
    // MARK: - Transcription
    private func transcribeOffline(audio url: URL) async throws -> String {
        print("🎯 Transcribing audio offline from: \(url.path)")
        guard let whisperKit = whisperKit else {
            throw NSError(domain: "TranscriptionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "WhisperKit not initialized"])
        }

        print("📝 Starting offline transcription process...")
        let result = try await whisperKit.transcribe(audioPath: url.path)
        print("✅ Offline transcription successful")
        return result.map { $0.text }.joined(separator: " ")
    }

    private func transcribeOnline(audio url: URL) async throws -> String {
        print("🎯 Starting Groq API transcription for: \(url.path)")
        
        let apiKey = try getAPIKey()
        var request = URLRequest(url: URL(string: GroqAPI.baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Add model parameter
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(selectedTranscriptionModel.rawValue)\r\n".data(using: .utf8)!)
        
        // Add file data
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        data.append(try Data(contentsOf: url))
        data.append("\r\n".data(using: .utf8)!)
        
        // Add closing boundary
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = data
        
        let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "TranscriptionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "TranscriptionService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed with status code \(httpResponse.statusCode)"])
        }
        
        let transcriptionResponse = try JSONDecoder().decode(TranscriptionResponse.self, from: responseData)
        return transcriptionResponse.text
    }

    // MARK: - Transcription Mode
    private func transcribe(audio url: URL) async throws -> String {
        switch transcriptionMode {
        case .offline:
            return try await transcribeOffline(audio: url)
        case .online:
            return try await transcribeOnline(audio: url)
        }
    }

    // MARK: - Paste Handling
    private func pasteTranscribedText(_ text: String) {
        Task {
            await MainActor.run {
                print("📋 Attempting to paste text: \(text)")
                // Save current clipboard content
                let pasteboard = NSPasteboard.general
                let oldContent = pasteboard.string(forType: .string)
                
                // Copy new text to clipboard
                pasteboard.clearContents()
                pasteboard.setString(text, forType: .string)
                
                // Simulate Cmd+V keystroke
                let source = CGEventSource(stateID: .hidSystemState)
                
                // Create Command down event
                let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Command), keyDown: true)
                
                // Create 'v' key down event
                let vDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
                vDown?.flags = .maskCommand
                
                // Create 'v' key up event
                let vUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
                vUp?.flags = .maskCommand
                
                // Create Command up event
                let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Command), keyDown: false)
                
                // Post the events
                cmdDown?.post(tap: .cghidEventTap)
                vDown?.post(tap: .cghidEventTap)
                vUp?.post(tap: .cghidEventTap)
                cmdUp?.post(tap: .cghidEventTap)
                
                print("✅ Paste command sent successfully")

                // Restore previous clipboard content after a short delay
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    if let oldContent = oldContent {
//                        pasteboard.clearContents()
//                        pasteboard.setString(oldContent, forType: .string)
//                    }
//                }
            }
        }
    }

    // MARK: - Cleanup
    deinit {
        print("♻️ TranscriptionService: Cleaning up resources")
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            print("🧹 Removed keyboard monitor")
        }
    }

    private func checkAudioInputAvailability() -> Bool {
        // Create a discovery session for audio devices
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        
        let devices = discoverySession.devices
        let hasInputDevices = !devices.isEmpty
        
        if !hasInputDevices {
            print("❌ No audio input devices found")
        } else {
            print("✅ Found \(devices.count) audio input device(s)")
            devices.forEach { device in
                print("📱 Device: \(device.localizedName)")
            }
        }
        
        return hasInputDevices
    }

    private func showNoAudioInputAlert() {
        let alert = NSAlert()
        alert.messageText = "No Audio Input Available"
        alert.informativeText = "Please connect a microphone or ensure your system's audio input is properly configured in System Settings."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Sound Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.sound")!)
        }
    }

    private func logAudioDevices() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        
        print("🎧 Available Audio Devices:")
        discoverySession.devices.forEach { device in
            print("- \(device.localizedName) (ID: \(device.uniqueID))")
            print("  Manufacturer: \(device.manufacturer)")
            print("  Connected: \(device.isConnected)")
        }
    }

    private func checkInputMonitoringPermission() async -> Bool {
        let trusted = CGPreflightListenEventAccess()
        if !trusted {
            await MainActor.run {
                showInputMonitoringAlert()
            }
            return false
        }
        return true
    }

    @MainActor
    private func showInputMonitoringAlert() {
        let alert = NSAlert()
        alert.messageText = "Input Monitoring Permission Required"
        alert.informativeText = "Please enable Input Monitoring for this app in System Settings to allow pasting text."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
        }
    }
}

// Add AVAudioRecorderDelegate methods
extension TranscriptionService {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("🎤 Recording finished - Success: \(flag)")
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("❌ Recording encode error: \(error)")
        }
    }
}
