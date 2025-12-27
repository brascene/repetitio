# YRepeat - Personal Productivity & Tracking App

A comprehensive iOS app that combines YouTube video repeating, habit tracking, fasting monitoring, daily tasks, calendar events, customizable checklists, and a dice roller for kids - all in one place with cloud sync.

## Features Overview

### 🎥 Player (YouTube Repeat)
- Load YouTube videos by URL or video ID
- Repeat specific sections with customizable start/end times
- Set repeat count (0 for infinite loop)
- Real-time playback monitoring
- Perfect for learning languages, music practice, or studying

### 📅 Daily Repeats
- Track daily recurring tasks and activities
- Organize your day with a clean, intuitive interface
- Quick add and completion tracking

### 📆 Calendar
- Manage events and appointments
- Visual calendar view
- Event scheduling and tracking

### ❤️ Habits
- Build and track positive habits
- Visual progress indicators
- Customizable habit goals
- Track streaks and completion rates

### 🌙 Fasting Tracker
- Monitor fasting periods with precise timing
- HealthKit integration for Activity Ring tracking
- Automatic permission management
- Save fasting sessions as mindful minutes
- Visual fasting progress

### ✅ Check (Checkbox Grid)
- Create customizable checkbox grids
- Configurable rows and columns
- Perfect for tracking progress, goals, or challenges
- Lock configuration after starting to maintain consistency
- Progress percentage tracking

### 🎲 Dice Roller
- Fun dice roller for kids and games
- **2D Mode**: Fast animated dice with rotation effects
- **3D Mode**: Realistic physics-based dice with SceneKit
  - Real 3D graphics with shadows and lighting
  - Physics simulation for authentic dice rolling
  - Support for 1-3 dice
  - Camera controls for viewing from different angles
- Roll history tracking
- Toggle between 2D and 3D modes in Settings

### ⚙️ Settings & Customization
- **Cloud Sync**: Sign in with Apple for automatic data backup
  - Sync across all your devices
  - Manual upload/download controls
  - Cloud data management
- **Appearance**: Customize app colors
  - Single color or gradient backgrounds
  - Color picker for personalization
- **Tab Visibility**: Show/hide tabs based on your needs
  - Customize which features appear in the tab bar
  - Streamline your experience
- **Account Management**: Secure authentication with Apple Sign In

## Architecture

### Core Technologies
- **SwiftUI**: Modern, declarative UI framework
- **Core Data**: Local data persistence
- **Firebase**: Cloud sync and authentication
  - Firestore for data storage
  - Firebase Auth with Apple Sign In
- **HealthKit**: Fasting data integration with Activity Rings
- **SceneKit**: 3D graphics for realistic dice physics
- **WKWebView**: YouTube video playback via IFrame API

### Key Components

#### Player Feature
- **YouTubePlayerController.swift**: Manages video playback and repeat logic
- **RepeatControlsView.swift**: UI for setting repeat parameters
- Timer-based monitoring for precise section repeating

#### Health Integration
- **ExerciseManager.swift**: HealthKit permission and data management
- **FastView.swift**: Fasting tracking interface
- Automatic Activity Ring integration

#### Data Management
- **FirebaseSyncManager.swift**: Handles cloud synchronization
- **AuthenticationManager.swift**: Apple Sign In integration
- Core Data entities for local storage
- Real-time sync status tracking

#### 3D Dice System
- **SceneKitDiceView.swift**: Physics-based 3D dice implementation
  - Realistic physics simulation
  - Custom dice textures with programmatic dot generation
  - Proper lighting and shadows
  - Quaternion-based face detection
- **DiceView.swift**: 2D animated dice with rotation effects

## Usage

### Getting Started
1. Launch the app
2. Choose the feature you want to use from the tab bar
3. Optional: Sign in with Apple for cloud sync (Settings → Account & Sync)

### YouTube Repeat
1. Go to the Player tab
2. Paste a YouTube URL or video ID
3. Tap "Load" to load the video
4. Set start time, end time, and repeat count
5. Tap "Start Repeat" to begin looping

### Fasting Tracker
1. Go to the Fast tab
2. Tap "Start Fasting" to begin a fast
3. Monitor your progress in real-time
4. Tap "End Fast" when done - it automatically saves to HealthKit

