import Foundation
import Models

#if canImport(FoundationModels)
  import FoundationModels
#endif

@MainActor
@Observable
public class SemanticSearchService {
  public static let shared = SemanticSearchService()
  
  // Cache for search results to improve performance
  private var searchCache: [String: (results: [SemanticSearchResult], timestamp: Date)] = [:]
  private let cacheExpirationInterval: TimeInterval = 600 // 10 minutes
  
  // Search preferences
  public var searchScope: SearchScope = .all
  public var maxResults: Int = 20
  public var includeContext: Bool = true
  
  private init() {}
  
  // MARK: - Public Interface
  
  public func performSemanticSearch(query: String, posts: [PostItem], users: [Profile]) async -> [SemanticSearchResult] {
    let cacheKey = "\(query)_\(searchScope.rawValue)_\(posts.count)_\(users.count)"
    
    // Check cache first
    if let cached = searchCache[cacheKey],
       Date().timeIntervalSince(cached.timestamp) < cacheExpirationInterval {
      return cached.results
    }
    
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        do {
          let results = try await performAISemanticSearch(query: query, posts: posts, users: users)
          
          // Cache the results
          searchCache[cacheKey] = (results: results, timestamp: Date())
          
          return results
        } catch {
          print("SemanticSearchService: Error performing semantic search: \(error)")
          return performFallbackSearch(query: query, posts: posts, users: users)
        }
      }
    #endif
    
