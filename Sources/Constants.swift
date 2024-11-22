import Foundation
import KeyboardShortcuts

enum GroqAPI {
    static let baseURL = "https://api.groq.com/openai/v1/audio/transcriptions"
    static let keychainService = "com.whispering.apikeys"
    static let keychainKey = "groq_api_key"
}

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording", default: .init(.f5))
}
