# Follow/Unfollow Functionality Implementation

This document outlines the follow/unfollow functionality that has been implemented in LiquidSky for user profiles.

## Overview

The follow/unfollow system allows users to follow other users on Bluesky, creating a social connection that enables them to see posts from followed users in their timeline. The system includes:

- **FollowButton**: A reusable component for following/unfollowing users
- **CompactFollowButton**: A smaller version for use in lists and compact spaces
- **UserSearchView**: A comprehensive user search interface with follow functionality
- **ProfileView**: Enhanced profile view with follow/unfollow capabilities

## Components

### 1. FollowButton (`DesignSystem/Components/FollowButton.swift`)

A full-featured follow button component with three size variants:

- **Small**: For compact spaces (caption font, 12px corner radius)
- **Medium**: Standard size (subheadline font, 20px corner radius)  
- **Large**: Prominent display (body font, 24px corner radius)

**Features:**
- Optimistic UI updates for immediate feedback
- Loading states with progress indicators
- Error handling with fallback to server state
- Automatic followingURI management
- Responsive design with proper spacing

**Usage:**
```swift
FollowButton(profile: userProfile, size: .medium)
```

### 2. CompactFollowButton (`DesignSystem/Components/CompactFollowButton.swift`)

A streamlined follow button optimized for use in lists and other space-constrained areas.

**Features:**
- Compact design (caption font, 12px corner radius)
- Minimal padding for list integration
- Same core functionality as FollowButton
- Optimized for horizontal layouts

**Usage:**
```swift
CompactFollowButton(profile: userProfile)
```

### 3. UserSearchView (`FeedUI/List/UserSearchView.swift`)

A comprehensive user search interface that allows users to find and follow other users.

**Features:**
- Real-time search with debouncing
- User search results with follow buttons
- Loading, error, and empty states
- Navigation to user profiles
- Clean, intuitive interface

**Usage:**
```swift
UserSearchView(client: bskyClient)
```

### 4. UserSearchResultView (`FeedUI/List/UserSearchResultView.swift`)

Individual user search result items that display user information and follow status.

**Features:**
- User avatar, display name, and handle
- Bio preview (if available)
- Follower and post counts
- Follow/unfollow button
- Tap to navigate to profile

### 5. UserSearchService (`FeedUI/List/UserSearchService.swift`)

Service layer for user search functionality using the Bluesky API.

**Features:**
- Search actors using `searchActors` API
- Result mapping to Profile objects
- Error handling and state management
- Search cancellation support

## Profile Integration

### Enhanced ProfileView

The main `ProfileView` has been updated to use the new `FollowButton` component:

- **Relationship Status Section**: Shows follow/unfollow button for non-current users
- **Optimistic Updates**: Immediate UI feedback when following/unfollowing
- **Error Handling**: Graceful fallback on API failures
- **State Management**: Proper followingURI tracking for unfollow operations

### Follow State Management

The system properly manages follow state through:

- **followingURI Storage**: Tracks the URI of follow records for unfollow operations
- **Optimistic Updates**: Immediate UI changes for better user experience
- **Error Recovery**: Reverts optimistic updates on API failures
- **State Synchronization**: Keeps local state in sync with server state

## API Integration

### Follow Operations

**Follow User:**
```swift
// Create follow record (placeholder - needs correct API method)
let followRecord = try await client.blueskyClient.createFollowRecord(
  .init(actorDID: profile.did)
)
```

**Unfollow User:**
```swift
// Delete follow record using stored followingURI
try await client.blueskyClient.deleteRecord(.recordURI(atURI: followingURI))
```

### Current Limitations

The follow functionality currently has a placeholder implementation for creating follow records. The correct API method signature needs to be determined from ATProtoKit documentation or examples.

## Usage Examples

### Basic Follow Button
```swift
struct UserProfileRow: View {
  let user: Profile
  
  var body: some View {
    HStack {
      // User info...
      Spacer()
      FollowButton(profile: user, size: .medium)
    }
  }
}
```

### Compact Follow Button in List
```swift
struct UserListRow: View {
  let user: Profile
  
  var body: some View {
    HStack {
      // User info...
      Spacer()
      CompactFollowButton(profile: user)
    }
  }
}
```

### User Search Interface
```swift
struct SearchView: View {
  @StateObject var searchService = UserSearchService(client: bskyClient)
  
  var body: some View {
    UserSearchView(client: bskyClient)
  }
}
```

## Design Principles

### 1. Consistency
- All follow buttons use consistent visual design
- Standardized colors (blue for follow, green for following)
- Consistent iconography and typography

### 2. Accessibility
- Proper button semantics for screen readers
- Loading states with progress indicators
- Clear visual feedback for all states

### 3. Performance
- Optimistic UI updates for immediate feedback
- Efficient state management
- Minimal API calls

### 4. Error Handling
- Graceful degradation on API failures
- User-friendly error messages
- Automatic state recovery

## Future Enhancements

### 1. API Completion
- Implement correct follow record creation
- Add proper error handling for API failures
- Implement retry mechanisms

### 2. Enhanced Features
- Follow suggestions
- Follow lists management
- Follow analytics and insights

### 3. Integration
- Add follow buttons to more views
- Integrate with notification system
- Add follow-related preferences

## Testing

The components include comprehensive previews for development and testing:

- Different follow states (following/not following)
- Various button sizes
- Loading and error states
- Different profile configurations

## Dependencies

The follow/unfollow system depends on:

- **Models**: Profile data structure
- **Client**: BSkyClient for API communication
- **DesignSystem**: Base components and styling
- **ATProtoKit**: Bluesky protocol implementation

## Conclusion

The follow/unfollow functionality provides a solid foundation for social features in LiquidSky. The modular design allows for easy integration across the app, while the comprehensive error handling ensures a robust user experience. The system is ready for production use once the follow record creation API is properly implemented.
