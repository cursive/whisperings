import SwiftUI
import WhisperKit
import KeyboardShortcuts

@main
struct WhisperingApp: App {
  @AppStorage("isOnboardingComplete") private var isOnboardingComplete = false

  // Create a StateObject to hold the WhisperKit instance
  @StateObject private var whisperState = WhisperState()
  @StateObject private var transcriptionService = TranscriptionService()

  var body: some Scene {
    MenuBarExtra("Whispering", systemImage: "waveform.circle") {
      ContentView(whisperKit: whisperState)
        .environmentObject(transcriptionService)
        .onAppear {
          setupKeyboardShortcut()
        }
    }
    .menuBarExtraStyle(.window)

    Settings {
      SettingsView()
        .environmentObject(whisperState)
    }
  }

  func setupKeyboardShortcut() {
    KeyboardShortcuts.onKeyDown(for: .toggleRecording) { 
      transcriptionService.toggleRecording()
    }
  }
}

/// A class to manage the WhisperKit instance and handle its async initialization
@MainActor
class WhisperState: ObservableObject {
  /// The initialized WhisperKit instance
  @Published var whisperKit: WhisperKit?

  init() {
    Task {
      do {
        let config = WhisperKitConfig()
        self.whisperKit = try await WhisperKit(config)
      } catch {
        print("Failed to initialize WhisperKit: \(error)")
        // Handle error appropriately
      }
    }
  }
}
