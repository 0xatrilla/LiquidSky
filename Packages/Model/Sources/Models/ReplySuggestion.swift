import Foundation

public struct ReplySuggestion: Codable, Identifiable {
  public let id = UUID()
  public let text: String
  public let tone: ReplyTone
  
  public init(text: String, tone: ReplyTone) {
    self.text = text
    self.tone = tone
  }
}
