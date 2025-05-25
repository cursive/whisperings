import SwiftUI
import WhisperKit
import KeyboardShortcuts

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var viewModel = SettingsViewModel()
  @EnvironmentObject private var whisperState: WhisperState
  
  var body: some View {
    Form {
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
    }
  }
}

@MainActor
class SettingsViewModel: ObservableObject {
  @Published var downloadedModels: [DownloadedModel] = []
  @Published var isLoading = false
  @Published var error: String?
  
  struct DownloadedModel: Hashable {
    let name: String
    let path: String
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
      await fetchDownloadedModels(whisperKit: try WhisperKit())
    } catch {
      self.error = "Failed to delete model: \(error.localizedDescription)"
    }
  }
}
