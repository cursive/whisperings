import SwiftUI

@main
struct WhisperingApp: App {
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete = false
    
    var body: some Scene {
        WindowGroup {
            if #available(macOS 14.0, *) {
                if isOnboardingComplete {
                    ContentView()
                        .frame(minWidth: 400, minHeight: 300)
                } else {
                    OnboardingView(isOnboardingComplete: $isOnboardingComplete)
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
