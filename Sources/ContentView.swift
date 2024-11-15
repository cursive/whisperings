import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "waveform")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Welcome to Whispering")
                .font(.title)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
