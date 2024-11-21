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
      HStack {
        Picker("Mode", selection: $transcriptionService.transcriptionMode) {
          ForEach(TranscriptionMode.allCases) { mode in
            Text(mode.id.capitalized).tag(mode)
          }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        
        Spacer()
      }
      .padding(.horizontal)
      
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
            
            if autoClipboardCopy {
              Image(systemName: "doc.on.clipboard")
                .foregroundStyle(.secondary)
            }
          }
          
          Text(transcriptionService.transcriptionResult)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
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
