import Foundation

public struct SemanticSearchResult: Identifiable {
  public let id: UUID
  public let type: ResultType
  public let post: PostItem?
  public let user: Profile?
  public let relevanceScore: Double
  public let explanation: String
  public let matchedContent: String
  
  public init(type: ResultType, post: PostItem?, user: Profile?, relevanceScore: Double, explanation: String, matchedContent: String) {
    self.id = UUID()
    self.type = type
    self.post = post
    self.user = user
    self.relevanceScore = relevanceScore
    self.explanation = explanation
    self.matchedContent = matchedContent
  }
  
  public enum ResultType: String, Codable {
    case post = "post"
    case user = "user"
    case topic = "topic"
  }
}

public struct SearchIntent: Codable {
  public let intent: SearchIntentType
  public let concepts: [String]
  public let sentiment: Sentiment
  public let timeFrame: String?
  public let isQuestion: Bool
  
  public init(intent: SearchIntentType, concepts: [String], sentiment: Sentiment, timeFrame: String?, isQuestion: Bool) {
    self.intent = intent
    self.concepts = concepts
    self.sentiment = sentiment
    self.timeFrame = timeFrame
    self.isQuestion = isQuestion
  }
}

public enum SearchIntentType: String, Codable {
  case posts = "posts"
  case users = "users"
  case topics = "topics"
  case questions = "questions"
  case sentiment = "sentiment"
  case trends = "trends"
}

public enum Sentiment: String, Codable {
  case positive = "positive"
  case negative = "negative"
  case neutral = "neutral"
}

public enum SearchScope: String, CaseIterable {
  case all = "all"
  case posts = "posts"
  case users = "users"
  case following = "following"
  case bookmarks = "bookmarks"
}

public struct SearchContext {
  public let availablePosts: Int
  public let availableUsers: Int
  public let recentActivity: Bool
  public let description: String
  
  public init(availablePosts: Int, availableUsers: Int, recentActivity: Bool, description: String) {
    self.availablePosts = availablePosts
    self.availableUsers = availableUsers
    self.recentActivity = recentActivity
    self.description = description
  }
}
