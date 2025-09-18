import Foundation
import Models

#if canImport(FoundationModels)
  import FoundationModels
#endif

@MainActor
@Observable
public class PersonalAnalyticsService {
  public static let shared = PersonalAnalyticsService()
  
  // Analytics data
  public var userInsights: UserInsights?
  public var contentAnalytics: ContentAnalytics?
  public var engagementMetrics: EngagementMetrics?
  public var trendingTopics: [TrendingTopic] = []
  public var weeklyReport: WeeklyReport?
  
  // Settings
  public var analyticsEnabled: Bool = true
  public var dataRetentionDays: Int = 30
  public var insightsUpdateInterval: TimeInterval = 3600 // 1 hour
  
  // Cache
  private var insightsCache: [String: (insights: Any, timestamp: Date)] = [:]
  private let cacheExpirationInterval: TimeInterval = 1800 // 30 minutes
  
  private init() {
    loadAnalyticsSettings()
  }
  
  // MARK: - Public Interface
  
  public func generateUserInsights(posts: [PostItem], interactions: [UserInteraction]) async -> UserInsights {
    let cacheKey = "user_insights_\(posts.count)_\(interactions.count)"
    
    // Check cache first
    if let cached = insightsCache[cacheKey] as? (insights: UserInsights, timestamp: Date),
       Date().timeIntervalSince(cached.timestamp) < cacheExpirationInterval {
      return cached.insights
    }
    
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        do {
          let insights = try await generateAIUserInsights(posts: posts, interactions: interactions)
          
          // Cache the results
          insightsCache[cacheKey] = (insights: insights, timestamp: Date())
          
          return insights
        } catch {
          print("PersonalAnalyticsService: Error generating user insights: \(error)")
        }
      }
    #endif
    
