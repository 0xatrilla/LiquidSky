import Foundation
import Models

#if canImport(FoundationModels)
  import FoundationModels
#endif

@MainActor
@Observable
public class DigitalWellbeingService {
  public static let shared = DigitalWellbeingService()
  
  // Wellbeing metrics
  public var dailyUsageTime: TimeInterval = 0
  public var weeklyUsageTime: TimeInterval = 0
  public var sessionCount: Int = 0
  public var lastSessionEnd: Date?
  public var consecutiveDays: Int = 0
  
  // Wellbeing settings
  public var dailyTimeLimit: TimeInterval = 7200 // 2 hours in seconds
  public var breakRemindersEnabled: Bool = true
  public var breakInterval: TimeInterval = 1800 // 30 minutes
  public var wellbeingInsightsEnabled: Bool = true
  
  // Content analysis
  private var contentSentimentHistory: [ContentSentiment] = []
  private var negativeContentCount: Int = 0
  private var positiveContentCount: Int = 0
  
  // Session tracking
  private var currentSessionStart: Date?
  private var sessionHistory: [SessionData] = []
  
  private init() {
    loadWellbeingData()
    startSessionTracking()
  }
  
  // MARK: - Public Interface
  
  public func startSession() {
    currentSessionStart = Date()
    sessionCount += 1
  }
  
  public func endSession() {
    guard let startTime = currentSessionStart else { return }
    
    let sessionDuration = Date().timeIntervalSince(startTime)
    dailyUsageTime += sessionDuration
    weeklyUsageTime += sessionDuration
    
    let sessionData = SessionData(
      startTime: startTime,
      duration: sessionDuration,
      type: .normal
    )
    sessionHistory.append(sessionData)
    
    lastSessionEnd = Date()
    currentSessionStart = nil
    
    // Check for wellbeing concerns
    checkWellbeingConcerns()
    
    saveWellbeingData()
  }
  
  public func analyzeContentSentiment(_ content: String) async -> ContentSentiment {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        do {
          return try await performAISentimentAnalysis(content: content)
        } catch {
          print("DigitalWellbeingService: Error analyzing sentiment: \(error)")
        }
      }
    #endif
    