    return performFallbackSearch(query: query, posts: posts, users: users)
  }
  
  public func extractSearchIntent(from query: String) async -> SearchIntent {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        do {
          return try await analyzeSearchIntent(query: query)
        } catch {
          print("SemanticSearchService: Error analyzing search intent: \(error)")
        }
      }
    #endif
    
    return analyzeFallbackIntent(query: query)
  }
  
  public func generateSearchSuggestions(based query: String, context: SearchContext) async -> [String] {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        do {
          return try await generateAISearchSuggestions(query: query, context: context)
        } catch {
          print("SemanticSearchService: Error generating search suggestions: \(error)")
        }
      }
    #endif
    
    return generateFallbackSuggestions(query: query, context: context)
  }
  
  public func clearCache() {
    searchCache.removeAll()
  }
  
  public func clearExpiredCache() {
    let now = Date()
    searchCache = searchCache.filter { _, value in
      now.timeIntervalSince(value.timestamp) < cacheExpirationInterval
    }
  }
  
  // MARK: - Private Methods
  
  #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func performAISemanticSearch(query: String, posts: [PostItem], users: [Profile]) async throws -> [SemanticSearchResult] {
      let systemPrompt = buildSearchSystemPrompt()
      let userPrompt = buildSearchUserPrompt(query: query, posts: posts, users: users)
      
      let session = LanguageModelSession { systemPrompt }
      let response = try await session.respond(to: userPrompt)
      
      return parseSearchResults(from: response.content, posts: posts, users: users)
    }
    
    @available(iOS 26.0, *)
    private func analyzeSearchIntent(query: String) async throws -> SearchIntent {
      let systemPrompt = """
      Analyze the search intent from user queries. Classify the intent and extract key concepts.
      
      Return a JSON object with:
      - intent: one of [posts, users, topics, questions, sentiment, trends]
      - concepts: array of key concepts/topics
      - sentiment: positive/negative/neutral if applicable
      - timeFrame: recent/week/month/year if mentioned
      - isQuestion: boolean
      """
      
      let userPrompt = "Query: \"\(query)\""
      
      let session = LanguageModelSession { systemPrompt }
      let response = try await session.respond(to: userPrompt)
      
      return parseSearchIntent(from: response.content)
    }
    
    @available(iOS 26.0, *)
    private func generateAISearchSuggestions(query: String, context: SearchContext) async throws -> [String] {
      let systemPrompt = """
      Generate 5-8 search suggestions based on the user's query and context.
      Suggestions should be:
      - Related to the original query
      - More specific or broader variations
      - Include trending topics if relevant
      - Use natural language
      """
      
      let userPrompt = """
      Original query: "\(query)"
      Context: \(context.description)
      Available data: \(context.availablePosts) posts, \(context.availableUsers) users
      """
      
      let session = LanguageModelSession { systemPrompt }
      let response = try await session.respond(to: userPrompt)
      
      return parseSearchSuggestions(from: response.content)
    }
  #endif
  
  private func buildSearchSystemPrompt() -> String {
    return """
    You are a semantic search assistant for a social media platform.
    
    Your task is to find the most relevant posts and users based on the user's query.
    Consider:
    - Semantic meaning, not just keyword matching
    - Context and intent
    - User relationships and interests
    - Post sentiment and topics
    - Recency and engagement
    
    Return a JSON array of results with relevance scores and explanations.
    """
  }
  
  private func buildSearchUserPrompt(query: String, posts: [PostItem], users: [Profile]) -> String {
    var prompt = "Search query: \"\(query)\"\n\n"
    
    prompt += "Posts to search through (\(posts.count) total):\n"
    for (index, post) in posts.prefix(50).enumerated() {
      prompt += "\(index + 1). \(post.content) (by @\(post.author?.handle ?? "unknown"))\n"
    }
    
    prompt += "\nUsers to search through (\(users.count) total):\n"
    for (index, user) in users.prefix(20).enumerated() {
      prompt += "\(index + 1). @\(user.handle) - \(user.displayName ?? "") - \(user.description ?? "")\n"
    }
    
    return prompt
  }
  
  private func parseSearchResults(from content: String, posts: [PostItem], users: [Profile]) -> [SemanticSearchResult] {
    // Extract JSON from the response
    let jsonStart = content.range(of: "[")?.lowerBound ?? content.startIndex
    let jsonEnd = content.range(of: "]", options: .backwards)?.upperBound ?? content.endIndex
    let jsonString = String(content[jsonStart..<jsonEnd])
    
    guard let data = jsonString.data(using: .utf8) else {
      return performFallbackSearch(query: "", posts: posts, users: users)
    }
    
    do {
      let results = try JSONDecoder().decode([SemanticSearchResult].self, from: data)
      return Array(results.prefix(maxResults))
    } catch {
      print("SemanticSearchService: Error parsing search results: \(error)")
      return performFallbackSearch(query: "", posts: posts, users: users)
    }
  }
  
  private func parseSearchIntent(from content: String) -> SearchIntent {
    guard let data = content.data(using: .utf8) else {
      return SearchIntent(intent: .posts, concepts: [], sentiment: .neutral, timeFrame: nil, isQuestion: false)
    }
    
    do {
      return try JSONDecoder().decode(SearchIntent.self, from: data)
    } catch {
      print("SemanticSearchService: Error parsing search intent: \(error)")
      return SearchIntent(intent: .posts, concepts: [], sentiment: .neutral, timeFrame: nil, isQuestion: false)
    }
  }
  
  private func parseSearchSuggestions(from content: String) -> [String] {
    // Extract suggestions from the response
    let lines = content.components(separatedBy: .newlines)
    return lines.compactMap { line in
      let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }.prefix(8).map { String($0) }
  }
  
  private func performFallbackSearch(query: String, posts: [PostItem], users: [Profile]) -> [SemanticSearchResult] {
    let queryLower = query.lowercased()
    var results: [SemanticSearchResult] = []
    
    // Search posts
    for post in posts {
      let content = post.content.lowercased()
      let relevance = calculateRelevanceScore(query: queryLower, content: content)
      
      if relevance > 0.3 {
        results.append(SemanticSearchResult(
          type: .post,
          post: post,
          user: nil,
          relevanceScore: relevance,
          explanation: "Contains keywords: \(query)",
          matchedContent: extractMatchedContent(from: post.content, query: query)
        ))
      }
    }
    
    // Search users
    for user in users {
      let handle = user.handle.lowercased()
      let displayName = (user.displayName ?? "").lowercased()
      let description = (user.description ?? "").lowercased()
      
      let relevance = max(
        calculateRelevanceScore(query: queryLower, content: handle),
        calculateRelevanceScore(query: queryLower, content: displayName),
        calculateRelevanceScore(query: queryLower, content: description)
      )
      
      if relevance > 0.3 {
        results.append(SemanticSearchResult(
          type: .user,
          post: nil,
          user: user,
          relevanceScore: relevance,
          explanation: "Matches user profile",
          matchedContent: extractMatchedContent(from: "\(user.displayName ?? "") \(user.description ?? "")", query: query)
        ))
      }
    }
    
    return results.sorted { $0.relevanceScore > $1.relevanceScore }.prefix(maxResults).map { $0 }
  }
  
  private func calculateRelevanceScore(query: String, content: String) -> Double {
    let queryWords = query.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    let contentWords = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    
    var matches = 0
    for queryWord in queryWords {
      for contentWord in contentWords {
        if contentWord.contains(queryWord) || queryWord.contains(contentWord) {
          matches += 1
          break
        }
      }
    }
    
    return Double(matches) / Double(queryWords.count)
  }
  
  private func extractMatchedContent(from content: String, query: String) -> String {
    let words = content.components(separatedBy: .whitespacesAndNewlines)
    let queryWords = query.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    
    for (index, word) in words.enumerated() {
      for queryWord in queryWords {
        if word.lowercased().contains(queryWord.lowercased()) {
          let start = max(0, index - 2)
          let end = min(words.count, index + 3)
          return words[start..<end].joined(separator: " ")
        }
      }
    }
    
    return String(content.prefix(100))
  }
  
  private func analyzeFallbackIntent(query: String) -> SearchIntent {
    let queryLower = query.lowercased()
    
    let intent: SearchIntentType
    if queryLower.contains("?") || queryLower.hasPrefix("what") || queryLower.hasPrefix("how") || queryLower.hasPrefix("why") {
      intent = .questions
    } else if queryLower.contains("@") {
      intent = .users
    } else if queryLower.contains("#") {
      intent = .topics
    } else {
      intent = .posts
    }
    
    let concepts = queryLower.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    let isQuestion = queryLower.contains("?") || queryLower.hasPrefix("what") || queryLower.hasPrefix("how") || queryLower.hasPrefix("why")
    
    return SearchIntent(
      intent: intent,
      concepts: concepts,
      sentiment: .neutral,
      timeFrame: nil,
      isQuestion: isQuestion
    )
  }
  
  private func generateFallbackSuggestions(query: String, context: SearchContext) -> [String] {
    let baseSuggestions = [
      "\(query) discussion",
      "\(query) news",
      "\(query) opinions",
      "thoughts on \(query)",
      "\(query) updates"
    ]
    
    return Array(baseSuggestions.prefix(5))
  }
}

// MARK: - Supporting Types

public struct SemanticSearchResult: Identifiable, Codable {
  public let id = UUID()
  public let type: ResultType
  public let post: PostItem?
  public let user: Profile?
  public let relevanceScore: Double
  public let explanation: String
  public let matchedContent: String
  
  public init(type: ResultType, post: PostItem?, user: Profile?, relevanceScore: Double, explanation: String, matchedContent: String) {
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