    return generateFallbackUserInsights(posts: posts, interactions: interactions)
  }
  
  public func analyzeContentPatterns(posts: [PostItem]) async -> ContentAnalytics {
    let cacheKey = "content_analytics_\(posts.count)"
    
    if let cached = insightsCache[cacheKey] as? (insights: ContentAnalytics, timestamp: Date),
       Date().timeIntervalSince(cached.timestamp) < cacheExpirationInterval {
      return cached.insights
    }
    
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        do {
          let analytics = try await generateAIContentAnalytics(posts: posts)
          insightsCache[cacheKey] = (insights: analytics, timestamp: Date())
          return analytics
        } catch {
          print("PersonalAnalyticsService: Error analyzing content patterns: \(error)")
        }
      }
    #endif
    
    return generateFallbackContentAnalytics(posts: posts)
  }
  
  public func calculateEngagementMetrics(posts: [PostItem], interactions: [UserInteraction]) -> EngagementMetrics {
    let totalPosts = posts.count
    let totalLikes = posts.reduce(0) { $0 + $1.likeCount }
    let totalReposts = posts.reduce(0) { $0 + $1.repostCount }
    let totalReplies = posts.reduce(0) { $0 + $1.replyCount }
    
    let avgLikesPerPost = totalPosts > 0 ? Double(totalLikes) / Double(totalPosts) : 0
    let avgRepostsPerPost = totalPosts > 0 ? Double(totalReposts) / Double(totalPosts) : 0
    let avgRepliesPerPost = totalPosts > 0 ? Double(totalReplies) / Double(totalPosts) : 0
    
    let totalEngagement = totalLikes + totalReposts + totalReplies
    let engagementRate = totalPosts > 0 ? Double(totalEngagement) / Double(totalPosts) : 0
    
    // Calculate best performing post
    let bestPost = posts.max { $0.likeCount + $0.repostCount + $0.replyCount < $1.likeCount + $1.repostCount + $1.replyCount }
    
    // Calculate engagement trends
    let recentPosts = posts.suffix(10)
    let olderPosts = posts.prefix(max(0, posts.count - 10))
    
    let recentEngagement = recentPosts.reduce(0) { $0 + $1.likeCount + $1.repostCount + $1.replyCount }
    let olderEngagement = olderPosts.reduce(0) { $0 + $1.likeCount + $1.repostCount + $1.replyCount }
    
    let engagementTrend: EngagementTrend
    if recentEngagement > olderEngagement {
      engagementTrend = .increasing
    } else if recentEngagement < olderEngagement {
      engagementTrend = .decreasing
    } else {
      engagementTrend = .stable
    }
    
    return EngagementMetrics(
      totalPosts: totalPosts,
      totalLikes: totalLikes,
      totalReposts: totalReposts,
      totalReplies: totalReplies,
      avgLikesPerPost: avgLikesPerPost,
      avgRepostsPerPost: avgRepostsPerPost,
      avgRepliesPerPost: avgRepliesPerPost,
      engagementRate: engagementRate,
      bestPerformingPost: bestPost,
      engagementTrend: engagementTrend
    )
  }
  
  public func identifyTrendingTopics(posts: [PostItem]) async -> [TrendingTopic] {
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        do {
          return try await generateAITrendingTopics(posts: posts)
        } catch {
          print("PersonalAnalyticsService: Error identifying trending topics: \(error)")
        }
      }
    #endif
    
    return generateFallbackTrendingTopics(posts: posts)
  }
  
  public func generateWeeklyReport(posts: [PostItem], interactions: [UserInteraction]) async -> WeeklyReport {
    let userInsights = await generateUserInsights(posts: posts, interactions: interactions)
    let contentAnalytics = await analyzeContentPatterns(posts: posts)
    let engagementMetrics = calculateEngagementMetrics(posts: posts, interactions: interactions)
    let trendingTopics = await identifyTrendingTopics(posts: posts)
    
    return WeeklyReport(
      weekOf: Date(),
      userInsights: userInsights,
      contentAnalytics: contentAnalytics,
      engagementMetrics: engagementMetrics,
      trendingTopics: trendingTopics,
      recommendations: generateRecommendations(
        insights: userInsights,
        analytics: contentAnalytics,
        metrics: engagementMetrics
      )
    )
  }
  
  public func generateRecommendations(
    insights: UserInsights,
    analytics: ContentAnalytics,
    metrics: EngagementMetrics
  ) -> [Recommendation] {
    var recommendations: [Recommendation] = []
    
    // Engagement-based recommendations
    if metrics.engagementTrend == .decreasing {
      recommendations.append(Recommendation(
        type: .engagement,
        priority: .high,
        title: "Boost Your Engagement",
        description: "Your recent posts are getting less engagement. Try posting at different times or using more engaging content.",
        action: "Post during peak hours (6-9 PM) or ask questions to encourage replies."
      ))
    }
    
    if metrics.avgLikesPerPost < 5 {
      recommendations.append(Recommendation(
        type: .content,
        priority: .medium,
        title: "Improve Content Quality",
        description: "Your posts could benefit from more engaging content.",
        action: "Try sharing personal stories, asking questions, or using relevant hashtags."
      ))
    }
    
    // Content-based recommendations
    if analytics.mostUsedTopics.count > 0 {
      let topTopic = analytics.mostUsedTopics[0]
      recommendations.append(Recommendation(
        type: .content,
        priority: .low,
        title: "Leverage Your Expertise",
        description: "You frequently post about \(topTopic.name). Consider becoming a thought leader in this area.",
        action: "Share more in-depth content about \(topTopic.name) or start discussions."
      ))
    }
    
    // Time-based recommendations
    if let bestTime = analytics.bestPostingTimes.first {
      recommendations.append(Recommendation(
        type: .timing,
        priority: .medium,
        title: "Optimize Posting Times",
        description: "Your posts perform best around \(bestTime).",
        action: "Schedule more posts during this time for better engagement."
      ))
    }
    
    // Wellbeing recommendations
    if insights.dailyPostCount > 10 {
      recommendations.append(Recommendation(
        type: .wellbeing,
        priority: .medium,
        title: "Consider Quality Over Quantity",
        description: "You're posting very frequently. Consider focusing on fewer, higher-quality posts.",
        action: "Try posting 3-5 thoughtful posts per day instead of many quick updates."
      ))
    }
    
    return recommendations
  }
  
  public func clearCache() {
    insightsCache.removeAll()
  }
  
  public func clearExpiredCache() {
    let now = Date()
    insightsCache = insightsCache.filter { _, value in
      now.timeIntervalSince(value.timestamp) < cacheExpirationInterval
    }
  }
  
  // MARK: - Private Methods
  
  #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func generateAIUserInsights(posts: [PostItem], interactions: [UserInteraction]) async throws -> UserInsights {
      let systemPrompt = """
      Analyze a user's social media activity and generate personalized insights.
      
      Return a JSON object with:
      - posting_pattern: description of when/how often they post
      - content_themes: array of main topics they discuss
      - engagement_style: how they interact with others
      - personality_traits: inferred personality characteristics
      - growth_areas: suggestions for improvement
      - strengths: what they do well
      - daily_post_count: average posts per day
      - preferred_content_types: text/image/video preferences
      """
      
      let userPrompt = buildUserPrompt(posts: posts, interactions: interactions)
      
      let session = LanguageModelSession { systemPrompt }
      let response = try await session.respond(to: userPrompt)
      
      return parseUserInsights(from: response.content)
    }
    
    @available(iOS 26.0, *)
    private func generateAIContentAnalytics(posts: [PostItem]) async throws -> ContentAnalytics {
      let systemPrompt = """
      Analyze content patterns and provide detailed analytics.
      
      Return a JSON object with:
      - most_used_topics: array of topics with frequency
      - sentiment_distribution: positive/negative/neutral percentages
      - best_posting_times: array of optimal posting times
      - content_length_analysis: average and optimal lengths
      - hashtag_usage: most effective hashtags
      - engagement_patterns: when content gets most engagement
      """
      
      let userPrompt = buildContentPrompt(posts: posts)
      
      let session = LanguageModelSession { systemPrompt }
      let response = try await session.respond(to: userPrompt)
      
      return parseContentAnalytics(from: response.content)
    }
    
    @available(iOS 26.0, *)
    private func generateAITrendingTopics(posts: [PostItem]) async throws -> [TrendingTopic] {
      let systemPrompt = """
      Identify trending topics from social media posts.
      
      Return a JSON array of trending topics with:
      - name: topic name
      - frequency: how often it appears
      - trend_direction: increasing/decreasing/stable
      - related_hashtags: array of related hashtags
      - engagement_score: average engagement for this topic
      """
      
      let userPrompt = buildTrendingTopicsPrompt(posts: posts)
      
      let session = LanguageModelSession { systemPrompt }
      let response = try await session.respond(to: userPrompt)
      
      return parseTrendingTopics(from: response.content)
    }
  #endif
  
  private func buildUserPrompt(posts: [PostItem], interactions: [UserInteraction]) -> String {
    var prompt = "User's recent posts (\(posts.count) total):\n"
    
    for (index, post) in posts.prefix(20).enumerated() {
      prompt += "\(index + 1). \(post.content) (Likes: \(post.likeCount), Reposts: \(post.repostCount), Replies: \(post.replyCount))\n"
    }
    
    prompt += "\nUser's interactions (\(interactions.count) total):\n"
    for (index, interaction) in interactions.prefix(20).enumerated() {
      prompt += "\(index + 1). \(interaction.type.rawValue) - \(interaction.content)\n"
    }
    
    return prompt
  }
  
  private func buildContentPrompt(posts: [PostItem]) -> String {
    var prompt = "Content analysis for \(posts.count) posts:\n\n"
    
    for (index, post) in posts.prefix(50).enumerated() {
      prompt += "Post \(index + 1): \(post.content)\n"
      prompt += "Engagement: \(post.likeCount) likes, \(post.repostCount) reposts, \(post.replyCount) replies\n"
      prompt += "Posted: \(post.createdAt)\n\n"
    }
    
    return prompt
  }
  
  private func buildTrendingTopicsPrompt(posts: [PostItem]) -> String {
    var prompt = "Identify trending topics from these posts:\n\n"
    
    for (index, post) in posts.prefix(100).enumerated() {
      prompt += "\(index + 1). \(post.content)\n"
    }
    
    return prompt
  }
  
  private func parseUserInsights(from content: String) -> UserInsights {
    guard let data = content.data(using: .utf8) else {
      return generateFallbackUserInsights(posts: [], interactions: [])
    }
    
    do {
      return try JSONDecoder().decode(UserInsights.self, from: data)
    } catch {
      print("PersonalAnalyticsService: Error parsing user insights: \(error)")
      return generateFallbackUserInsights(posts: [], interactions: [])
    }
  }
  
  private func parseContentAnalytics(from content: String) -> ContentAnalytics {
    guard let data = content.data(using: .utf8) else {
      return generateFallbackContentAnalytics(posts: [])
    }
    
    do {
      return try JSONDecoder().decode(ContentAnalytics.self, from: data)
    } catch {
      print("PersonalAnalyticsService: Error parsing content analytics: \(error)")
      return generateFallbackContentAnalytics(posts: [])
    }
  }
  
  private func parseTrendingTopics(from content: String) -> [TrendingTopic] {
    guard let data = content.data(using: .utf8) else {
      return generateFallbackTrendingTopics(posts: [])
    }
    
    do {
      return try JSONDecoder().decode([TrendingTopic].self, from: data)
    } catch {
      print("PersonalAnalyticsService: Error parsing trending topics: \(error)")
      return generateFallbackTrendingTopics(posts: [])
    }
  }
  
  private func generateFallbackUserInsights(posts: [PostItem], interactions: [UserInteraction]) -> UserInsights {
    let dailyPostCount = posts.count / 7 // Rough estimate
    let contentThemes = extractContentThemes(from: posts)
    
    return UserInsights(
      postingPattern: "Regular poster",
      contentThemes: contentThemes,
      engagementStyle: "Active engager",
      personalityTraits: ["Social", "Expressive"],
      growthAreas: ["Content variety", "Engagement optimization"],
      strengths: ["Consistent posting", "Community building"],
      dailyPostCount: dailyPostCount,
      preferredContentTypes: ["Text", "Images"]
    )
  }
  
  private func generateFallbackContentAnalytics(posts: [PostItem]) -> ContentAnalytics {
    let topics = extractContentThemes(from: posts)
    let sentimentDistribution = calculateSentimentDistribution(from: posts)
    
    return ContentAnalytics(
      mostUsedTopics: topics.map { TopicFrequency(name: $0, frequency: 1) },
      sentimentDistribution: sentimentDistribution,
      bestPostingTimes: ["6-9 PM", "12-2 PM"],
      contentLengthAnalysis: ContentLengthAnalysis(
        averageLength: calculateAverageLength(from: posts),
        optimalLength: 150,
        lengthEngagementCorrelation: 0.7
      ),
      hashtagUsage: extractHashtags(from: posts),
      engagementPatterns: ["Evening posts perform best"]
    )
  }
  
  private func generateFallbackTrendingTopics(posts: [PostItem]) -> [TrendingTopic] {
    let topics = extractContentThemes(from: posts)
    return topics.prefix(5).map { topic in
      TrendingTopic(
        name: topic,
        frequency: 1,
        trendDirection: .stable,
        relatedHashtags: ["#\(topic.lowercased())"],
        engagementScore: 5.0
      )
    }
  }
  
  private func extractContentThemes(from posts: [PostItem]) -> [String] {
    let allContent = posts.map { $0.content }.joined(separator: " ")
    let words = allContent.components(separatedBy: .whitespacesAndNewlines)
      .filter { $0.count > 3 }
      .map { $0.lowercased() }
    
    let wordCounts = Dictionary(grouping: words, by: { $0 })
      .mapValues { $0.count }
      .sorted { $0.value > $1.value }
    
    return Array(wordCounts.prefix(10).map { $0.key })
  }
  
  private func calculateSentimentDistribution(from posts: [PostItem]) -> SentimentDistribution {
    // Simple sentiment analysis based on keywords
    let positiveWords = ["great", "amazing", "wonderful", "love", "happy", "excellent"]
    let negativeWords = ["terrible", "awful", "hate", "sad", "disappointed", "angry"]
    
    var positiveCount = 0
    var negativeCount = 0
    var neutralCount = 0
    
    for post in posts {
      let content = post.content.lowercased()
      let hasPositive = positiveWords.contains { content.contains($0) }
      let hasNegative = negativeWords.contains { content.contains($0) }
      
      if hasPositive && !hasNegative {
        positiveCount += 1
      } else if hasNegative && !hasPositive {
        negativeCount += 1
      } else {
        neutralCount += 1
      }
    }
    
    let total = positiveCount + negativeCount + neutralCount
    return SentimentDistribution(
      positive: total > 0 ? Double(positiveCount) / Double(total) : 0.33,
      negative: total > 0 ? Double(negativeCount) / Double(total) : 0.33,
      neutral: total > 0 ? Double(neutralCount) / Double(total) : 0.34
    )
  }
  
  private func calculateAverageLength(from posts: [PostItem]) -> Double {
    let totalLength = posts.reduce(0) { $0 + $1.content.count }
    return posts.isEmpty ? 0 : Double(totalLength) / Double(posts.count)
  }
  
  private func extractHashtags(from posts: [PostItem]) -> [HashtagUsage] {
    let allContent = posts.map { $0.content }.joined(separator: " ")
    let hashtagPattern = #"#\w+"#
    let regex = try? NSRegularExpression(pattern: hashtagPattern)
    let range = NSRange(location: 0, length: allContent.utf16.count)
    let matches = regex?.matches(in: allContent, range: range) ?? []
    
    let hashtags = matches.compactMap { match in
      Range(match.range, in: allContent).map { String(allContent[$0]) }
    }
    
    let hashtagCounts = Dictionary(grouping: hashtags, by: { $0 })
      .mapValues { $0.count }
      .sorted { $0.value > $1.value }
    
    return hashtagCounts.prefix(10).map { hashtag, count in
      HashtagUsage(hashtag: hashtag, usageCount: count, averageEngagement: 5.0)
    }
  }
  
  private func loadAnalyticsSettings() {
    analyticsEnabled = UserDefaults.standard.bool(forKey: "analyticsEnabled")
    dataRetentionDays = UserDefaults.standard.integer(forKey: "dataRetentionDays")
    if dataRetentionDays == 0 { dataRetentionDays = 30 }
  }
}

