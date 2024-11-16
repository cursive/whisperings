import SwiftUI
import WhisperKit

@main
struct WhisperingApp: App {
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete = false
    
    // Create a StateObject to hold the WhisperKit instance
    @StateObject private var whisperState = WhisperState()
    
    var body: some Scene {
        WindowGroup {
            if #available(macOS 14.0, *) {
                if isOnboardingComplete {
                    ContentView(whisperKit: whisperState)
                        .frame(minWidth: 400, minHeight: 300)
                } else {
                    OnboardingView(isOnboardingComplete: $isOnboardingComplete, whisperKit: whisperState)
                        .frame(minWidth: 500, minHeight: 400)
                }
            } else {
                Text("This app requires macOS 14.0 or later")
                    .padding()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
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
