import SwiftUI

struct ContentView: View {
    @EnvironmentObject var transcriptionService: TranscriptionService

    var body: some View {
        VStack(spacing: 20) {
            Text("Transcription")
                .font(.title)

            TextEditor(text: .constant(transcriptionService.transcriptionResult))
                .frame(height: 200)
                .border(Color.gray)

            Button(action: {
                transcriptionService.toggleRecording()
            }) {
                Text(transcriptionService.isRecording ? "Stop Recording" : "Start Recording")
                    .padding()
                    .background(transcriptionService.isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            if transcriptionService.isTranscribing {
                ProgressView("Transcribing...")
            }
        }
        .padding()
    }
}