    return performFallbackSentimentAnalysis(content: content)
  }
  
  public func recordContentInteraction(_ content: String, interactionType: InteractionType) {
    Task {
      let sentiment = await analyzeContentSentiment(content)
      contentSentimentHistory.append(sentiment)
      
      switch sentiment.overall {
      case .positive:
        positiveContentCount += 1
      case .negative:
        negativeContentCount += 1
      case .neutral:
        break
      }
      
      // Check for negative content patterns
      checkNegativeContentPatterns()
    }
  }
  
  public func generateWellbeingInsights() async -> [WellbeingInsight] {
    var insights: [WellbeingInsight] = []
    
    // Usage insights
    if dailyUsageTime > dailyTimeLimit {
      insights.append(WellbeingInsight(
        type: .usage,
        severity: .warning,
        title: "Daily Time Limit Exceeded",
        message: "You've used the app for \(formatTime(dailyUsageTime)) today, exceeding your limit of \(formatTime(dailyTimeLimit)).",
        suggestion: "Consider taking a break or adjusting your time limit in settings."
      ))
    }
    
    if sessionCount > 20 {
      insights.append(WellbeingInsight(
        type: .usage,
        severity: .info,
        title: "Frequent App Usage",
        message: "You've opened the app \(sessionCount) times today.",
        suggestion: "Consider using focus modes or notification settings to reduce interruptions."
      ))
    }
    
    // Content insights
    let recentSentiment = contentSentimentHistory.suffix(10)
    let negativeRatio = Double(negativeContentCount) / Double(max(1, positiveContentCount + negativeContentCount))
    
    if negativeRatio > 0.7 {
      insights.append(WellbeingInsight(
        type: .content,
        severity: .warning,
        title: "Negative Content Pattern",
        message: "You've been engaging with more negative content recently.",
        suggestion: "Consider following more positive accounts or taking a break from social media."
      ))
    }
    
    // Break reminders
    if breakRemindersEnabled && shouldSuggestBreak() {
      insights.append(WellbeingInsight(
        type: .break,
        severity: .info,
        title: "Time for a Break",
        message: "You've been using the app for a while. Consider taking a short break.",
        suggestion: "Step away from your device for 5-10 minutes to rest your eyes and mind."
      ))
    }
    
    // Positive reinforcement
    if positiveContentCount > negativeContentCount * 2 {
      insights.append(WellbeingInsight(
        type: .positive,
        severity: .success,
        title: "Positive Content Balance",
        message: "Great job maintaining a positive content balance!",
        suggestion: "Keep following accounts that inspire and uplift you."
      ))
    }
    
    return insights
  }
  
  public func suggestWellbeingActions() async -> [WellbeingAction] {
    var actions: [WellbeingAction] = []
    
    // Usage-based actions
    if dailyUsageTime > dailyTimeLimit {
      actions.append(WellbeingAction(
        title: "Set App Timer",
        description: "Set a timer to limit your usage",
        actionType: .timer,
        priority: .high
      ))
    }
    
    if sessionCount > 15 {
      actions.append(WellbeingAction(
        title: "Enable Focus Mode",
        description: "Reduce interruptions with focus mode",
        actionType: .focusMode,
        priority: .medium
      ))
    }
    
    // Content-based actions
    let negativeRatio = Double(negativeContentCount) / Double(max(1, positiveContentCount + negativeContentCount))
    if negativeRatio > 0.6 {
      actions.append(WellbeingAction(
        title: "Curate Your Feed",
        description: "Follow more positive accounts",
        actionType: .curateFeed,
        priority: .high
      ))
    }
    
    // Break suggestions
    if shouldSuggestBreak() {
      actions.append(WellbeingAction(
        title: "Take a Break",
        description: "Step away for 5-10 minutes",
        actionType: .break,
        priority: .medium
      ))
    }
    
    return actions
  }
  
  public func resetDailyMetrics() {
    dailyUsageTime = 0
    sessionCount = 0
    contentSentimentHistory.removeAll()
    negativeContentCount = 0
    positiveContentCount = 0
    saveWellbeingData()
  }
  
  public func resetWeeklyMetrics() {
    weeklyUsageTime = 0
    consecutiveDays = 0
    saveWellbeingData()
  }
  
  // MARK: - Private Methods
  
  private func startSessionTracking() {
    // Track app lifecycle events
    NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { _ in
      self.startSession()
    }
    
    NotificationCenter.default.addObserver(
      forName: UIApplication.willResignActiveNotification,
      object: nil,
      queue: .main
    ) { _ in
      self.endSession()
    }
  }
  
  private func checkWellbeingConcerns() {
    // Check for excessive usage
    if dailyUsageTime > dailyTimeLimit * 1.5 {
      // Trigger strong wellbeing warning
      NotificationCenter.default.post(
        name: .wellbeingWarning,
        object: WellbeingWarning(type: .excessiveUsage, severity: .high)
      )
    }
    
    // Check for negative content patterns
    if negativeContentCount > positiveContentCount * 3 {
      NotificationCenter.default.post(
        name: .wellbeingWarning,
        object: WellbeingWarning(type: .negativeContent, severity: .medium)
      )
    }
  }
  
  private func checkNegativeContentPatterns() {
    let recentSentiment = contentSentimentHistory.suffix(20)
    let recentNegative = recentSentiment.filter { $0.overall == .negative }.count
    let recentPositive = recentSentiment.filter { $0.overall == .positive }.count
    
    if recentNegative > recentPositive * 2 {
      // Suggest content curation
      NotificationCenter.default.post(
        name: .wellbeingSuggestion,
        object: WellbeingSuggestion(
          type: .contentCuration,
          message: "Consider following more positive accounts to balance your feed."
        )
      )
    }
  }
  
  private func shouldSuggestBreak() -> Bool {
    guard let lastBreak = lastSessionEnd else { return true }
    return Date().timeIntervalSince(lastBreak) > breakInterval
  }
  
  #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func performAISentimentAnalysis(content: String) async throws -> ContentSentiment {
      let systemPrompt = """
      Analyze the emotional tone and sentiment of social media content.
      
      Return a JSON object with:
      - overall: positive/negative/neutral
      - emotions: array of detected emotions
      - intensity: 1-10 scale
      - wellbeing_impact: positive/negative/neutral
      - keywords: array of key emotional words
      """
      
      let userPrompt = "Content: \"\(content)\""
      
      let session = LanguageModelSession { systemPrompt }
      let response = try await session.respond(to: userPrompt)
      
      return parseSentimentAnalysis(from: response.content)
    }
  #endif
  
  private func parseSentimentAnalysis(from content: String) -> ContentSentiment {
    guard let data = content.data(using: .utf8) else {
      return performFallbackSentimentAnalysis(content: "")
    }
    
    do {
      return try JSONDecoder().decode(ContentSentiment.self, from: data)
    } catch {
      print("DigitalWellbeingService: Error parsing sentiment analysis: \(error)")
      return performFallbackSentimentAnalysis(content: "")
    }
  }
  
  private func performFallbackSentimentAnalysis(content: String) -> ContentSentiment {
    let contentLower = content.lowercased()
    
    let positiveWords = ["great", "amazing", "wonderful", "excellent", "love", "happy", "joy", "celebration", "congratulations"]
    let negativeWords = ["terrible", "awful", "hate", "angry", "sad", "disappointed", "frustrated", "worried", "anxious"]
    
    let positiveCount = positiveWords.reduce(0) { count, word in
      count + (contentLower.components(separatedBy: word).count - 1)
    }
    
    let negativeCount = negativeWords.reduce(0) { count, word in
      count + (contentLower.components(separatedBy: word).count - 1)
    }
    
    let overall: SentimentType
    if positiveCount > negativeCount {
      overall = .positive
    } else if negativeCount > positiveCount {
      overall = .negative
    } else {
      overall = .neutral
    }
    
    return ContentSentiment(
      overall: overall,
      emotions: [],
      intensity: min(10, max(1, abs(positiveCount - negativeCount))),
      wellbeingImpact: overall,
      keywords: []
    )
  }
  
  private func formatTime(_ timeInterval: TimeInterval) -> String {
    let hours = Int(timeInterval) / 3600
    let minutes = Int(timeInterval) % 3600 / 60
    
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(minutes)m"
    }
  }
  
  private func loadWellbeingData() {
    // Load from UserDefaults or Core Data
    dailyUsageTime = UserDefaults.standard.double(forKey: "dailyUsageTime")
    weeklyUsageTime = UserDefaults.standard.double(forKey: "weeklyUsageTime")
    sessionCount = UserDefaults.standard.integer(forKey: "sessionCount")
    dailyTimeLimit = UserDefaults.standard.double(forKey: "dailyTimeLimit")
    if dailyTimeLimit == 0 { dailyTimeLimit = 7200 } // Default 2 hours
  }
  
  private func saveWellbeingData() {
    UserDefaults.standard.set(dailyUsageTime, forKey: "dailyUsageTime")
    UserDefaults.standard.set(weeklyUsageTime, forKey: "weeklyUsageTime")
    UserDefaults.standard.set(sessionCount, forKey: "sessionCount")
    UserDefaults.standard.set(dailyTimeLimit, forKey: "dailyTimeLimit")
  }
}

