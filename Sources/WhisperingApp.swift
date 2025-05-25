import SwiftUI
import WhisperKit

@main
struct WhisperingApp: App {
    @StateObject private var transcriptionService = TranscriptionService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(transcriptionService)
        }
    }
}

@MainActor
class WhisperState: ObservableObject {
    @Published var whisperKit: WhisperKit?

    init() {
        Task {
            do {
                let config = WhisperKitConfig()
                self.whisperKit = try await WhisperKit(config)
            } catch {
                print("❌ Failed to initialize WhisperKit: \(error)")
            }
        }
    }
}