// MARK: - Supporting Types

public struct UserInsights: Codable {
  public let postingPattern: String
  public let contentThemes: [String]
  public let engagementStyle: String
  public let personalityTraits: [String]
  public let growthAreas: [String]
  public let strengths: [String]
  public let dailyPostCount: Int
  public let preferredContentTypes: [String]
  
  public init(postingPattern: String, contentThemes: [String], engagementStyle: String, personalityTraits: [String], growthAreas: [String], strengths: [String], dailyPostCount: Int, preferredContentTypes: [String]) {
    self.postingPattern = postingPattern
    self.contentThemes = contentThemes
    self.engagementStyle = engagementStyle
    self.personalityTraits = personalityTraits
    self.growthAreas = growthAreas
    self.strengths = strengths
    self.dailyPostCount = dailyPostCount
    self.preferredContentTypes = preferredContentTypes
  }
}

public struct ContentAnalytics: Codable {
  public let mostUsedTopics: [TopicFrequency]
  public let sentimentDistribution: SentimentDistribution
  public let bestPostingTimes: [String]
  public let contentLengthAnalysis: ContentLengthAnalysis
  public let hashtagUsage: [HashtagUsage]
  public let engagementPatterns: [String]
  
  public init(mostUsedTopics: [TopicFrequency], sentimentDistribution: SentimentDistribution, bestPostingTimes: [String], contentLengthAnalysis: ContentLengthAnalysis, hashtagUsage: [HashtagUsage], engagementPatterns: [String]) {
    self.mostUsedTopics = mostUsedTopics
    self.sentimentDistribution = sentimentDistribution
    self.bestPostingTimes = bestPostingTimes
    self.contentLengthAnalysis = contentLengthAnalysis
    self.hashtagUsage = hashtagUsage
    self.engagementPatterns = engagementPatterns
  }
}

