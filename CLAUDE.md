# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LiquidSky is a **modern iOS application** built with **Swift and SwiftUI**, serving as a **Bluesky client** for the social network. The app targets **iOS 18.6+** and demonstrates sophisticated architecture with a focus on clean code organization, modern SwiftUI patterns, and comprehensive feature set.
✱iOS 26 and iPadOS 26** are being built with the beta SDK

## Development Commands

### Build & Development

**Primary Build:**
```bash
# Open project in Xcode
open Horizon.xcodeproj

# Build the main app
xcodebuild -project Horizon.xcodeproj -scheme LiquidSky -configuration Debug build

# Build for device
xcodebuild -project Horizon.xcodeproj -scheme LiquidSky -configuration Debug -destination 'platform=iOS,name=iPhone 16' build
```

**Testing:**
```bash
# Run unit tests
xcodebuild -project Horizon.xcodeproj -scheme LiquidSky test

# Run tests with specific test plan
xcodebuild -project Horizon.xcodeproj -scheme LiquidSky -testPlan FeaturesTests test

# Run tests for specific package
swift test --package-path Packages/Features
swift test --package-path Packages/Model
```

**Deployment:**
```bash
# Deploy to TestFlight
fastlane beta
```

## Architecture Overview

### Package-Based Architecture

The project follows a **workspace + package architecture** with clear separation between UI and business logic:

```
LiquidSky/
├── Horizon.xcodeproj/           # Main Xcode project (shell)
├── App/                        # App target and entry point
│   └── LiquidSkyApp.swift      # @main entry point
├── Packages/
│   ├── Features/               # UI feature packages
│   │   ├── Package.swift       # Feature package manifest
│   │   ├── Sources/
│   │   │   ├── AuthUI/        # Authentication UI
│   │   │   ├── ChatUI/        # Chat/messaging UI
│   │   │   ├── ComposerUI/    # Post composer UI
│   │   │   ├── DesignSystem/  # Shared design system
│   │   │   ├── FeedUI/        # Timeline feed UI
│   │   │   ├── MediaUI/       # Media handling UI
│   │   │   ├── NotificationsUI/  # Notifications UI
│   │   │   ├── PostUI/        # Post display UI
│   │   │   ├── ProfileUI/     # Profile UI
│   │   │   └── SettingsUI/    # Settings UI
│   │   └── Tests/             # Feature tests
│   └── Model/                  # Core model packages
│       ├── Package.swift       # Model package manifest
│       ├── Sources/
│       │   ├── Auth/          # Authentication logic
│       │   ├── Client/        # Network client
│       │   ├── Destinations/  # Navigation destinations
│       │   ├── InAppPurchase/ # Purchase logic
│       │   ├── Models/        # Data models
│       │   └── User/          # User management
│       └── Tests/             # Model tests
└── LiquidSkyWidgets/           # Widget extension
```

### Key Dependencies

**Core Frameworks:**
- **ATProtoKit 0.31.2**: Bluesky AT Protocol integration
- **SwiftUI**: Modern declarative UI framework (iOS 18.6+)
- **Swift Concurrency**: Heavy use of async/await patterns
- **Nuke/NukeUI 12.8.0**: Image loading and caching
- **AppRouter 1.0.2**: Declarative navigation
- **KeychainSwift 24.0.0**: Secure credential storage

**Testing:**
- **ViewInspector 0.10.1**: SwiftUI testing framework
- **Swift Testing**: Modern testing framework with @Test macros

**Apple Frameworks:**
- **UserNotifications**: Push notifications
- **CloudKit**: iCloud sync
- **WidgetKit**: Home screen widgets
- **StoreKit 2**: In-app purchases

### Architecture Patterns

**Modern SwiftUI Architecture:**
- **Pure SwiftUI**: Avoid UIKit unless absolutely necessary
- **@Observable**: Modern state management (iOS 17+)
- **MV Pattern**: Model-View pattern, avoiding unnecessary ViewModels
- **Environment-Based DI**: App-wide services via @Environment
- **Async/Await**: Modern concurrency throughout
- **Feature Organization**: Group related functionality

**Data Flow:**
- Views own their local state unless sharing is required
- State flows down, actions flow up
- Keep state as close to where it's used as possible
- Use @Environment for app-wide services (Router, Theme, CurrentAccount)
- Use @State and @Observable for feature-specific state

### State Management Guidelines

**When to use @State:**
- Local, ephemeral view state
- Simple values that don't need to be shared
- UI-specific state (toggle switches, text fields)

**When to use @Observable:**
- Shared state across multiple views
- Complex data models that need to be observed
- Services that manage app-wide functionality

