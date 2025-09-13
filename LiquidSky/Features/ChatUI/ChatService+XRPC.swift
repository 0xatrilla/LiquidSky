// TODO: Re-enable ChatService extension when chat functionality is ready
/*
import Client
import Foundation

extension ChatService {
  struct EmptyResponse: Decodable {}
  struct ChatErrorResponse: Decodable {
    let error: String?
    let message: String?
  }

  // Test basic authentication without chat API
  func testBasicAuthentication() async throws -> Bool {
    print("🧪 Testing basic authentication...")

    do {
      let session = try await client.protoClient.getUserSession()
      print("✅ Session exists for: \(session?.handle ?? "unknown")")

      // Try to get a basic profile to test authentication
      let profile = try await client.blueskyClient.getProfile(for: session?.handle ?? "")
      print("✅ Basic authentication test passed for: \(profile.handle)")
      return true
    } catch {
      print("❌ Basic authentication test failed: \(error)")
      return false
    }
  }

  // Use ATProtoKit's built-in XRPC functionality instead of raw HTTP
  func performXrpcCall<T: Decodable>(
    _ endpoint: String, method: String = "GET", parameters: [String: Any]? = nil
  ) async throws -> T {
    print("🔄 Making authenticated XRPC call to: \(endpoint)")

    // First, test basic authentication
    let authWorks = try await testBasicAuthentication()
    if !authWorks {
      print("❌ Basic authentication failed, aborting chat API call")
      throw ChatError.invalidResponse
    }

    // First, verify we have a valid session
    guard let session = try? await client.protoClient.getUserSession() else {
      print("❌ No valid session found")
      throw ChatError.invalidResponse
    }

    print("✅ Session verified for: \(session?.handle ?? "unknown")")

    // Try using ATProtoKit's XRPC functionality if available
    // For now, fall back to manual implementation with better token extraction

    let url = URL(string: "https://bsky.social/xrpc/\(endpoint)")!
    var request = URLRequest(url: url)
    request.httpMethod = method

    // Add query parameters if any
    if let params = parameters, method == "GET" {
      var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
      components.queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
      request.url = components.url
    } else if let params = parameters, method == "POST" {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try JSONSerialization.data(withJSONObject: params)
    }

    // Simplified token extraction - try the most direct approach first
    var token: String?

    // Try to get token from session - look for the most common property names
    if let session = try? await client.protoClient.getUserSession() {
      let mirror = Mirror(reflecting: session)
      for child in mirror.children {
        if let label = child.label,
          let tokenValue = child.value as? String,
          tokenValue.hasPrefix("eyJ")
        {
          // Look for access-related properties
          if label.lowercased().contains("access") || label.lowercased().contains("token")
            || label == "jwt"
          {
            token = tokenValue
            print("✅ Found access token in session property: \(label)")
            break
          }
        }
      }
    }

    // If still no token, try the configuration
    if token == nil {
      let configMirror = Mirror(reflecting: client.configuration)
      for child in configMirror.children {
        if let label = child.label,
          let tokenValue = child.value as? String,
          tokenValue.hasPrefix("eyJ")
        {
          if label.lowercased().contains("access") || label.lowercased().contains("token") {
            token = tokenValue
            print("✅ Found access token in config property: \(label)")
            break
          }
        }
      }
    }

    if let token = token {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
      print("✅ Using access token for request")
    } else {
      print("⚠️ No access token found - this will likely cause authentication failure")
    }

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw ChatError.invalidResponse
    }

    if httpResponse.statusCode == 401 {
      print("❌ Authentication failed - invalid or expired token")
      if let responseString = String(data: data, encoding: .utf8) {
        print("Auth error response: \(responseString)")
      }
      // Check if this is a chat-specific permission issue
      if endpoint.contains("chat.bsky") {
        throw ChatError.conversationNotFound  // We'll treat this as a chat permission issue
      }
      throw ChatError.invalidResponse
    }

    if httpResponse.statusCode == 403 {
      print("❌ Forbidden - user may not have chat permissions")
      if endpoint.contains("chat.bsky") {
        throw ChatError.conversationNotFound  // Chat not available for this user
      }
      throw ChatError.invalidResponse
    }

    guard 200..<300 ~= httpResponse.statusCode else {
      print("❌ XRPC call failed: \(endpoint)")
      print("Status code: \(httpResponse.statusCode)")
      print("Request URL: \(url)")
      if let responseString = String(data: data, encoding: .utf8) {
        print("Response: \(responseString)")
        // Try to parse error response
        if let errorResponse = try? JSONDecoder().decode(ChatErrorResponse.self, from: data) {
          print("Error details: \(errorResponse)")
        }
      }
      throw ChatError.invalidResponse
    }

    // Add success logging
    print("✅ XRPC call succeeded: \(endpoint)")

    return try JSONDecoder().decode(T.self, from: data)
  }
}
*/
import Client
import Foundation