public struct EngagementMetrics {
  public let totalPosts: Int
  public let totalLikes: Int
  public let totalReposts: Int
  public let totalReplies: Int
  public let avgLikesPerPost: Double
  public let avgRepostsPerPost: Double
  public let avgRepliesPerPost: Double
  public let engagementRate: Double
  public let bestPerformingPost: PostItem?
  public let engagementTrend: EngagementTrend
  
  public init(totalPosts: Int, totalLikes: Int, totalReposts: Int, totalReplies: Int, avgLikesPerPost: Double, avgRepostsPerPost: Double, avgRepliesPerPost: Double, engagementRate: Double, bestPerformingPost: PostItem?, engagementTrend: EngagementTrend) {
    self.totalPosts = totalPosts
    self.totalLikes = totalLikes
    self.totalReposts = totalReposts
    self.totalReplies = totalReplies
    self.avgLikesPerPost = avgLikesPerPost
    self.avgRepostsPerPost = avgRepostsPerPost
    self.avgRepliesPerPost = avgRepliesPerPost
    self.engagementRate = engagementRate
    self.bestPerformingPost = bestPerformingPost
    self.engagementTrend = engagementTrend
  }
}

public struct TrendingTopic: Codable, Identifiable {
  public let id = UUID()
  public let name: String
  public let frequency: Int
  public let trendDirection: TrendDirection
  public let relatedHashtags: [String]
  public let engagementScore: Double
  
