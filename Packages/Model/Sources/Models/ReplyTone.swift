import Foundation

public enum ReplyTone: String, CaseIterable, Codable {
  case friendly = "friendly"
  case supportive = "supportive"
  case professional = "professional"
  case casual = "casual"
  case thoughtful = "thoughtful"
  case curious = "curious"
  case grateful = "grateful"
  case celebratory = "celebratory"
  case enthusiastic = "enthusiastic"
  
  public var description: String {
    switch self {
    case .friendly: return "Warm and approachable"
    case .supportive: return "Encouraging and positive"
    case .professional: return "Formal and business-like"
    case .casual: return "Relaxed and informal"
    case .thoughtful: return "Reflective and considerate"
    case .curious: return "Inquisitive and engaging"
    case .grateful: return "Appreciative and thankful"
    case .celebratory: return "Joyful and congratulatory"
    case .enthusiastic: return "Excited and energetic"
    }
  }
}
