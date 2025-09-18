import ATProtoKit
import Auth
import Testing
import Foundation
import Models

struct AuthTests {

  @Test func testLogoutClearsConfigurationAndEmitsNil() async throws {
    let accountManager = AccountManager()
    let auth = Auth(accountManager: accountManager)

    // Start collecting updates before triggering logout
    let task = Task {
      var result: ATProtocolConfiguration?
      for await config in auth.configurationUpdates {
        result = config
        break
      }
      return result
    }

    // Logout should succeed even if there's no active session
    do {
      try await auth.logout()
    } catch {
      // Expected: logout might fail when no session exists, but state should still be cleared
    }

    let emittedConfig = await task.value
    #expect(emittedConfig == nil)
  }

  @Test func testRefreshEmitsNilOnFailure() async throws {
    let accountManager = AccountManager()
    let auth = Auth(accountManager: accountManager)
    
    // Start collecting updates before triggering refresh
    let task = Task {
      var result: ATProtocolConfiguration?
      for await config in auth.configurationUpdates {
        result = config
        break
      }
      return result
    }
    
    await auth.refresh()
    
    let emittedConfig = await task.value
    #expect(emittedConfig == nil)
    #expect(auth.configuration == nil)
  }

  @Test func testAuthInstanceCreation() {
    let accountManager1 = AccountManager()
    let accountManager2 = AccountManager()
    let auth1 = Auth(accountManager: accountManager1)
    let auth2 = Auth(accountManager: accountManager2)

    // Auth instances always have a configuration, even in fresh login state
    #expect(auth1.configuration != nil)
    #expect(auth2.configuration != nil)
    #expect(auth1.currentAccountId == nil)
    #expect(auth2.currentAccountId == nil)
  }
  
  @Test func testConfigurationUpdatesStream() async throws {
    let accountManager = AccountManager()
    let auth = Auth(accountManager: accountManager)

    // Test that logout emits nil configuration
    let logoutTask = Task {
      var result: ATProtocolConfiguration?
      for await config in auth.configurationUpdates {
        result = config
        break
      }
      return result
    }

    // Logout should succeed even if there's no active session
    do {
      try await auth.logout()
    } catch {
      // Expected: logout might fail when no session exists, but state should still be cleared
    }
    let logoutConfig = await logoutTask.value
    #expect(logoutConfig == nil)

    // Test that refresh failure emits nil configuration
    let refreshTask = Task {
      var result: ATProtocolConfiguration?
      for await config in auth.configurationUpdates {
        result = config
        break
      }
      return result
    }

    // Refresh is expected to fail when no session exists
    await auth.refresh()
    let refreshConfig = await refreshTask.value
    #expect(refreshConfig == nil)
  }
}