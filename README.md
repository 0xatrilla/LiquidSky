
<img width="150" height="150" alt="butterfly" src="https://github.com/user-attachments/assets/2fb98b8a-6b5f-4ec2-87e4-4fa8fdde023f" />

# Horizon for Bluesky

A beautiful, modern Bluesky client for iOS built with SwiftUI and the AT Protocol.

<img width="200" height="550" alt="Screenshot 2025-09-07 at 02 12 53" src="https://github.com/user-attachments/assets/51b8c7d1-1876-471e-a4bf-67d1c9e79380" />
<img width="200" height="550" alt="Screenshot 2025-09-07 at 02 13 02" src="https://github.com/user-attachments/assets/d9d68059-4270-485e-92cd-502b74432c2d" />
<img width="200" height="550" alt="Screenshot 2025-09-07 at 02 13 13" src="https://github.com/user-attachments/assets/c1254eaf-3958-4d52-84c3-5f13b7f729e1" />
<img width="200" height="550" alt="Screenshot 2025-09-07 at 02 13 29" src="https://github.com/user-attachments/assets/50504651-6f3e-4268-bfa5-2a7547bb357a" />


## ✨ **Features**

### 🎨 **Core Features**
- **Modern SwiftUI Interface**: Beautiful, native iOS design with Liquid Glass effects
- **AT Protocol Integration**: Full Bluesky API support via ATProtoKit 0.31.2
- **Real-time Updates**: Live feed updates and notifications
- **Media Support**: Rich media handling with inline videos and images
- **Push Notifications**: Real-time notifications for new activity
- **iCloud Sync**: Cross-device synchronization of preferences and data
- **Rich Widgets**: Home screen widgets for quick access to activity
- **In-App Purchases**: Support development with optional tips

### 📱 **Social Features**
- **Timeline Viewing**: Browse your home timeline and custom feeds
- **Post Creation**: Compose and publish posts with media attachments
- **Interactions**: Like, repost, and reply to posts
- **Profile Management**: View and edit your profile
- **User Search**: Fast, optimized search for users, posts, and feeds
- **Content Filtering**: Customizable content preferences
- **Feed Summarization**: AI-powered feed summaries using Apple Intelligence

### 💬 **Direct Messages**
- **Real-time Chat**: Send and receive direct messages
- **Conversation Management**: View conversation history and unread counts
- **Message Status**: Read receipts and delivery indicators
- **Background Sync**: Messages sync across devices

### 📋 **Lists Management**
- **Create & Edit Lists**: Create custom user lists with descriptions
- **List Members**: Add/remove users from lists with bulk actions
- **Member Actions**: Follow, mute, block, and manage list members
- **List Discovery**: Browse and subscribe to public lists
- **Advanced Filtering**: Search and filter list members
- **Push Notifications**: Get notified of list changes

### 🌐 **Custom Domain Support**
- **Domain Linking**: Link your personal domain to your Bluesky profile
- **DNS Configuration**: Easy setup with TXT record verification
- **Profile Customization**: Enhanced profile with custom domain

### ⚙️ **Settings & Customization**
- **Tab Bar Customization**: Choose which tabs appear and their order
- **Theme Management**: Light, dark, and system theme support
- **Video Preferences**: Control autoplay, muting, and concurrent video limits
- **Display Options**: Timestamps, compact mode, and content preferences
- **Privacy Controls**: Mentions, replies, and quote permissions
- **Notification Settings**: Push and email notification preferences
- **Content Filters**: Sensitive content and media playback controls
- **User Actions**: Mute, block, and report users with real AT Protocol integration

### 💝 **Support & Tipping**
- **Multiple Tip Amounts**: Choose from small, medium, large, or custom tip amounts
- **Secure Transactions**: Apple's StoreKit handles all payment processing
- **Purchase History**: View your tipping history and total support
- **Restore Purchases**: Easily restore previous purchases across devices
- **Development Support**: Tips help cover costs and motivate improvements

### 🔔 **Notifications**
- **Push Notifications**: Real-time alerts for new activity
- **Background Processing**: Handle notifications even when app is closed
- **Deep Linking**: Navigate directly to content from notifications
- **Customizable**: Choose which notifications to receive
- **List Notifications**: Get notified when users are added/removed from lists

### ☁️ **iCloud Integration**
- **Cross-Device Sync**: Keep preferences in sync across all your devices
- **User Preferences**: Theme, video settings, and display options
- **Feed Subscriptions**: Your custom feed list stays synchronized
- **Block Lists**: Maintain consistent blocking across devices
- **Secure Storage**: All data encrypted and stored in your private iCloud
- **Automatic Sync**: Background synchronization when changes occur

### 📱 **Home Screen Widgets**
- **Follower Count Widget**: Beautiful display of your current follower count
- **Recent Notifications**: Show your latest Bluesky activity with smart type detection
- **Feed Updates**: Monitor activity from your favorite feeds
- **Multiple Sizes**: Support for small, medium, and large widget sizes
- **Real-time Updates**: Widgets refresh automatically with new data
- **Deep Linking**: Tap widgets to jump directly into the app

