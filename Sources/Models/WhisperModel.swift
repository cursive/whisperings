/// Represents available Whisper models with their configurations
enum WhisperModel: String, CaseIterable, Identifiable {
  case tinyEn = "openai_whisper-tiny.en"
  case tiny = "openai_whisper-tiny"
  case baseEn = "openai_whisper-base.en"
  case base = "openai_whisper-base"
  case small = "openai_whisper-small"
  case smallEn = "openai_whisper-small.en"
  case largeV3 = "openai_whisper-large-v3"
  case largeV3Turbo = "openai_whisper-large-v3_turbo"
  
  var id: String { rawValue }
  
  var displayName: String {
    switch self {
    case .tinyEn: return "Tiny (English)"
    case .tiny: return "Tiny (Multilingual)"
    case .baseEn: return "Base (English)"
    case .base: return "Base (Multilingual)"
    case .small: return "Small (Multilingual)"
    case .smallEn: return "Small (English)"
    case .largeV3: return "Large V3 (Multilingual)"
    case .largeV3Turbo: return "Large V3 Turbo (Multilingual)"
    }
  }
  
  var description: String {
    switch self {
    case .tinyEn, .tiny:
      return "Fastest, least accurate model (~39MB)"
    case .baseEn, .base:
      return "Good balance of speed and accuracy (~142MB)"
    case .smallEn, .small:
      return "More accurate but slower (~466MB)"
    case .largeV3:
      return "Most accurate, very slow (~947MB)"
    case .largeV3Turbo:
      return "Most accurate, optimized for speed (~954MB)"
    }
  }
} 