import Foundation
import Models

#if canImport(UIKit)
  import UIKit
#endif
#if canImport(FoundationModels)
  import FoundationModels
#endif

@MainActor
@Observable
public class FeedSummaryService {
  public static let shared = FeedSummaryService()
  // Apple Intelligence session will be created lazily at use time to avoid init-time crashes on unsupported devices
  // Device support enabled: rely on iOS availability and safe fallbacks

  private init() {}

  public func summarizeFeedPosts(_ posts: [Any], feedName: String) async -> String {
    // Filter posts from last 12 hours using reflection
    let twelveHoursAgo = Date().addingTimeInterval(-12 * 60 * 60)
    let recentPosts = posts.filter { post in
      if let indexedAt = getIndexedAt(from: post) {
        return indexedAt >= twelveHoursAgo
      }
      return false
    }
    // Prefer newest posts first for summarization
    let sortedRecentPosts = recentPosts.sorted {
      (getIndexedAt(from: $0) ?? .distantPast) > (getIndexedAt(from: $1) ?? .distantPast)
    }

    guard !sortedRecentPosts.isEmpty else {
      return "No posts found in the last 12 hours for \(feedName)."
    }

    // Try Apple Intelligence first, fallback to basic summary
    let aiEnabledByUser = SettingsService.shared.aiSummariesEnabled
    let aiDeviceExperimental = SettingsService.shared.aiDeviceExperimentalEnabled
    #if targetEnvironment(simulator)
      let aiGatedOK = aiEnabledByUser
    #else
      let aiGatedOK = aiEnabledByUser && aiDeviceExperimental
    #endif
    #if canImport(FoundationModels)
      if #available(iOS 26.0, *), aiGatedOK {
        #if DEBUG
          print("AI Summary: Preconditions met. iOS >= 26.0, user enabled = true")
          print("AI Summary: Device info => \(deviceInfo())")
          print("AI Summary: Preparing to create LanguageModelSession...")
        #endif
        if let session = makeLanguageModelSession() {
          #if DEBUG
            print(
              "AI Summary: LanguageModelSession created successfully. Preparing to request response..."
            )
          #endif
          return await generateAISummary(
            posts: sortedRecentPosts, feedName: feedName, session: session)
        } else {
          #if DEBUG
            print("AI Summary: Failed to create LanguageModelSession (nil returned). Falling back.")
          #endif
        }
      }
    #endif
    #if DEBUG
      if !aiEnabledByUser {
        print("AI Summary: Disabled by user setting; using basic summary.")
      } else {
        #if targetEnvironment(simulator)
          print("AI Summary: Not available or session init failed; using basic summary.")
        #else
          if !aiDeviceExperimental {
            print("AI Summary: Device path gated by experimental toggle OFF; using basic summary.")
          } else {
            print("AI Summary: Not available or session init failed; using basic summary.")
          }
        #endif
      }
    #endif
    return generateBasicSummary(posts: recentPosts, feedName: feedName)
  }

  private func getIndexedAt(from post: Any) -> Date? {
    let mirror = Mirror(reflecting: post)
    for child in mirror.children {
      if child.label == "indexedAt", let date = child.value as? Date {
        return date
      }
    }
    return nil
  }

  private func getPostContent(from post: Any) -> String? {
    let mirror = Mirror(reflecting: post)
    for child in mirror.children {
      if child.label == "content", let content = child.value as? String {
        return content
      }
    }
    return nil
  }

  private func getAuthorHandle(from post: Any) -> String? {
    let mirror = Mirror(reflecting: post)
    for child in mirror.children {
      if child.label == "author" {
        let authorMirror = Mirror(reflecting: child.value)
        for authorChild in authorMirror.children {
          if authorChild.label == "handle", let handle = authorChild.value as? String {
            return handle
          }
        }
      }
    }
    return nil
  }

  private func getAuthorDisplayName(from post: Any?) -> String? {
    guard let post = post else { return nil }
    let mirror = Mirror(reflecting: post)

    for child in mirror.children {
      if child.label == "author" {
        let authorMirror = Mirror(reflecting: child.value)
        for authorChild in authorMirror.children {
          if authorChild.label == "displayName",
            let displayName = authorChild.value as? String,
            !displayName.isEmpty
          {
            return displayName
          }
        }
      }
    }
    return nil
  }

  #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func makeLanguageModelSession() -> LanguageModelSession? {
      // Lazily create the session only when needed. If creation fails due to device capability, return nil.
      return LanguageModelSession {
        """
        You are an expert social media content summarizer. Your task is to create concise, insightful summaries of social media posts from the last 12 hours.

        Focus on:
        - Key themes and topics being discussed
        - Notable conversations or trending subjects  
        - Important announcements or news
        - Community sentiment and reactions

        Keep summaries engaging and informative while being concise. Highlight the most interesting and relevant content.
        """
      }
    }

    @available(iOS 26.0, *)
    private func generateAISummary(posts: [Any], feedName: String, session: LanguageModelSession)
      async -> String
    {
      // Prepare post content for AI analysis
      let entries: [String] = posts.compactMap { post -> String? in
        guard let content = getPostContent(from: post),
          let handle = getAuthorHandle(from: post)
        else { return nil }
        let displayName = getAuthorDisplayName(from: post) ?? handle
        let timeAgo = getIndexedAt(from: post).map { formatRelativeTime($0) } ?? "unknown time"
        return
          "@\(handle) (\(displayName)) - \(timeAgo):\n\(truncateContent(content, maxLength: 400))\n"
      }

      // Heuristic character budgets to avoid 4096-token window (approx ~3 chars/token). Leave headroom.
      let maxPromptChars = 9000

      // Try a direct single-pass summary with trimmed content
      let directSummary = await attemptDirectSummary(
        entries: entries, feedName: feedName, session: session, maxChars: maxPromptChars)
      if let directSummary { return directSummary }

      // If still too large or failed with context window, use hierarchical chunking
      #if DEBUG
        print("AI Summary: Falling back to hierarchical chunking due to size limits…")
      #endif
      if let chunked = await generateHierarchicalSummary(
        entries: entries, feedName: feedName, session: session)
      {
        return chunked
      }

      // Final fallback
      return generateBasicSummary(posts: posts, feedName: feedName)
    }

    @available(iOS 26.0, *)
    private func attemptDirectSummary(
      entries: [String], feedName: String, session: LanguageModelSession, maxChars: Int
    ) async -> String? {
      // Reduce to fit char budget
      var selected: [String] = []
      var total = 0
      for entry in entries {
        let sep = selected.isEmpty ? 0 : 5  // approx for "\n---\n"
        if total + entry.count + sep > maxChars { break }
        selected.append(entry)
        total += entry.count + sep
      }
      guard !selected.isEmpty else { return nil }

      let combinedContent = selected.joined(separator: "\n---\n")
      let prompt = """
        Please analyze and summarize the following social media posts from the "\(feedName)" feed over the last 12 hours.

        Posts (\(selected.count) included):
        \(combinedContent)

        Create a comprehensive, engaging summary in 2-3 well-structured paragraphs that captures:
        1. Main themes and topics being discussed across the community
        2. Notable conversations, trending subjects, and key developments
        3. Important insights, announcements, or interesting points raised
        4. Overall community sentiment and engagement patterns

        Write in a conversational, engaging style as if explaining to a friend what they missed. Focus on the most interesting and relevant content. Each paragraph should be 3-5 sentences long and flow naturally into the next.
        """

      do {
        #if DEBUG
          print(
            "AI Summary: Attempting direct summary (\(prompt.count) chars, \(selected.count) posts)…"
          )
        #endif
        let response = try await session.respond(to: prompt)
        #if DEBUG
          print("AI Summary: Received direct response (\(response.content.count) chars)")
        #endif
        return
          "**AI-Powered Feed Summary - Last 12 Hours**\n\n\(response.content)\n\n*Summary generated using Apple Intelligence*"
      } catch {
        let errText = String(describing: error)
        if errText.localizedCaseInsensitiveContains("exceeds the maximum allowed context size") {
          #if DEBUG
            print("AI Summary: Direct attempt exceeded context window; will chunk.")
          #endif
          return nil
        }
        #if DEBUG
          print("AI Summary: Direct attempt failed: \(error)")
        #endif
        return nil
      }
    }

    @available(iOS 26.0, *)
    private func generateHierarchicalSummary(
      entries: [String], feedName: String, session: LanguageModelSession
    ) async -> String? {
      // Chunk entries into bite-sized groups and summarize each, then summarize the summaries
      let maxChunkChars = 6000
      var chunks: [[String]] = []
      var current: [String] = []
      var running = 0
      for entry in entries {
        let sep = current.isEmpty ? 0 : 5
        if running + entry.count + sep > maxChunkChars {
          if !current.isEmpty { chunks.append(current) }
          current = [entry]
          running = entry.count
        } else {
          current.append(entry)
          running += entry.count + sep
        }
      }
      if !current.isEmpty { chunks.append(current) }

      var partials: [String] = []
      partials.reserveCapacity(chunks.count)

      for (idx, chunk) in chunks.enumerated() {
        let body = chunk.joined(separator: "\n---\n")
        let prompt = """
          You are summarizing part \(idx + 1) of \(chunks.count) from the "\(feedName)" feed.

          Posts in this part (\(chunk.count)):
          \(body)

          Produce a concise paragraph summary (2-3 sentences) of the key themes, notable discussions, and sentiment from this section.
          Focus on the most important and interesting content. No bullet points - write in flowing paragraph form.
          """
        do {
          #if DEBUG
            print(
              "AI Summary: Summarizing chunk \(idx + 1)/\(chunks.count) (\(prompt.count) chars)…")
          #endif
          let response = try await session.respond(to: prompt)
          partials.append(response.content)
        } catch {
          #if DEBUG
            print("AI Summary: Chunk \(idx + 1) failed: \(error). Skipping.")
          #endif
        }
      }

      guard !partials.isEmpty else { return nil }

      let combinedBullets = partials.joined(separator: "\n")
      let finalPrompt = """
        The following are paragraph summaries of multiple parts from the "\(feedName)" feed over the last 12 hours:

        \(combinedBullets)

        Write a single cohesive summary in 2-3 well-structured paragraphs capturing:
        - Main themes and topics being discussed across the community
        - Notable conversations, trending subjects, and key developments
        - Important insights, announcements, or interesting points raised
        - Overall community sentiment and engagement patterns

        Write in a conversational, engaging style as if explaining to a friend what they missed. Each paragraph should be 3-5 sentences long and flow naturally into the next.
        """
      do {
        #if DEBUG
          print(
            "AI Summary: Requesting final synthesis (\(finalPrompt.count) chars, from \(partials.count) chunk summaries)…"
          )
        #endif
        let response = try await session.respond(to: finalPrompt)
        return
          "**AI-Powered Feed Summary - Last 12 Hours**\n\n\(response.content)\n\n*Summary generated using Apple Intelligence*"
      } catch {
        #if DEBUG
          print("AI Summary: Final synthesis failed: \(error)")
        #endif
        return nil
      }
    }
  #endif

  private func generateBasicSummary(posts: [Any], feedName: String) -> String {
    let postCount = posts.count
    let contributors = Set(posts.compactMap { getAuthorHandle(from: $0) })
    let contributorCount = contributors.count

    // Group posts by author for better organization
    let postsByAuthor = Dictionary(grouping: posts) { post in
      getAuthorHandle(from: post) ?? "Unknown"
    }

    var summary =
      "Over the last 12 hours, your feed has been quite active with **\(postCount)** posts from **\(contributorCount)** contributors. "

    // Create detailed content summary by author
    let sortedAuthors = postsByAuthor.sorted { $0.value.count > $1.value.count }

    // Generate paragraph-style summary
    let topContributors = sortedAuthors.prefix(5)
    let contributorNames = topContributors.map { author, posts in
      let displayName = getAuthorDisplayName(from: posts.first) ?? author
      return displayName != author ? "\(displayName) (@\(author))" : "@\(author)"
    }

    if !contributorNames.isEmpty {
      summary +=
        "The most active contributors include \(contributorNames.joined(separator: ", ")). "
    }

    // Add content themes
    var contentThemes: [String] = []
    for (_, authorPosts) in topContributors {
      for post in authorPosts.prefix(2) {
        if let content = getPostContent(from: post) {
          let truncatedContent = truncateContent(content, maxLength: 200)
          contentThemes.append(truncatedContent)
        }
      }
    }

    if !contentThemes.isEmpty {
      summary +=
        "Key discussions included topics around \(contentThemes.prefix(3).joined(separator: ", ")). "
    }

    summary +=
      "The community has been engaged with various topics, showing active participation and thoughtful discussions throughout the day."

    if sortedAuthors.count > 5 {
      summary +=
        " Additionally, \(sortedAuthors.count - 5) other contributors also shared their thoughts and updates."
    }

    let aiAvailability: String = {
      #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
          return
            "Apple Intelligence may be available on iOS 26.0+, but the device may not support it or initialization failed—using fallback summary."
        } else {
          return "Requires iOS 26.0+ for Apple Intelligence integration."
        }
      #else
        return "Apple Intelligence framework not available in this build."
      #endif
    }()

    summary += "*Basic summary generated. \(aiAvailability)*"

    return summary
  }

  private func formatRelativeTime(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
  }

  private func truncateContent(_ content: String, maxLength: Int) -> String {
    if content.count <= maxLength {
      return content
    }

    let truncated = String(content.prefix(maxLength))
    if let lastSpace = truncated.lastIndex(of: " ") {
      return String(truncated[..<lastSpace]) + "..."
    } else {
      return truncated + "..."
    }
  }

  private func deviceInfo() -> String {
    #if canImport(UIKit)
      let device = UIDevice.current
      return "iOS \(device.systemVersion), model: \(device.model), name: \(device.name)"
    #else
      return "Unknown platform"
    #endif
  }
}