## 🏗️ **Architecture**

### **Modern SwiftUI Architecture**
- **SwiftUI 5.0**: Latest iOS UI framework with Liquid Glass effects
- **Swift Observation**: Native state management with `@Observable`
- **Async/Await**: Modern concurrency throughout the app
- **SwiftData**: Local data persistence with automatic sync
- **Modular Design**: Feature-based package organization

### **AT Protocol Integration**
- **ATProtoKit 0.31.2**: Latest Bluesky client library with chat support
- **Real-time Streaming**: Live updates via WebSocket connections
- **Rich Media Support**: Images, videos, and custom content
- **Feed Management**: Custom algorithm feeds and lists
- **User Management**: Profile editing and account management
- **Chat API**: Direct messaging with real-time synchronization

### **Search Architecture**
- **Optimized Search**: Debounced input with smart query prioritization
- **Handle Detection**: Fast user search for @handles and domains
- **Parallel Processing**: Efficient concurrent search across posts, users, and feeds
- **Result Caching**: Smart caching for improved performance

### **Lists Management Architecture**
- **Real AT Protocol**: Full integration with Bluesky's list APIs
- **Member Management**: Bulk actions and advanced filtering
- **Push Notifications**: Real-time list change notifications
- **Background Sync**: Automatic synchronization of list changes

### **Push Notification Architecture**
- **UserNotifications Framework**: Native iOS notification system
- **Background Processing**: Handle notifications when app is closed
- **Deep Linking**: Navigate to specific content from notifications
- **Custom Categories**: Different notification types for different actions
- **Permission Management**: Graceful handling of notification permissions

### **iCloud Sync Architecture**
- **CloudKit Framework**: Apple's cloud database service
- **Private Database**: Secure, user-specific data storage
- **Automatic Sync**: Background synchronization of changes
- **Conflict Resolution**: Smart merging of conflicting data
- **Offline Support**: Local caching with sync when online

### **Widget Architecture**
- **WidgetKit**: Native iOS widget framework
- **Timeline Provider**: Efficient data updates
- **App Groups**: Shared data between app and widgets
- **Deep Linking**: Navigate from widgets to app
- **Multiple Sizes**: Support for all widget sizes

### **StoreKit Architecture**
- **StoreKit 2**: Modern in-app purchase framework
- **Product Management**: Dynamic product loading and display
- **Transaction Handling**: Secure purchase processing and verification
- **Purchase History**: Local storage and Apple's receipt validation
- **Restore Purchases**: Cross-device purchase restoration
- **Testing**: StoreKit configuration for development and testing

## 🛠️ **Key Technologies**

- **SwiftUI** with iOS 26's Liquid Glass effects
- **Swift Observation** framework for state management
- **AT Protocol** via ATProtoKit 0.31.2 for Bluesky integration
- **Async/Await** for modern concurrency
- **SwiftData** for local data persistence
- **Nuke/NukeUI** for image loading and caching
- **AppRouter** for declarative navigation
- **Push Notifications** for real-time updates
- **CloudKit** for iCloud data synchronization
- **WidgetKit** for home screen widgets
- **StoreKit** for in-app purchases and tipping
- **Apple Intelligence** for feed summarization

## 🚀 **Getting Started**

### **Prerequisites**
- Xcode 16.0+
- iOS 17.0+
- Apple Developer Account (for push notifications and iCloud)

### **Installation**
1. Clone the repository
2. Open `Horizon.xcodeproj` in Xcode
3. Configure your signing and capabilities
4. Build and run on device or simulator

### **Configuration**
1. **Push Notifications**: Enable in Signing & Capabilities
2. **iCloud**: Configure CloudKit container
3. **App Groups**: Set up for widget data sharing
4. **StoreKit**: Add configuration file for testing

## 🎯 **Recent Updates**

### **v2.0 - Major Feature Release**
- ✅ **Direct Messages**: Full chat implementation with real-time sync
- ✅ **Lists Management**: Create, edit, and manage user lists
- ✅ **Custom Domain Support**: Link personal domains to profiles
- ✅ **Tab Bar Customization**: Customize tab order and visibility
- ✅ **Optimized Search**: Fast, debounced search with handle prioritization
- ✅ **Real Mute/Block**: AT Protocol integration for user actions
- ✅ **Feed Summarization**: AI-powered feed summaries
- ✅ **Enhanced UI**: Improved profile actions and navigation

## 🤝 **Contributing**

We welcome contributions! Please see our contributing guidelines for details.

## 📄 **License**

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 **Acknowledgments**

- **Bluesky Team** for the AT Protocol and ATProtoKit
- **Apple** for SwiftUI and the iOS platform
- **Community** for feedback and testing

---

**LiquidSky** - Where the sky meets the horizon of possibilities. 🌅
