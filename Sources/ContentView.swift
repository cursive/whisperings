import SwiftUI
import WhisperKit
import AVFoundation

@available(macOS 14.0, *)
struct ContentView: View {
    @StateObject private var transcriptionService = TranscriptionService()
    
    var body: some View {
        VStack {
            if transcriptionService.isTranscribing {
                VStack {
                    ProgressView()
                    Text("Transcribing...")
                        .font(.headline)
                }
            } else {
                VStack {
                    Button(action: {
                        // Button is just for visual feedback
                    }) {
                        Image(systemName: transcriptionService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 44))
                            .symbolRenderingMode(.multicolor)
                            .symbolEffect(.bounce, value: transcriptionService.isRecording)
                    }
                    .buttonStyle(.plain)
                    .disabled(transcriptionService.isTranscribing)
                    
                    if transcriptionService.isRecording {
                        Text("Say something.")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding(.top, 8)
                    }
                }
            }
            
            if !transcriptionService.transcriptionResult.isEmpty {
                Text(transcriptionService.transcriptionResult)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
//            if !transcriptionService.hasAccessibilityPermissions {
//                VStack(spacing: 12) {
//                    Text("Required Permissions")
//                        .font(.headline)
//                    
//                    PermissionRow(
//                        title: "Accessibility",
//                        description: "Required to paste transcribed text",
//                        action: {
//                            NSWorkspace.shared.open(
//                                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
//                            )
//                        }
//                    )
//                }
//                .padding()
//                .background(Color.gray.opacity(0.1))
//                .cornerRadius(10)
//                .padding()
//            }
        }
        .padding()
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .bold()
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Open Settings") {
                action()
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.5))
        .cornerRadius(8)
    }
}

#Preview {
    if #available(macOS 14.0, *) {
        ContentView()
    } else {
        Text("Requires macOS 14.0 or later")
    }
}
