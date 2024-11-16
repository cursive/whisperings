import SwiftUI
import WhisperKit

struct OnboardingView: View {
  @StateObject private var viewModel = OnboardingViewModel()
  @Binding var isOnboardingComplete: Bool
  let whisperKit: WhisperState

  var body: some View {
    VStack(spacing: 24) {
      Text("Welcome to Whispering ✨")
        .font(.largeTitle)
        .bold()

      Text("Choose a model to get started")
        .font(.title3)
        .foregroundStyle(.secondary)

      Picker("Select Model", selection: $viewModel.selectedModel) {
        ForEach(WhisperModel.allCases) { model in
          VStack(alignment: .leading) {
            Text(model.displayName)
              .font(.headline)
            Text(model.description)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .tag(model)
        }
      }
      .disabled(viewModel.isDownloading)

      if viewModel.isDownloading {
        VStack {
          ProgressView()
            .progressViewStyle(.circular)
          Text("Downloading model...")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      } else if viewModel.isModelReady {
        Button("Continue") {
          isOnboardingComplete = true
        }
        .buttonStyle(.borderedProminent)
      } else {
        Button("Download Model") {
          Task {
            await viewModel.downloadModel()
          }
        }
        .buttonStyle(.borderedProminent)
      }

      if let error = viewModel.error {
        Text(error)
          .font(.caption)
          .foregroundStyle(.red)
      }

      // Display available models
      ForEach(viewModel.availableModels, id: \.self) { model in
        Text(model)
          .font(.headline)
          .foregroundStyle(.primary)
      }

      Text(viewModel.selectedModel.description)
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.top, 8)
    }
    .padding()
    .frame(maxWidth: 500)
  }
}

@MainActor
class OnboardingViewModel: ObservableObject {
  @Published var selectedModel: WhisperModel = .base
  @Published var isDownloading = false
  @Published var isModelReady = false
  @Published var error: String?
  @Published var availableModels: [String] = []

  private var whisperKit: WhisperKit?

  func downloadModel() async {
    isDownloading = true
    error = nil

    do {
      whisperKit = try await WhisperKit(model: selectedModel.rawValue)
      isModelReady = true
    } catch {
      self.error = "Failed to download model: \(error.localizedDescription)"
    }

    isDownloading = false
  }

  func fetchAvailableModels() async {
    do {
      availableModels = try await WhisperKit.fetchAvailableModels()
      print(availableModels)
    } catch {
      self.error = "Failed to fetch available models: \(error.localizedDescription)"
    }
  }
}
