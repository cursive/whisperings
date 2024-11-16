/// Represents available Whisper models with their configurations
enum WhisperModel: String, CaseIterable, Identifiable {
  case tinyEn = "openai_whisper-tiny.en"
  case tiny = "openai_whisper-tiny"
  case baseEn = "openai_whisper-base.en"
  case base = "openai_whisper-base"
  case small = "openai_whisper-small"
  case smallEn = "openai_whisper-small.en"
  case distilLargeV3 = "distil-whisper_distil-large-v3"
  case distilLargeV3Optimized = "distil-whisper_distil-large-v3_594MB"
  case largeV2 = "openai_whisper-large-v2"
  case largeV2Optimized = "openai_whisper-large-v2_949MB"
  case largeV3 = "openai_whisper-large-v3"
  case largeV3Latest = "openai_whisper-large-v3-v20240930"
  case largeV3LatestOptimized = "openai_whisper-large-v3-v20240930_626MB"
  case largeV3Optimized = "openai_whisper-large-v3_947MB"
  
  var id: String { rawValue }
  
  var displayName: String {
    switch self {
    case .tinyEn: return "Tiny (English)"
    case .tiny: return "Tiny (Multilingual)"
    case .baseEn: return "Base (English)"
    case .base: return "Base (Multilingual)"
    case .small: return "Small (Multilingual)"
    case .smallEn: return "Small (English)"
    case .distilLargeV3: return "Distil Large V3 (Multilingual)"
    case .distilLargeV3Optimized: return "Distil Large V3 Optimized (Multilingual)"
    case .largeV2: return "Large V2 (Multilingual)"
    case .largeV2Optimized: return "Large V2 Optimized (Multilingual)"
    case .largeV3: return "Large V3 (Multilingual)"
    case .largeV3Latest: return "Large V3 Latest (Multilingual)"
    case .largeV3LatestOptimized: return "Large V3 Latest Optimized (Multilingual)"
    case .largeV3Optimized: return "Large V3 Optimized (Multilingual)"
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
    case .distilLargeV3:
      return "Distilled version of Large V3, good balance of accuracy and size"
    case .distilLargeV3Optimized:
      return "Optimized distilled version of Large V3 (~594MB)"
    case .largeV2, .largeV2Optimized:
      return "Previous generation large model (~949MB)"
    case .largeV3, .largeV3Optimized:
      return "Most accurate model (~947MB)"
    case .largeV3Latest, .largeV3LatestOptimized:
      return "Latest version of Large V3, optimized for better performance (~626MB)"
    }
  }
}