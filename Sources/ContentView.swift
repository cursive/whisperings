import SwiftUI
import WhisperKit
import AVFoundation

@available(macOS 14.0, *)
struct ContentView: View {
  let whisperKit: WhisperState
  @StateObject private var transcriptionService = TranscriptionService()
  
  var body: some View {
    VStack(spacing: 12) {
      if transcriptionService.isTranscribing {
        VStack(spacing: 8) {
          ProgressView()
          Text("Transcribing...")
            .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
      } else {
        Button(action: {
          // Button is just for visual feedback
        }) {
          Label(
            transcriptionService.isRecording ? "Stop Recording" : "Start Recording",
            systemImage: transcriptionService.isRecording ? "stop.circle.fill" : "mic.circle.fill"
          )
        }
        .buttonStyle(.plain)
        .disabled(transcriptionService.isTranscribing)
        
        if transcriptionService.isRecording {
          Text("Say something.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }
      
      if !transcriptionService.transcriptionResult.isEmpty {
        Divider()
        
        VStack(alignment: .leading, spacing: 8) {
          Text("Last Transcription:")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Text(transcriptionService.transcriptionResult)
            .font(.callout)
            .textSelection(.enabled)
          
          Button(action: {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(transcriptionService.transcriptionResult, forType: .string)
          }) {
            Label("Copy to Clipboard", systemImage: "doc.on.doc")
              .font(.caption)
          }
          .buttonStyle(.borderless)
          .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: 300)
      }
      
      Divider()
      
      Button("Quit") {
        NSApplication.shared.terminate(nil)
      }
    }
    .padding()
  }
}

#Preview {
  ContentView(whisperKit: WhisperState())
}
