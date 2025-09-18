import Foundation

public struct ReplyContext {
  public let type: ContextType
  public let description: String
  
  public init(type: ContextType, description: String) {
    self.type = type
    self.description = description
  }
  
  public enum ContextType {
    case thread
    case debate
    case celebration
    case question
    case announcement
    case personal
  }
}
