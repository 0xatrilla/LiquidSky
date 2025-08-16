# LiquidSky 🧊✨


A modern, beautiful Bluesky client for iOS built with SwiftUI and the latest iOS 26 SDK features.

## 🌟 About

LiquidSky (formerly known as GlowSky, RetroSky, IcySky) is a native iOS client for [Bluesky](https://bsky.social), the decentralized social network built on the AT Protocol. This project showcases modern iOS development practices with a focus on beautiful, fluid UI powered by the latest SwiftUI capabilities.

### ✨ Core Features

- **🧊 Liquid Glass UI**: Leverages iOS 26's new Liquid Glass effects for a stunning, modern interface
- **🚀 Native Performance**: Built entirely in SwiftUI for smooth, responsive interactions
- **🏗️ Modular Architecture**: Clean separation between UI and business logic using Swift Package Manager
- **🔗 AT Protocol Integration**: Full support for Bluesky's decentralized social features
- **🔐 Secure Authentication**: Login with app passwords, stored securely in iOS Keychain
- **🎨 Beautiful Design System**: Custom components with consistent blue theme matching Bluesky brand

## ✅ **Implemented Features**

### 🔐 **Authentication & User Management**
- **Secure Login**: App password authentication with iOS Keychain
- **Session Management**: Automatic token refresh and session persistence
- **User Profiles**: Complete profile viewing with bio, stats, and relationship status
- **Current User**: Full profile management and settings access

### 📱 **Feed & Timeline**
- **Following Timeline**: View posts from people you follow
- **Custom Feeds**: Browse and explore custom Bluesky feeds
- **Feed Discovery**: Search and discover new feeds
- **Recent Feeds**: Quick access to recently viewed feeds
- **Pull-to-Refresh**: Swipe down to refresh feed content
- **Infinite Scrolling**: Seamless pagination for continuous browsing

### 📝 **Post System**
- **Post Composition**: Create new posts with rich text editor
- **Reply System**: Reply to posts with threaded conversations
- **Post Actions**: Like, repost, and interact with posts
- **Post Threads**: View complete conversation threads
- **Post Detail**: Full post viewing with context
- **Media Support**: Posts with images, videos, and external links

### 🎥 **Advanced Media System**
- **Inline Video Playback**: Videos play directly in the feed
- **Smart Autoplay**: Intelligent video playback management
- **Video Controls**: Play/pause, mute, progress bar, and seeking
- **Performance Optimization**: Limits concurrent videos for smooth performance
- **Image Support**: High-quality image loading and display
- **Media Grid**: Beautiful media layouts for multiple images/videos
- **Full-Screen Media**: Immersive media viewing experience

### 👤 **Profile & Social Features**
- **Profile Viewing**: Complete user profiles with stats and bio
- **Profile Posts**: View posts, replies, media, and threads by user
- **Profile Likes**: See what posts a user has liked
- **Relationship Status**: Following, followers, blocking, and muting indicators
- **Profile Sharing**: Share profiles with custom share text
- **Avatar Management**: Profile picture display and management

### ⚙️ **Settings & Customization**
- **Theme Management**: Light, dark, and system theme support
- **Video Preferences**: Control autoplay, muting, and concurrent video limits
- **Display Options**: Timestamps, compact mode, and content preferences
- **Privacy Controls**: Mentions, replies, and quote permissions
- **Notification Settings**: Push and email notification preferences
- **Content Filters**: Sensitive content and media playback controls

### 🔔 **Notifications**
- **Real-time Notifications**: Like, follow, repost, and mention alerts
- **Notification Grouping**: Smart grouping of similar notifications
- **Notification Types**: Different icons and colors for various activities
- **Quick Actions**: Respond directly from notifications

### 🎨 **Design System**
- **Custom Components**: Reusable UI components with consistent styling
- **Blue Theme**: Beautiful blue color scheme matching Bluesky brand
- **Glass Effects**: Modern translucent and blur effects
- **Responsive Design**: Adaptive layouts for different screen sizes
- **Accessibility**: VoiceOver support and accessibility features
- **Animations**: Smooth transitions and micro-interactions

### 📱 **Navigation & UX**
- **Tab Navigation**: Feed, Profile, Notifications, and Settings tabs
- **Sheet Presentations**: Modal views for composer and media
- **Deep Linking**: Navigate directly to posts, profiles, and feeds
- **Gesture Support**: Swipe gestures and intuitive interactions
- **Search**: Find feeds, users, and content quickly

## 🚧 **In Progress Features**

- **Multi-Account Support**: Switch between multiple Bluesky accounts
- **Advanced Search**: Enhanced search with filters and suggestions
- **Bookmarks**: Save and organize favorite posts
- **Offline Support**: Cache content for offline viewing
- **Push Notifications**: Real-time push notification delivery

## 🛠️ **Technical Details**

### Requirements

- **iOS 26.0+** 
- **Xcode 26.0+** with iOS 26 SDK
- **Swift 6.2+**

### Architecture

LiquidSky follows a modular architecture with two main Swift packages:

- **Features Package**: All UI components and views
  - AuthUI, FeedUI, PostUI, ProfileUI, SettingsUI, NotificationsUI, MediaUI, ComposerUI
  - Custom DesignSystem with reusable components
  
- **Model Package**: Core business logic and data
  - Network layer (AT Protocol client via ATProtoKit)
  - Data models and state management
  - Authentication and user management
  - SwiftData integration for local storage

### Key Technologies

- **SwiftUI** with iOS 26's Liquid Glass effects
- **Swift Observation** framework for state management
- **AT Protocol** via ATProtoKit for Bluesky integration
- **Async/Await** for modern concurrency
- **SwiftData** for local data persistence
- **Nuke/NukeUI** for image loading and caching
- **AppRouter** for declarative navigation


## 🤝 **Contributing**

While this is currently a personal exploration project, feedback and ideas are welcome! Feel free to:
- Open issues for bugs or feature requests
- Share UI/UX suggestions
- Discuss architectural improvements
- Contribute to the codebase

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 **What Makes LiquidSky Special**

LiquidSky isn't just another Bluesky client - it's a showcase of modern iOS development:

- **🎨 Beautiful Design**: Stunning UI that rivals the best social media apps
- **⚡ Performance**: Optimized for smooth scrolling and video playback
- **🔒 Privacy-First**: Secure authentication and data handling
- **🌐 Open Protocol**: Built on the decentralized AT Protocol
- **📱 Native Experience**: Leverages the latest iOS capabilities
- **🏗️ Clean Architecture**: Well-structured, maintainable codebase

Experience the future of social media with LiquidSky - where beautiful design meets decentralized technology! ✨