### Check Grid
1. Go to the Check tab
2. Configure the number of sections and boxes per section
3. Tap "Start with Configuration" to lock it in
4. Tap boxes to check/uncheck them
5. Track your progress percentage
6. Use "Delete All" to reset and start fresh

### Dice Roller
1. Go to the Dice tab
2. Select number of dice (1-3)
3. Tap "THROW DICE!" to roll
4. View roll history
5. Switch between 2D and 3D modes in Settings → Tab Visibility → 3D Dice

### Customization
1. Go to Settings
2. **Appearance**: Change background colors
3. **Tab Visibility**: Show/hide features you don't use
4. **Cloud Sync**: Enable backup and cross-device sync

## Setup in Xcode

### Prerequisites
- iOS 16.0+
- Xcode 15.0+
- Firebase project configured
- Apple Developer account for Sign in with Apple

### Installation
1. Clone the repository
2. Open `YRepeat.xcodeproj`
3. Add your `GoogleService-Info.plist` to the project
4. Select your development team in Signing & Capabilities
5. Enable HealthKit capability
6. Build and run on simulator or device

### Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Authentication → Sign-in method → Apple
3. Enable Firestore Database
4. Add Firestore security rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
5. Download `GoogleService-Info.plist` and add to project

## Requirements

- iOS 16.0 or later
- Xcode 15.0 or later
- Internet connection for:
  - YouTube content (Player feature)
  - Cloud sync (optional)
- HealthKit permissions for fasting tracking (optional)

## Project Structure

```
YRepeat/
├── YRepeat/
│   ├── YRepeatApp.swift              # App entry point
│   ├── ContentView.swift             # Main tab navigation
│   ├── PersistenceController.swift   # Core Data stack
│   │
│   ├── Player/
│   │   ├── YouTubePlayerController.swift
│   │   ├── YouTubePlayerView.swift
│   │   ├── RepeatControlsView.swift
│   │   └── TimeHelpers.swift
│   │
│   ├── Daily/
│   │   └── DailyRepeatView.swift
│   │
│   ├── Calendar/
│   │   └── CalendarView.swift
│   │
│   ├── Habits/
│   │   ├── HabitView.swift
│   │   └── HabitManager.swift
│   │
│   ├── Fasting/
│   │   ├── FastView.swift
│   │   └── ExerciseManager.swift
│   │
│   ├── Check/
│   │   ├── CheckView.swift
│   │   └── CheckBoxManager.swift
│   │
│   ├── Dice/
│   │   ├── DiceView.swift            # 2D dice
│   │   └── SceneKitDiceView.swift    # 3D dice
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── ThemeManager.swift
│   │   ├── AuthenticationManager.swift
│   │   └── FirebaseSyncManager.swift
│   │
│   └── YRepeat.xcdatamodeld/         # Core Data model
│
└── GoogleService-Info.plist           # Firebase config (add yourself)
```

## Security Notes

- **GoogleService-Info.plist** is excluded from git for security
- All sensitive configuration should be kept private
- HealthKit data stays on device unless explicitly synced
- Firebase security rules ensure users can only access their own data

## Privacy & Permissions

The app requests the following permissions:
- **Internet Access**: For YouTube videos and cloud sync
- **HealthKit**:
  - Read: Activity, mindful minutes
  - Write: Mindful session (fasting data)
  - Permission requested only when using Fast tab
- **Apple Sign In**: Optional, for cloud sync feature

## Technical Highlights

### YouTube Repeat Implementation
- Uses YouTube IFrame API for reliable video control
- Timer-based monitoring every 0.3s for precise loop points
- Maintains repeat count across loops

### 3D Dice Physics
- SceneKit physics engine with realistic gravity and collisions
- Quaternion-based rotation for accurate face detection
- Programmatically generated textures with proper dot placement
- Physically-based rendering for realistic materials
- Proper shadow mapping and lighting

### Cloud Sync Architecture
- Real-time Firestore synchronization
- Conflict resolution with timestamp-based merging
- Batch operations for efficiency
- Offline support with automatic retry

### HealthKit Integration
- Permission management with `getRequestStatusForAuthorization`
- Fasting saved as `HKCategoryTypeIdentifier.mindfulSession`
- Proper Activity Ring integration
- Background permission handling

## Contributing

This is a personal project, but suggestions and feedback are welcome!

## License

Private project - All rights reserved

---

**Note**: This app combines multiple productivity and tracking features into a single, unified experience with optional cloud sync across devices.