**When to use @Environment:**
- App-wide services (Router, Theme, CurrentAccount, Client)
- Cross-feature dependencies
- Configuration and settings

## Coding Standards

### Swift Concurrency

- **Always use .task modifier** for async work tied to view lifecycle
- **Never use Task { } in onAppear** - this doesn't cancel automatically
- Handle errors gracefully with try/catch
- Use actors for expensive operations
- Ensure proper Sendable conformance for types crossing concurrency boundaries

### SwiftUI Best Practices

- Keep views small and focused
- Extract reusable components into their own files
- Use @ViewBuilder for conditional view composition
- Leverage SwiftUI's built-in animations and transitions
- Avoid massive body computations - break them down
- Implement Equatable on models to optimize SwiftUI diffing

### Error Handling

- Use optionals with if let/guard let for nil handling
- Never force-unwrap (!) without absolute certainty
- Use do/try/catch for error handling with meaningful error types
- Handle or propagate all errors - no empty catch blocks

### Testing Strategy

- Unit test business logic and data transformations
- Use SwiftUI Previews for visual testing
- Test @Observable classes independently
- Keep tests simple and focused
- Don't sacrifice code clarity for testability

## Key Technologies and Integration

### AT Protocol Integration

- Full Bluesky API support via ATProtoKit
- Real-time streaming via WebSocket connections
- Chat API for direct messaging
- User authentication and session management

### iCloud Integration

- CloudKit for cross-device synchronization
- Private database for secure user-specific data
- Automatic background synchronization
- Conflict resolution for concurrent changes

### Push Notifications

- UserNotifications framework for native iOS notifications
- Background processing when app is closed
- Deep linking to specific content from notifications
- Custom categories for different notification types

### In-App Purchases

- StoreKit 2 for modern in-app purchases
- Support for tipping/development funding
- Secure transaction processing and verification
- Purchase history and restoration across devices

### Home Screen Widgets

- WidgetKit for native iOS widgets
- Timeline provider for efficient data updates
- App groups for shared data between app and widgets
- Deep linking from widgets to app content

## Development Workflow

### Package Management

All development work should be done in the Swift packages (Packages/Features and Packages/Model), not in the main app project. The app project is merely a thin wrapper that imports and launches the package features.

### Testing

Use Swift Testing framework with @Test macros for modern, readable tests. Tests live in the package test targets alongside the source code.

### Building

Use XcodeBuildMCP tools for building, testing, and deployment when available. They provide better integration with the Xcode build system and simulator/device management.

## Configuration

### Entitlements

The app requires several key entitlements:
- Push notifications (aps-environment: development)
- CloudKit (com.apple.developer.icloud-services)
- App groups for cross-extension data sharing
- Keychain access for secure credential storage
- In-app purchases (StoreKit integration)

### Build Settings

- Minimum iOS deployment target: 18.6
- Swift tools version: 6.2
- Use modern build settings and asset catalogs
- Support both simulator and device builds

## Important Notes

- **Always use .task modifier** for async operations in views - it automatically cancels when the view disappears
- **Never use Task { } in onAppear** - this can cause memory leaks or crashes
- **Avoid unnecessary abstractions** - SwiftUI provides native state management
- **Keep the app shell minimal** - implement all features in the Swift packages
- **Embrace modern Swift features** - async/await, actors, property wrappers
- **Prioritize accessibility** - include VoiceOver support from the start
- **Test thoroughly** - use both unit tests and UI tests for comprehensive coverage

# Check

Perform comprehensive code quality and security checks.

## Primary Task:
Run `npm run check` (or project-specific check command) and resolve any resulting errors.

## Important:
- DO NOT commit any code during this process
- DO NOT change version numbers
- Focus only on fixing issues identified by checks

## Common Checks Include:
1. **Linting**: Code style and syntax errors
2. **Type Checking**: TypeScript/Flow type errors
3. **Unit Tests**: Failing test cases
4. **Security Scan**: Vulnerability detection
5. **Code Formatting**: Style consistency
6. **Build Verification**: Compilation errors

## Process:
1. Run the check command
2. Analyze output for errors and warnings
3. Fix issues in priority order:
   - Build-breaking errors first
   - Test failures
   - Linting errors
   - Warnings
4. Re-run checks after each fix
5. Continue until all checks pass

## For Different Project Types:
- **JavaScript/TypeScript**: `npm run check` or `yarn check`
- **Python**: `black`, `isort`, `flake8`, `mypy`
- **Rust**: `cargo check`, `cargo clippy`
- **Go**: `go vet`, `golint`
- **Swift**: `swift-format`, `swiftlint`

