import SwiftUI
import WhisperKit
import Carbon

@main
struct WhisperingApp: App {
  @AppStorage("isOnboardingComplete") private var isOnboardingComplete = false

  // Create a StateObject to hold the WhisperKit instance
  @StateObject private var whisperState = WhisperState()

  // Add keyboard shortcut monitoring
  init() {
    //  registerGlobalShortcut()
  }

  var body: some Scene {
    MenuBarExtra(
      "Whispering",
      systemImage: "waveform.circle"
    ) {
      VStack {
        ContentView(whisperKit: whisperState)
        Divider()
        SettingsLink {
          HStack {
            Image(systemName: "gear")
              .imageScale(.small)
            Text("Settings")
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
      }
    }
    .menuBarExtraStyle(.window)

    Settings {
      SettingsView()
        .environmentObject(whisperState)
    }
  }

  private func registerGlobalShortcut() {
    NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
      // Check for Command (⌘) + Shift (⇧) + E
      if event.modifierFlags.contains([.command, .shift]) &&
          event.keyCode == 14 { // E key
        toggleApp()
      }
    }
  }

  private func toggleApp() {
    // Get the MenuBarExtra window
    if let window = NSApplication.shared.windows.first(where: { $0.isVisible }) {
      window.close()
    } else {
      NSApplication.shared.activate(ignoringOtherApps: true)
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