// MARK: - Supporting Types

public struct ContentSentiment: Codable {
  public let overall: SentimentType
  public let emotions: [String]
  public let intensity: Int
  public let wellbeingImpact: SentimentType
  public let keywords: [String]
  
  public init(overall: SentimentType, emotions: [String], intensity: Int, wellbeingImpact: SentimentType, keywords: [String]) {
    self.overall = overall
    self.emotions = emotions
    self.intensity = intensity
    self.wellbeingImpact = wellbeingImpact
    self.keywords = keywords
  }
}

public enum SentimentType: String, Codable {
  case positive = "positive"
  case negative = "negative"
  case neutral = "neutral"
}

public struct WellbeingInsight: Identifiable {
  public let id = UUID()
  public let type: InsightType
  public let severity: Severity
  public let title: String
  public let message: String
  public let suggestion: String
  
  public init(type: InsightType, severity: Severity, title: String, message: String, suggestion: String) {
    self.type = type
    self.severity = severity
    self.title = title
    self.message = message
    self.suggestion = suggestion
  }
  
  public enum InsightType {
    case usage
    case content
    case break
    case positive
  }
  
  public enum Severity {
    case info
    case warning
    case success
  }
}

public struct WellbeingAction: Identifiable {
  public let id = UUID()
  public let title: String
  public let description: String
  public let actionType: ActionType
  public let priority: Priority
  
  public init(title: String, description: String, actionType: ActionType, priority: Priority) {
    self.title = title
    self.description = description
    self.actionType = actionType
    self.priority = priority
  }
  
  public enum ActionType {
    case timer
    case focusMode
    case curateFeed
    case break
    case settings
  }
  
  public enum Priority {
    case low
    case medium
    case high
  }
}

public struct SessionData {
  public let startTime: Date
  public let duration: TimeInterval
  public let type: SessionType
  
  public init(startTime: Date, duration: TimeInterval, type: SessionType) {
    self.startTime = startTime
    self.duration = duration
    self.type = type
  }
  
  public enum SessionType {
    case normal
    case focused
    case break
  }
}

public enum InteractionType {
  case view
  case like
  case repost
  case reply
  case share
}

public struct WellbeingWarning {
  public let type: WarningType
  public let severity: Severity
  
  public init(type: WarningType, severity: Severity) {
    self.type = type
    self.severity = severity
  }
  
  public enum WarningType {
    case excessiveUsage
    case negativeContent
    case frequentSessions
  }
  
  public enum Severity {
    case low
    case medium
    case high
  }
}

public struct WellbeingSuggestion {
  public let type: SuggestionType
  public let message: String
  
  public init(type: SuggestionType, message: String) {
    self.type = type
    self.message = message
  }
  
  public enum SuggestionType {
    case contentCuration
    case breakReminder
    case usageLimit
    case positiveContent
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let wellbeingWarning = Notification.Name("wellbeingWarning")
  static let wellbeingSuggestion = Notification.Name("wellbeingSuggestion")
}
