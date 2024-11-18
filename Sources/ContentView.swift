import SwiftUI
import WhisperKit
import AVFoundation

@available(macOS 14.0, *)
struct ContentView: View {
  let whisperKit: WhisperState
  @StateObject private var transcriptionService = TranscriptionService()
  @AppStorage("autoClipboardCopy") private var autoClipboardCopy = false
  
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
          self.transcriptionService.handleF5Press()
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
          HStack {
            Text("Last Transcription:")
              .font(.caption)
              .foregroundStyle(.secondary)
            
            Spacer()
          }
          
          Text(transcriptionService.transcriptionResult)
            .font(.callout)
            .textSelection(.enabled)
            .onChange(of: transcriptionService.transcriptionResult) { _, newValue in
              if autoClipboardCopy && !newValue.isEmpty {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(newValue, forType: .string)
              }
            }
          
          if !autoClipboardCopy {
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
        }
        .frame(maxWidth: 300)
      }

      Divider()

      Toggle("Auto Copy", isOn: $autoClipboardCopy)

      Divider()

      HStack {
        SettingsLink {
          Label("Settings", systemImage: "gear")
            .contentShape(Rectangle())
        }

        Spacer()

        Button(action: {
          NSApplication.shared.terminate(nil)
        }) {
          Label("Quit", systemImage: "power")
        }
      }
    }
    .padding()
  }
}

#Preview {
  ContentView(whisperKit: WhisperState())
}
