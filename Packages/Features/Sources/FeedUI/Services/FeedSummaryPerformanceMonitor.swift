import Foundation

@MainActor
public class FeedSummaryPerformanceMonitor: ObservableObject {
  public static let shared = FeedSummaryPerformanceMonitor()
  
  private var performanceMetrics: [String: PerformanceMetric] = [:]
  
  private init() {}
  
  public func startTiming(for operation: String) {
    performanceMetrics[operation] = PerformanceMetric(
      operation: operation,
      startTime: Date(),
      endTime: nil,
      duration: nil
    )
  }
  
  public func endTiming(for operation: String) -> TimeInterval? {
    guard let metric = performanceMetrics[operation] else { return nil }
    
    let endTime = Date()
    let duration = endTime.timeIntervalSince(metric.startTime)
    
    let updatedMetric = PerformanceMetric(
      operation: metric.operation,
      startTime: metric.startTime,
      endTime: endTime,
      duration: duration
    )
    
    performanceMetrics[operation] = updatedMetric
    
    #if DEBUG
    print("⏱️ Feed Summary Performance - \(operation): \(String(format: "%.2f", duration))s")
    #endif
    
    return duration
  }
  
  public func getMetrics() -> [PerformanceMetric] {
    return Array(performanceMetrics.values)
  }
  
  public func clearMetrics() {
    performanceMetrics.removeAll()
  }
}

public struct PerformanceMetric {
  public let operation: String
  public let startTime: Date
  public let endTime: Date?
  public let duration: TimeInterval?
  
  public init(operation: String, startTime: Date, endTime: Date?, duration: TimeInterval?) {
    self.operation = operation
    self.startTime = startTime
    self.endTime = endTime
    self.duration = duration
  }
}
