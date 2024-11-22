import SwiftUI
import WhisperKit
import KeychainAccess
import KeyboardShortcuts

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var viewModel = SettingsViewModel()
  @EnvironmentObject private var whisperState: WhisperState
  
  var body: some View {
    Form {
      Section("API Key") {
        SecureField("Enter API Key", text: $viewModel.apiKey)
        
        HStack {
          Button(action: {
            Task {
              await viewModel.saveAPIKey()
            }
          }) {
            Text("Save")
          }
          .disabled(viewModel.apiKey.isEmpty)
          
          Button(action: {
            Task {
              await viewModel.verifyAPIKey()
            }
          }) {
            Text("Verify")
          }
          .disabled(viewModel.apiKey.isEmpty)
        }
        
        if viewModel.isVerifying {
          ProgressView()
            .frame(maxWidth: .infinity, alignment: .center)
        }
        
        if let apiStatus = viewModel.apiKeyStatus {
          Text(apiStatus.message)
            .foregroundStyle(apiStatus.isError ? .red : .green)
            .font(.caption)
        }
      }

      Section("Keyboard Shortcuts") {
        KeyboardShortcuts.Recorder("Toggle Recording:", name: .toggleRecording)
      }
      
      Section("Downloaded Models") {
        if viewModel.isLoading {
          ProgressView()
            .frame(maxWidth: .infinity, alignment: .center)
        } else if viewModel.downloadedModels.isEmpty {
          Text("No models downloaded")
            .foregroundStyle(.secondary)
        } else {
          ForEach(viewModel.downloadedModels, id: \.self) { model in
            HStack {
              VStack(alignment: .leading) {
                Text(model.name)
                  .font(.headline)
                Text(model.path)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              
              Spacer()
              
              Button(role: .destructive) {
                Task {
                  await viewModel.deleteModel(model)
                }
              } label: {
                Image(systemName: "trash")
              }
              .buttonStyle(.borderless)
            }
            .padding(.vertical, 4)
          }
        }
      }
      
      if let error = viewModel.error {
        Text(error)
          .foregroundStyle(.red)
          .font(.caption)
      }
    }
    .formStyle(.grouped)
    .frame(width: 500, height: 400)
    .task {
      if let whisperKit = whisperState.whisperKit {
        await viewModel.fetchDownloadedModels(whisperKit: whisperKit)
      }
      await viewModel.loadSavedAPIKey()
    }
  }
}

@MainActor
class SettingsViewModel: ObservableObject {
  @Published var downloadedModels: [DownloadedModel] = []
  @Published var isLoading = false
  @Published var error: String?
  @Published var apiKey: String = ""
  @Published var isVerifying = false
  @Published var apiKeyStatus: APIKeyStatus?
  
  private let keychain = Keychain(service: GroqAPI.keychainService)
  
  struct APIKeyStatus {
    let message: String
    let isError: Bool
  }
  
  struct DownloadedModel: Hashable {
    let name: String
    let path: String
  }
  
  func loadSavedAPIKey() async {
    do {
      if let savedKey = try keychain.get(GroqAPI.keychainKey) {
        apiKey = savedKey
      }
    } catch {
      self.error = "Failed to load API key: \(error.localizedDescription)"
    }
  }
  
  func saveAPIKey() async {
    do {
      try keychain.set(apiKey, key: GroqAPI.keychainKey)
      apiKeyStatus = APIKeyStatus(message: "API key saved successfully", isError: false)
    } catch {
      apiKeyStatus = APIKeyStatus(message: "Failed to save API key: \(error.localizedDescription)", isError: true)
    }
  }
  
  func verifyAPIKey() async {
    isVerifying = true
    apiKeyStatus = nil
    
    do {
      var request = URLRequest(url: URL(string: GroqAPI.baseURL)!)
      request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
      request.httpMethod = "POST"
      
      let (_, response) = try await URLSession.shared.data(for: request)
      
      if let httpResponse = response as? HTTPURLResponse {
        if httpResponse.statusCode == 401 {
          apiKeyStatus = APIKeyStatus(message: "Invalid API key", isError: true)
        } else if httpResponse.statusCode == 200 || httpResponse.statusCode == 400 {
          // 400 is acceptable here as it means the API key is valid but we didn't send proper audio data
          apiKeyStatus = APIKeyStatus(message: "API key verified successfully", isError: false)
        } else {
          apiKeyStatus = APIKeyStatus(message: "Verification failed: HTTP \(httpResponse.statusCode)", isError: true)
        }
      }
    } catch {
      apiKeyStatus = APIKeyStatus(message: "Verification failed: \(error.localizedDescription)", isError: true)
    }
    
    isVerifying = false
  }
  
  func fetchDownloadedModels(whisperKit: WhisperKit) async {
    isLoading = true
    error = nil
    
    do {
      guard let modelFolder = whisperKit.modelFolder?.deletingLastPathComponent() else {
        error = "Model folder not found"
        isLoading = false
        return
      }

      print(modelFolder)

      // Get contents of the model folder
      let contents = try FileManager.default.contentsOfDirectory(
        at: modelFolder,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
      )
      
      // Filter for directories and map to model names
      downloadedModels = contents.compactMap { url in
        let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
        if isDirectory {
          return DownloadedModel(
            name: url.lastPathComponent,
            path: url.path
          )
        }
        return nil
      }
    } catch {
      self.error = "Failed to fetch models: \(error.localizedDescription)"
    }
    
    isLoading = false
  }
  
  func deleteModel(_ model: DownloadedModel) async {
    do {
      try FileManager.default.removeItem(atPath: model.path)
      if let whisperKit = try? await WhisperKit(WhisperKitConfig()) {
        await fetchDownloadedModels(whisperKit: whisperKit)
      }
    } catch {
      self.error = "Failed to delete model: \(error.localizedDescription)"
    }
  }
}
