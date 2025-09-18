import Foundation

@available(iOS 18.0, *)
public enum ContentPriority: Int, CaseIterable {
  case low = 0
  case normal = 1
  case high = 2

  public var displayName: String {
    switch self {
    case .low: return "Low"
    case .normal: return "Normal"
    case .high: return "High"
    }
  }
}