# Clean

Fix all code formatting and quality issues in the entire codebase.

## Python Projects:
Fix all `black`, `isort`, `flake8`, and `mypy` issues

### Steps:
1. **Format with Black**: `black .`
2. **Sort imports with isort**: `isort .`
3. **Fix flake8 issues**: `flake8 . --extend-ignore=E203`
4. **Resolve mypy type errors**: `mypy .`

## JavaScript/TypeScript Projects:
Fix all ESLint, Prettier, and TypeScript issues

### Steps:
1. **Format with Prettier**: `npx prettier --write .`
2. **Fix ESLint issues**: `npx eslint . --fix`
3. **Check TypeScript**: `npx tsc --noEmit`

## General Process:
1. Run automated formatters first
2. Fix remaining linting issues manually
3. Resolve type checking errors
4. Verify all tools pass with no errors
5. Review changes before committing

## Common Issues:
- Import order conflicts between tools
- Line length violations
- Unused imports/variables
- Type annotation requirements
- Missing return types
- Inconsistent quotes/semicolons

# Modern Swift Development

Write idiomatic SwiftUI code following Apple's latest architectural recommendations and best practices.

## Core Philosophy

- SwiftUI is the default UI paradigm for Apple platforms - embrace its declarative nature
- Avoid legacy UIKit patterns and unnecessary abstractions
- Focus on simplicity, clarity, and native data flow
- Let SwiftUI handle the complexity - don't fight the framework

## Architecture Guidelines

### 1. Embrace Native State Management

Use SwiftUI's built-in property wrappers appropriately:
- `@State` - Local, ephemeral view state
- `@Binding` - Two-way data flow between views
- `@Observable` - Shared state (iOS 17+)
- `@ObservableObject` - Legacy shared state (pre-iOS 17)
- `@Environment` - Dependency injection for app-wide concerns

### 2. State Ownership Principles

- Views own their local state unless sharing is required
- State flows down, actions flow up
- Keep state as close to where it's used as possible
- Extract shared state only when multiple views need it

### 3. Modern Async Patterns

- Use `async/await` as the default for asynchronous operations
- Leverage `.task` modifier for lifecycle-aware async work
- Avoid Combine unless absolutely necessary
- Handle errors gracefully with try/catch

### 4. View Composition

- Build UI with small, focused views
- Extract reusable components naturally
- Use view modifiers to encapsulate common styling
- Prefer composition over inheritance

### 5. Code Organization

- Organize by feature, not by type (avoid Views/, Models/, ViewModels/ folders)
- Keep related code together in the same file when appropriate
- Use extensions to organize large files
- Follow Swift naming conventions consistently

## Implementation Patterns

### Simple State Example
```swift
struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") { 
                count += 1 
            }
        }
    }
}
```

### Shared State with @Observable
```swift
@Observable
class UserSession {
    var isAuthenticated = false
    var currentUser: User?
    
    func signIn(user: User) {
        currentUser = user
        isAuthenticated = true
    }
}

struct MyApp: App {
    @State private var session = UserSession()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(session)
        }
    }
}
```

### Async Data Loading
```swift
struct ProfileView: View {
    @State private var profile: Profile?
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let profile {
                ProfileContent(profile: profile)
            } else if let error {
                ErrorView(error: error)
            }
        }
        .task {
            await loadProfile()
        }
    }
    
    private func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            profile = try await ProfileService.fetch()
        } catch {
            self.error = error
        }
    }
}
```

## Best Practices

### DO:
- Write self-contained views when possible
- Use property wrappers as intended by Apple
- Test logic in isolation, preview UI visually
- Handle loading and error states explicitly
- Keep views focused on presentation
- Use Swift's type system for safety

### DON'T:
- Create ViewModels for every view
- Move state out of views unnecessarily
- Add abstraction layers without clear benefit
- Use Combine for simple async operations
- Fight SwiftUI's update mechanism
- Overcomplicate simple features

## Testing Strategy

- Unit test business logic and data transformations
- Use SwiftUI Previews for visual testing
- Test @Observable classes independently
- Keep tests simple and focused
- Don't sacrifice code clarity for testability

## Modern Swift Features

- Use Swift Concurrency (async/await, actors)
- Leverage Swift 6 data race safety when available
- Utilize property wrappers effectively
- Embrace value types where appropriate
- Use protocols for abstraction, not just for testing

## Summary

Write SwiftUI code that looks and feels like SwiftUI. The framework has matured significantly - trust its patterns and tools. Focus on solving user problems rather than implementing architectural patterns from other platforms.