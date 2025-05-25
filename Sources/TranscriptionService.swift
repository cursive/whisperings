import SwiftUI
import AVFoundation
import WhisperKit

enum TranscriptionModel: String {
    case whisperLargeV3 = "whisper-large-v3"
    case whisperLargeV3Turbo = "whisper-large-v3-turbo"
    case distilWhisperLargeV3En = "distil-whisper-large-v3-en"
}

@MainActor
class TranscriptionService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var transcriptionResult = ""
    @Published var selectedTranscriptionModel: TranscriptionModel = .distilWhisperLargeV3En
    @Published private var isProcessing = false

    private var whisperKit: WhisperKit?
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private let selectedModel: WhisperModel

    init(model: WhisperModel = .base) {
        self.selectedModel = model
        super.init()
        setupWhisperKit()
    }

    private func setupWhisperKit() {
        Task {
            do {
                whisperKit = try await WhisperKit(model: selectedModel.rawValue)
            } catch {
                print("❌ Error setting up WhisperKit:", error)
            }
        }
    }

    func toggleRecording() {
        guard !isProcessing, !isTranscribing else { return }

        Task {
            isProcessing = true
            defer { isProcessing = false }

            if isRecording {
                isRecording = false
                transcriptionResult = "Transcribing..."

                if let resultURL = await stopRecording() {
                    isTranscribing = true
                    defer { isTranscribing = false }

                    do {
                        let result = try await transcribe(audio: resultURL)
                        transcriptionResult = result
                    } catch {
                        transcriptionResult = "Transcription failed"
                        print("❌ Transcription error: \(error)")
                    }
                }
            } else {
                transcriptionResult = ""
                isRecording = true
                await startRecording()
            }
        }
    }

    private func startRecording() async {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 24000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 64000,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            recordingURL = documentsPath.appendingPathComponent("recording.m4a")
            if let url = recordingURL {
                try? FileManager.default.removeItem(at: url)
                audioRecorder = try AVAudioRecorder(url: url, settings: settings)
                audioRecorder?.delegate = self
                audioRecorder?.isMeteringEnabled = true
                audioRecorder?.prepareToRecord()
                audioRecorder?.record()
            }
        } catch {
            print("❌ Failed to start recording: \(error)")
            isRecording = false
        }
    }

    private func stopRecording() async -> URL? {
        audioRecorder?.stop()
        return recordingURL
    }

    private func transcribe(audio url: URL) async throws -> String {
        guard let whisperKit = whisperKit else {
            throw NSError(domain: "WhisperKit", code: -1, userInfo: nil)
        }
        let result = try await whisperKit.transcribe(audioPath: url.path)
        return result.map { $0.text }.joined(separator: " ")
    }

    // MARK: - AVAudioRecorderDelegate
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("🎤 Recording finished - Success: \(flag)")
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("❌ Recording encode error: \(error)")
        }
    }
}
