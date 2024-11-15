import SwiftUI

@main
struct WhisperingApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(macOS 14.0, *) {
                ContentView()
                    .frame(minWidth: 400, minHeight: 300)
            } else {
                Text("This app requires macOS 14.0 or later")
                    .padding()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