  public init(name: String, frequency: Int, trendDirection: TrendDirection, relatedHashtags: [String], engagementScore: Double) {
    self.name = name
    self.frequency = frequency
    self.trendDirection = trendDirection
    self.relatedHashtags = relatedHashtags
    self.engagementScore = engagementScore
  }
}

public struct WeeklyReport {
  public let weekOf: Date
  public let userInsights: UserInsights
  public let contentAnalytics: ContentAnalytics
  public let engagementMetrics: EngagementMetrics
  public let trendingTopics: [TrendingTopic]
  public let recommendations: [Recommendation]
  
  public init(weekOf: Date, userInsights: UserInsights, contentAnalytics: ContentAnalytics, engagementMetrics: EngagementMetrics, trendingTopics: [TrendingTopic], recommendations: [Recommendation]) {
    self.weekOf = weekOf
    self.userInsights = userInsights
    self.contentAnalytics = contentAnalytics
    self.engagementMetrics = engagementMetrics
    self.trendingTopics = trendingTopics
    self.recommendations = recommendations
  }
}

public struct Recommendation: Identifiable {
  public let id = UUID()
  public let type: RecommendationType
  public let priority: Priority
  public let title: String
  public let description: String
  public let action: String
  
  public init(type: RecommendationType, priority: Priority, title: String, description: String, action: String) {
    self.type = type
    self.priority = priority
    self.title = title
    self.description = description
    self.action = action
  }
  
