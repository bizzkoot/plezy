<h1>
  <img src="assets/plezy.png" alt="Plezy Logo" height="24" style="vertical-align: middle;" />
  Plezy
</h1>

Plezy is a modern Plex media client that provides a seamless streaming experience across desktop and mobile platforms. Built with Flutter, it offers native performance and a clean, intuitive interface for browsing and playing your Plex media library.

<p align="center">
  <img src="assets/screenshots/macos-home.png" alt="Plezy macOS Home Screen" width="800" />
</p>

*See more screenshots in the [screenshots folder](assets/screenshots/#readme)*

## Download

### Mobile
<a href='https://apps.apple.com/us/app/id6754315964'><img height='60' alt='Download on the App Store' src='./assets/app-store-badge.png'/></a>
<a href='https://play.google.com/store/apps/details?id=com.edde746.plezy'><img height='60' alt='Get it on Google Play' src='./assets/play-store-badge.png'/></a>

> Google Play version is in closed testing ([required by Google](https://support.google.com/googleplay/android-developer/answer/14151465#overview)). Join the [Google Group](https://groups.google.com/g/plezy-testers-2) to get access.

### Desktop
- [Windows (x64)](https://github.com/edde746/plezy/releases/latest/download/plezy-windows-installer.exe)
- [macOS (Universal)](https://github.com/edde746/plezy/releases/latest/download/plezy-macos.zip)
- [Linux (x64)](https://github.com/edde746/plezy/releases/latest/download/plezy-linux.tar.gz)

> Download the latest release from the [Releases page](https://github.com/edde746/plezy/releases)

## Features

### 🔐 Authentication & Server Management
- Sign in with Plex
- Automatic server discovery with smart connection selection
- Persistent sessions with auto-login

### 📚 Media Browsing
- Browse libraries with rich metadata
- Discover featured content
- Advanced search across all media
- Season and episode navigation

### 🎬 Video Playback
- Wide codec support including HEVC, AV1, VP9, and more
- Advanced subtitle rendering with full ASS/SSA support
- Audio and subtitle track selection with user profile preferences
- Playback progress sync and resume functionality
- Auto-play next episode
- **Android gesture controls**: Swipe for brightness and volume (Android only)

### 🎮 Gesture Controls (Android)

Plezy for Android includes intuitive gesture controls for adjusting brightness and volume during video playback, similar to popular video players like YouTube and VLC.

#### How to Use

- **Brightness Control:** Swipe up or down on the **left half** of the video player
  - Swipe up: Increase screen brightness
  - Swipe down: Decrease screen brightness

- **Volume Control:** Swipe up or down on the **right half** of the video player
  - Swipe up: Increase media volume
  - Swipe down: Decrease media volume

#### Visual Feedback

During gestures, an on-screen indicator shows:
- Current control type (brightness or volume icon)
- Current level (percentage)
- Progress bar visualization

The indicator automatically fades out after 1 second of inactivity.

#### Platform Availability

Gesture controls are **Android-only** and automatically disabled on:
- iOS
- Windows
- macOS
- Linux
- Web

#### Permissions

The following Android permissions are required:
- `MODIFY_AUDIO_SETTINGS` - For volume control (granted automatically)
- `WRITE_SETTINGS` - For brightness control (may require manual grant)

If brightness control doesn't work, grant the "Modify system settings" permission:
1. Open Android Settings
2. Navigate to Apps > Plezy > Permissions
3. Enable "Modify system settings"

#### Compatibility with Existing Gestures

Gesture controls work seamlessly alongside existing double-tap gestures:
- **Double-tap left:** Rewind video (unchanged)
- **Double-tap right:** Fast-forward video (unchanged)
- **Swipe up/down left:** Brightness control (new)
- **Swipe up/down right:** Volume control (new)

## Prerequisites

- Flutter SDK 3.8.1 or higher
- A Plex account
- Access to a Plex Media Server (local or remote)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/edde746/plezy.git
cd plezy
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate required code:
```bash
dart run build_runner build
```

4. Run the application:
```bash
flutter run
```

## Development

### Code Generation

The project uses code generation for JSON serialization. After modifying model classes, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### Desktop
```bash
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

## Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Media playback powered by [MediaKit](https://github.com/media-kit/media-kit)
- Designed for [Plex Media Server](https://www.plex.tv)
