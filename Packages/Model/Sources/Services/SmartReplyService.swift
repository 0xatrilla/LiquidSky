import Foundation
import Models

#if canImport(FoundationModels)
  import FoundationModels
#endif

@MainActor
@Observable
public class SmartReplyService {
  public static let shared = SmartReplyService()
  
  // Cache for reply suggestions to avoid repeated API calls
  private var replyCache: [String: (suggestions: [ReplySuggestion], timestamp: Date)] = [:]
  private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes
  
  // User preferences for reply tone and style
  public var preferredTone: ReplyTone = .friendly
  public var includeEmojis: Bool = true
  public var maxSuggestions: Int = 4
  
  private init() {}
  
  // MARK: - Public Interface
  
  public func generateReplySuggestions(for post: PostItem, context: ReplyContext? = nil) async -> [ReplySuggestion] {
    let cacheKey = "\(post.id)_\(preferredTone.rawValue)_\(includeEmojis)"
    
    // Check cache first
    if let cached = replyCache[cacheKey],
       Date().timeIntervalSince(cached.timestamp) < cacheExpirationInterval {
      return cached.suggestions
    }
    
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        do {
          let suggestions = try await generateAISuggestions(for: post, context: context)
          
          // Cache the results
          replyCache[cacheKey] = (suggestions: suggestions, timestamp: Date())
          
          return suggestions
        } catch {
          print("SmartReplyService: Error generating suggestions: \(error)")
          return generateFallbackSuggestions(for: post)
        }
      }
    #endif
    
    return generateFallbackSuggestions(for: post)
  }
  
  public func clearCache() {
    replyCache.removeAll()
  }
  
  public func clearExpiredCache() {
    let now = Date()
    replyCache = replyCache.filter { _, value in
      now.timeIntervalSince(value.timestamp) < cacheExpirationInterval
    }
  }
  
  // MARK: - Private Methods
  
  #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func generateAISuggestions(for post: PostItem, context: ReplyContext?) async throws -> [ReplySuggestion] {
      let systemPrompt = buildSystemPrompt(for: post, context: context)
      let userPrompt = buildUserPrompt(for: post, context: context)
      
      let session = LanguageModelSession { systemPrompt }
      let response = try await session.respond(to: userPrompt)
      
      return parseAISuggestions(from: response.content)
    }
  #endif
  
  private func buildSystemPrompt(for post: PostItem, context: ReplyContext?) -> String {
    let tone = preferredTone.description
    let emojiInstruction = includeEmojis ? "Use appropriate emojis sparingly." : "Do not use emojis."
    
    return """
    You are a helpful assistant that generates reply suggestions for social media posts.
    
    Guidelines:
    - Generate \(maxSuggestions) diverse reply suggestions
    - Tone: \(tone)
    - \(emojiInstruction)
    - Keep replies under 280 characters
    - Make replies contextually relevant to the original post
    - Vary the types of replies (questions, agreements, elaborations, etc.)
    - Avoid controversial or offensive content
    - Consider the post's sentiment and topic
    
    Format your response as a JSON array of objects with "text" and "tone" fields.
    Example: [{"text": "Great point! I totally agree.", "tone": "supportive"}, ...]
    """
  }
  
  private func buildUserPrompt(for post: PostItem, context: ReplyContext?) -> String {
    var prompt = "Original post: \"\(post.content)\""
    
    if let author = post.author {
      prompt += "\nAuthor: @\(author.handle)"
    }
    
    if let context = context {
      prompt += "\nContext: \(context.description)"
    }
    
    if let repostedBy = post.repostedBy {
      prompt += "\nReposted by: @\(repostedBy.handle)"
    }
    
    return prompt
  }
  
  private func parseAISuggestions(from content: String) -> [ReplySuggestion] {
    // Extract JSON from the response
    let jsonStart = content.range(of: "[")?.lowerBound ?? content.startIndex
    let jsonEnd = content.range(of: "]", options: .backwards)?.upperBound ?? content.endIndex
    let jsonString = String(content[jsonStart..<jsonEnd])
    
    guard let data = jsonString.data(using: .utf8) else {
      return generateFallbackSuggestions()
    }
    
    do {
      let suggestions = try JSONDecoder().decode([ReplySuggestion].self, from: data)
      return Array(suggestions.prefix(maxSuggestions))
    } catch {
      print("SmartReplyService: Error parsing AI suggestions: \(error)")
      return generateFallbackSuggestions()
    }
  }
  
  private func generateFallbackSuggestions(for post: PostItem? = nil) -> [ReplySuggestion] {
    let baseSuggestions = [
      ReplySuggestion(text: "Interesting point!", tone: .supportive),
      ReplySuggestion(text: "Thanks for sharing this", tone: .grateful),
      ReplySuggestion(text: "I hadn't thought about it that way", tone: .thoughtful),
      ReplySuggestion(text: "Could you elaborate on that?", tone: .curious)
    ]
    
    // Customize based on post content if available
    if let post = post {
      return customizeFallbackSuggestions(baseSuggestions, for: post)
    }
    
    return Array(baseSuggestions.prefix(maxSuggestions))
  }
  
  private func customizeFallbackSuggestions(_ suggestions: [ReplySuggestion], for post: PostItem) -> [ReplySuggestion] {
    var customized = suggestions
    
    // Add context-specific suggestions based on post content
    let content = post.content.lowercased()
    
    if content.contains("?") {
      customized.append(ReplySuggestion(text: "That's a great question!", tone: .supportive))
    }
    
    if content.contains("congratulations") || content.contains("congrats") {
      customized.append(ReplySuggestion(text: "Congratulations! 🎉", tone: .celebratory))
    }
    
    if content.contains("thank") || content.contains("thanks") {
      customized.append(ReplySuggestion(text: "You're welcome!", tone: .grateful))
    }
    
    return Array(customized.prefix(maxSuggestions))
  }
}

// MARK: - Supporting Types

public struct ReplySuggestion: Codable, Identifiable {
  public let id = UUID()
  public let text: String
  public let tone: ReplyTone
  
  public init(text: String, tone: ReplyTone) {
    self.text = text
    self.tone = tone
  }
}

public enum ReplyTone: String, CaseIterable, Codable {
  case friendly = "friendly"
  case supportive = "supportive"
  case professional = "professional"
  case casual = "casual"
  case thoughtful = "thoughtful"
  case curious = "curious"
  case grateful = "grateful"
  case celebratory = "celebratory"
  
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
    }
  }
}

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