  public enum RecommendationType {
    case engagement
    case content
    case timing
    case wellbeing
    case growth
  }
  
  public enum Priority {
    case low
    case medium
    case high
  }
}

public struct TopicFrequency: Codable {
  public let name: String
  public let frequency: Int
  
  public init(name: String, frequency: Int) {
    self.name = name
    self.frequency = frequency
  }
}

public struct SentimentDistribution: Codable {
  public let positive: Double
  public let negative: Double
  public let neutral: Double
  
  public init(positive: Double, negative: Double, neutral: Double) {
    self.positive = positive
    self.negative = negative
    self.neutral = neutral
  }
}

public struct ContentLengthAnalysis: Codable {
  public let averageLength: Double
  public let optimalLength: Int
  public let lengthEngagementCorrelation: Double
  
  public init(averageLength: Double, optimalLength: Int, lengthEngagementCorrelation: Double) {
    self.averageLength = averageLength
    self.optimalLength = optimalLength
    self.lengthEngagementCorrelation = lengthEngagementCorrelation
  }
}

public struct HashtagUsage: Codable {
  public let hashtag: String
  public let usageCount: Int
  public let averageEngagement: Double
  
  public init(hashtag: String, usageCount: Int, averageEngagement: Double) {
    self.hashtag = hashtag
    self.usageCount = usageCount
    self.averageEngagement = averageEngagement
  }
}

public enum EngagementTrend {
  case increasing
  case decreasing
  case stable
}

public enum TrendDirection: String, Codable {
  case increasing = "increasing"
  case decreasing = "decreasing"
  case stable = "stable"
}

public struct UserInteraction {
  public let type: InteractionType
  public let content: String
  public let timestamp: Date
  
  public init(type: InteractionType, content: String, timestamp: Date) {
    self.type = type
    self.content = content
    self.timestamp = timestamp
  }
  
  public enum InteractionType: String, Codable {
    case like = "like"
    case repost = "repost"
    case reply = "reply"
    case share = "share"
    case view = "view"
  }
}
