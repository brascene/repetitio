# YRepeat - YouTube Repeat for iOS

Native iOS app that plays YouTube videos and allows repeating specific sections, just like the Chrome extension.

## Features

- 🎥 Load YouTube videos by URL or video ID
- 🔁 Repeat specific sections (start time → end time)
- 🔢 Set repeat count (0 for infinite loop)
- ⏱️ Real-time display of current time and duration
- 📱 Native iOS interface matching the extension UI

## Architecture

This app is a direct port of the YouTube Repeat Chrome extension, maintaining the same functionality:

### Core Components

1. **YouTubePlayerController.swift**
   - Manages WKWebView with YouTube IFrame API
   - Handles repeat logic with timer-based checking (like `content.js:392`)
   - JavaScript bridge for video control

2. **RepeatControlsView.swift**
   - UI matching the extension's `popup.html`
   - Input fields for start time, end time, and repeat count
   - Status display and action buttons

3. **TimeHelpers.swift**
   - Time conversion functions ported from `popup.js:6-44`
   - Supports MM:SS, HH:MM:SS, and raw seconds

4. **ContentView.swift**
   - Main app layout with URL input and video player
   - Integrates player and controls

### How It Works

The repeat functionality mirrors the Chrome extension:

1. **Video Loading**: YouTube IFrame API loads in WKWebView
2. **Time Monitoring**: Timer checks `currentTime` every 0.3s (like `timeupdate` event)
3. **Loop Logic**: When `currentTime >= endTime`, seek to `startTime` (content.js:408)
4. **Repeat Counting**: Track iterations and stop when limit reached

### Comparison to Extension

| Extension | iOS App |
|-----------|---------|
| `chrome.tabs.sendMessage` | Direct method calls |
| DOM `video` element | WKWebView + YouTube IFrame API |
| Content script injection | Native Swift controller |
| `timeupdate` event | Timer polling at 0.3s |

## Usage

1. Launch the app
2. Paste a YouTube URL (e.g., `https://www.youtube.com/watch?v=dQw4w9WgXcQ`) or video ID
3. Tap "Load" to load the video
4. Set start time, end time, and repeat count
5. Tap "Start Repeat" to begin looping

**Tips:**
- Use "Use Current" button to capture the current playback time
- Scrub through the video to find your desired end time
- Set repeat count to 0 for infinite loop

## Setup in Xcode

1. Open `YRepeat.xcodeproj`
2. Select your development team in Signing & Capabilities
3. Build and run on simulator or device

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Internet connection for YouTube content

## Files Created

```
YRepeat/
├── ContentView.swift              # Main UI with URL input and layout
├── YouTubePlayerController.swift  # Video control and repeat logic
├── YouTubePlayerView.swift        # WKWebView wrapper
├── RepeatControlsView.swift       # Repeat controls UI
├── TimeHelpers.swift              # Time conversion utilities
└── Info.plist                     # Network security config
```

## Notes

- Uses YouTube IFrame API for reliable video control
- Info.plist configured to allow youtube.com, ytimg.com, googlevideo.com
- Repeat logic maintains count across loops, just like the extension
# repetitio
