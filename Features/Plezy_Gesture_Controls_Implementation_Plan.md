# Plezy Android Gesture Controls Implementation Plan
## Brightness & Volume Swipe Gesture Integration

**Version:** 1.0  
**Date:** November 11, 2025  
**Target Platform:** Android (iOS, Desktop, Web unaffected)  
**AI Assistant:** Optimized for Cline/Claude Code

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Project Structure Analysis](#project-structure-analysis)
4. [Phase 1: Dependencies Setup](#phase-1-dependencies-setup)
5. [Phase 2: Platform Abstraction Layer](#phase-2-platform-abstraction-layer)
6. [Phase 3: Enhanced Gesture Detector Widget](#phase-3-enhanced-gesture-detector-widget)
7. [Phase 4: Video Player Integration](#phase-4-video-player-integration)
8. [Phase 5: Visual Feedback System](#phase-5-visual-feedback-system)
9. [Phase 6: Testing & Validation](#phase-6-testing--validation)
10. [Phase 7: Documentation](#phase-7-documentation)
11. [Troubleshooting Guide](#troubleshooting-guide)

---

## Overview

### Objective
Integrate vertical swipe gesture controls for brightness (left side) and volume (right side) into Plezy's existing video player, working alongside existing double-tap gestures for rewind/fast-forward on Android devices.

### Current Implementation
- **Existing gestures:** Double tap left = rewind, Double tap right = fast forward
- **Video player:** MediaKit-based video player
- **Platforms:** Cross-platform (Android, iOS, Desktop, Web)

### New Feature Requirements
- **Left side vertical swipe:** Brightness control (up = increase, down = decrease)
- **Right side vertical swipe:** Volume control (up = increase, down = decrease)
- **Gesture coexistence:** Must not interfere with existing tap gestures
- **Platform isolation:** Android-only feature, zero impact on other platforms
- **Visual feedback:** Show indicator overlay during gesture adjustments

### Technical Constraints
1. Must preserve existing double-tap gesture functionality
2. Both tap and swipe gestures must work in the same screen zones
3. Platform-conditional compilation for Android-only code
4. No breaking changes to other platforms

---

## Prerequisites

### Required Tools
- Flutter SDK 3.8.1+ (as per Plezy requirements)
- Android SDK
- VS Code with Cline extension
- Git

### Knowledge Requirements
- Flutter GestureDetector API
- Platform channels (basic understanding)
- Conditional imports in Dart
- MediaKit video player basics

### Test Device
- Physical Android device (Android 6.0+) for testing permissions and gestures

---

## Project Structure Analysis

### Expected Plezy Directory Structure
```
plezy/
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── AndroidManifest.xml
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   └── video_player_screen.dart (expected location)
│   ├── widgets/
│   ├── models/
│   ├── providers/
│   └── services/
├── pubspec.yaml
└── README.md
```

### Files to Locate (Search Commands)
Run these searches in your project to find the exact files:

```bash
# Find video player screen implementation
grep -r "Video(" lib/screens/ --include="*.dart"
grep -r "media_kit" lib/ --include="*.dart"
grep -r "VideoController" lib/ --include="*.dart"

# Find existing gesture implementations
grep -r "GestureDetector" lib/ --include="*.dart"
grep -r "onTap\|onDoubleTap" lib/screens/ --include="*.dart"
```

### Critical Files to Identify
1. **Video Player Screen:** File containing `Video()` widget from media_kit
2. **Video Controls:** File with existing tap gesture handlers
3. **Player Controller:** File managing video playback state

---

## Phase 1: Dependencies Setup

### Step 1.1: Update `pubspec.yaml`

**File:** `pubspec.yaml`

**Action:** Add the following dependencies under the `dependencies:` section

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Existing dependencies...
  media_kit: ^any_version  # Already exists
  media_kit_video: ^any_version  # Already exists

  # NEW: Add these dependencies
  brightness_volume_manager: ^0.0.2  # For brightness/volume control on Android
```

**Execution Command:**
```bash
flutter pub get
```

**Verification:**
- Check that no dependency conflicts occur
- Verify `pubspec.lock` updated successfully

---

### Step 1.2: Configure Android Permissions

**File:** `android/app/src/main/AndroidManifest.xml`

**Action:** Add permissions inside `<manifest>` tag (before `<application>`)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Existing permissions... -->

    <!-- NEW: Brightness & Volume Control Permissions -->
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.WRITE_SETTINGS" 
                     tools:ignore="ProtectedPermissions" />

    <application
        android:label="Plezy"
        android:icon="@mipmap/ic_launcher">
        <!-- Existing application config... -->
    </application>
</manifest>
```

**Important Notes:**
- `WRITE_SETTINGS` is a special permission that requires runtime request
- `MODIFY_AUDIO_SETTINGS` is granted automatically at install
- Add `xmlns:tools="http://schemas.android.com/tools"` to `<manifest>` tag if not present

**Verification:**
- Build Android APK to ensure no manifest errors
- Check permissions are listed in APK analyzer

---

## Phase 2: Platform Abstraction Layer

### Step 2.1: Create Directory Structure

**Action:** Create new directory structure

```bash
mkdir -p lib/services/gesture_controls
```

**Expected Result:**
```
lib/
└── services/
    └── gesture_controls/
        ├── gesture_control_interface.dart
        ├── gesture_control_stub.dart
        ├── gesture_control_android.dart
        └── gesture_control_other.dart
```

---

### Step 2.2: Create Interface Definition

**File:** `lib/services/gesture_controls/gesture_control_interface.dart`

**Action:** Create new file with the following content

```dart
/// Platform-agnostic interface for brightness and volume gesture controls.
/// 
/// This interface defines the contract for controlling system brightness
/// and volume across different platforms. Implementations should handle
/// platform-specific requirements (permissions, APIs, etc.).
abstract class GestureControlInterface {
  /// Initialize the gesture control service.
  /// 
  /// Must be called before using any other methods. Handles platform-specific
  /// initialization like permission requests on Android.
  /// 
  /// Returns a Future that completes when initialization is done.
  Future<void> initialize();

  /// Check if gesture controls are available on the current platform.
  /// 
  /// Returns true for Android, false for other platforms.
  bool get isAvailable;

  /// Get current screen brightness level.
  /// 
  /// Returns a value between 0.0 (minimum) and 1.0 (maximum).
  /// Returns 0.5 if unable to retrieve brightness.
  Future<double> getBrightness();

  /// Set screen brightness level.
  /// 
  /// [value] should be between 0.0 (minimum) and 1.0 (maximum).
  /// Values outside this range will be clamped.
  /// 
  /// On Android, this requires WRITE_SETTINGS permission.
  Future<void> setBrightness(double value);

  /// Get current media volume level.
  /// 
  /// Returns a value between 0.0 (minimum) and 1.0 (maximum).
  /// Returns 0.5 if unable to retrieve volume.
  Future<double> getVolume();

  /// Set media volume level.
  /// 
  /// [value] should be between 0.0 (minimum) and 1.0 (maximum).
  /// Values outside this range will be clamped.
  /// 
  /// On Android, this requires MODIFY_AUDIO_SETTINGS permission.
  Future<void> setVolume(double value);

  /// Clean up resources when gesture controls are no longer needed.
  void dispose();
}
```

**Key Points:**
- Pure abstract interface (no implementation)
- Comprehensive documentation for each method
- Return types and parameter types clearly defined

---

### Step 2.3: Create Conditional Import Stub

**File:** `lib/services/gesture_controls/gesture_control_stub.dart`

**Action:** Create new file with the following content

```dart
/// Stub file for conditional imports.
/// 
/// This file uses Dart's conditional import feature to automatically
/// select the correct implementation based on the target platform.
/// 
/// - On platforms with dart:io (Android, iOS, Desktop): uses gesture_control_android.dart
/// - On web and other platforms: uses gesture_control_other.dart

import 'gesture_control_interface.dart';

// Conditional export based on platform
// When dart.library.io is available (mobile/desktop), use Android implementation
// Otherwise, use the stub implementation
export 'gesture_control_other.dart'
    if (dart.library.io) 'gesture_control_android.dart';

/// Factory function to create the appropriate gesture control instance.
/// 
/// This function is called by consumers to get a platform-appropriate
/// implementation without needing to know platform details.
GestureControlInterface createGestureControl() {
  return getGestureControl();
}
```

**Key Concepts:**
- **Conditional Exports:** Dart selects implementation at compile time
- **Factory Pattern:** Single entry point for all platforms
- **Zero Runtime Overhead:** Dead code elimination removes unused implementations

---

### Step 2.4: Create Android Implementation

**File:** `lib/services/gesture_controls/gesture_control_android.dart`

**Action:** Create new file with the following content

```dart
import 'dart:io' show Platform;
import 'package:brightness_volume_manager/brightness_volume_manager.dart';
import 'gesture_control_interface.dart';

/// Android-specific implementation of gesture controls.
/// 
/// Uses the brightness_volume_manager package to control system
/// brightness and media volume on Android devices.
/// 
/// This implementation will only be included in Android builds due to
/// conditional imports in gesture_control_stub.dart.
class AndroidGestureControl implements GestureControlInterface {
  /// Instance of brightness_volume_manager for Android system control
  final BrightnessVolumeManager _manager = BrightnessVolumeManager();

  /// Cached brightness value to handle errors gracefully
  double _currentBrightness = 0.5;

  /// Cached volume value to handle errors gracefully
  double _currentVolume = 0.5;

  /// Flag to track if initialization completed successfully
  bool _isInitialized = false;

  @override
  bool get isAvailable => Platform.isAndroid;

  @override
  Future<void> initialize() async {
    if (!isAvailable) {
      _isInitialized = false;
      return;
    }

    try {
      // Retrieve current system values
      _currentBrightness = await _manager.getBrightness();
      _currentVolume = await _manager.getVolume();
      _isInitialized = true;
    } catch (e) {
      print('[GestureControl] Initialization failed: $e');
      _isInitialized = false;
    }
  }

  @override
  Future<double> getBrightness() async {
    if (!isAvailable || !_isInitialized) return _currentBrightness;

    try {
      _currentBrightness = await _manager.getBrightness();
      return _currentBrightness;
    } catch (e) {
      print('[GestureControl] Failed to get brightness: $e');
      return _currentBrightness; // Return cached value on error
    }
  }

  @override
  Future<void> setBrightness(double value) async {
    if (!isAvailable || !_isInitialized) return;

    // Clamp value to valid range
    final clampedValue = value.clamp(0.0, 1.0);

    try {
      await _manager.setBrightness(clampedValue);
      _currentBrightness = clampedValue;
    } catch (e) {
      print('[GestureControl] Failed to set brightness: $e');
      // Note: WRITE_SETTINGS permission might not be granted
    }
  }

  @override
  Future<double> getVolume() async {
    if (!isAvailable || !_isInitialized) return _currentVolume;

    try {
      _currentVolume = await _manager.getVolume();
      return _currentVolume;
    } catch (e) {
      print('[GestureControl] Failed to get volume: $e');
      return _currentVolume; // Return cached value on error
    }
  }

  @override
  Future<void> setVolume(double value) async {
    if (!isAvailable || !_isInitialized) return;

    // Clamp value to valid range
    final clampedValue = value.clamp(0.0, 1.0);

    try {
      await _manager.setVolume(clampedValue);
      _currentVolume = clampedValue;
    } catch (e) {
      print('[GestureControl] Failed to set volume: $e');
    }
  }

  @override
  void dispose() {
    // Cleanup if needed
    _isInitialized = false;
  }
}

/// Factory function required by conditional import system.
/// 
/// This function is called by gesture_control_stub.dart to create
/// an instance of the Android implementation.
GestureControlInterface getGestureControl() {
  return AndroidGestureControl();
}
```

**Key Features:**
- Error handling with graceful degradation
- Cached values for offline operation
- Platform check before every operation
- Debug logging for troubleshooting

---

### Step 2.5: Create Other Platforms Implementation

**File:** `lib/services/gesture_controls/gesture_control_other.dart`

**Action:** Create new file with the following content

```dart
import 'gesture_control_interface.dart';

/// No-op implementation for non-Android platforms (iOS, Desktop, Web).
/// 
/// This implementation does nothing and always returns safe default values.
/// It ensures the app compiles and runs on all platforms without errors,
/// while gesture controls simply remain inactive on non-Android devices.
class OtherGestureControl implements GestureControlInterface {
  @override
  bool get isAvailable => false; // Never available on non-Android platforms

  @override
  Future<void> initialize() async {
    // No-op: Nothing to initialize on non-Android platforms
  }

  @override
  Future<double> getBrightness() async => 0.5; // Default middle value

  @override
  Future<void> setBrightness(double value) async {
    // No-op: Brightness control not supported on this platform
  }

  @override
  Future<double> getVolume() async => 0.5; // Default middle value

  @override
  Future<void> setVolume(double value) async {
    // No-op: Volume control not supported on this platform
  }

  @override
  void dispose() {
    // No-op: Nothing to clean up
  }
}

/// Factory function required by conditional import system.
/// 
/// This function is called by gesture_control_stub.dart to create
/// an instance of the no-op implementation for non-Android platforms.
GestureControlInterface getGestureControl() {
  return OtherGestureControl();
}
```

**Key Features:**
- Minimal implementation (no-op pattern)
- Safe return values (0.5 = 50% as default)
- No platform-specific imports or dependencies

---

**Phase 2 Verification Checklist:**
- [ ] All 4 files created in correct directory
- [ ] No import errors in any file
- [ ] `flutter analyze` passes without errors
- [ ] Project builds for Android and other platforms

---

## Phase 3: Enhanced Gesture Detector Widget

### Step 3.1: Create Video Gesture Overlay Widget

**Directory:** `lib/widgets/`

**Action:** Create new file `lib/widgets/video_gesture_overlay.dart`

**File:** `lib/widgets/video_gesture_overlay.dart`

```dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/gesture_controls/gesture_control_stub.dart';

/// A gesture overlay widget for video players that handles brightness and volume
/// control through vertical swipe gestures on Android devices.
/// 
/// **Gesture Zones:**
/// - Left 50% of screen: Brightness control (swipe up/down)
/// - Right 50% of screen: Volume control (swipe up/down)
/// 
/// **Coexistence with Tap Gestures:**
/// This widget uses vertical drag gestures which do not conflict with tap gestures.
/// Existing double-tap gestures for rewind/fast-forward will continue to work.
/// 
/// **Platform Support:**
/// Only active on Android. Automatically disabled on iOS, Desktop, and Web.
/// 
/// **Usage:**
/// ```dart
/// VideoGestureOverlay(
///   enabled: true,
///   child: Video(controller: videoController),
/// )
/// ```
class VideoGestureOverlay extends StatefulWidget {
  /// The video player widget to wrap with gesture controls
  final Widget child;

  /// Whether gesture controls are enabled (can be toggled via settings)
  final bool enabled;

  /// Callback fired when a gesture starts (optional, for debugging/analytics)
  final VoidCallback? onGestureStart;

  /// Callback fired when a gesture ends (optional, for debugging/analytics)
  final VoidCallback? onGestureEnd;

  const VideoGestureOverlay({
    Key? key,
    required this.child,
    this.enabled = true,
    this.onGestureStart,
    this.onGestureEnd,
  }) : super(key: key);

  @override
  State<VideoGestureOverlay> createState() => _VideoGestureOverlayState();
}

class _VideoGestureOverlayState extends State<VideoGestureOverlay> {
  /// Gesture control service instance (platform-specific)
  late final GestureControlInterface _gestureControl;

  // === Gesture State Variables ===

  /// Whether a vertical drag gesture is currently active
  bool _isGestureActive = false;

  /// Whether the current gesture is for brightness (true) or volume (false)
  bool _isBrightnessGesture = false;

  /// The initial value when gesture started (brightness or volume)
  double _gestureStartValue = 0.5;

  /// The current value during gesture (brightness or volume)
  double _currentGestureValue = 0.5;

  /// The position where the gesture started
  Offset? _gestureStartPosition;

  // === UI Feedback State Variables ===

  /// Timer to auto-hide the visual indicator
  Timer? _hideOverlayTimer;

  /// Whether to show the visual indicator overlay
  bool _showIndicator = false;

  // === Configuration Constants ===

  /// Sensitivity factor for gesture-to-value conversion
  /// Higher = more sensitive (smaller swipe changes value more)
  /// Lower = less sensitive (larger swipe needed to change value)
  /// 
  /// Recommended range: 0.001 to 0.005
  static const double _sensitivityFactor = 0.0025;

  /// Screen division ratio for left/right gesture zones
  /// 0.5 = 50% left for brightness, 50% right for volume
  static const double _screenSectionDivider = 0.5;

  /// Duration to show indicator after gesture ends
  static const Duration _indicatorDisplayDuration = Duration(milliseconds: 1000);

  /// Animation duration for indicator fade in/out
  static const Duration _indicatorFadeDuration = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _gestureControl = createGestureControl();
    _initializeGestureControl();
  }

  /// Initialize the gesture control service
  Future<void> _initializeGestureControl() async {
    if (widget.enabled && _gestureControl.isAvailable) {
      await _gestureControl.initialize();
    }
  }

  @override
  void dispose() {
    _hideOverlayTimer?.cancel();
    _gestureControl.dispose();
    super.dispose();
  }

  /// Handle the start of a vertical drag gesture
  void _handleVerticalDragStart(DragStartDetails details, Size screenSize) {
    // Exit early if disabled or not available on this platform
    if (!widget.enabled || !_gestureControl.isAvailable) return;

    // Notify observers that gesture started
    widget.onGestureStart?.call();

    setState(() {
      _isGestureActive = true;
      _gestureStartPosition = details.globalPosition;

      // Determine which side of the screen was touched
      // Left side = brightness control, Right side = volume control
      final tapX = details.globalPosition.dx;
      final dividerX = screenSize.width * _screenSectionDivider;
      _isBrightnessGesture = tapX < dividerX;
    });

    // Get the initial system value (brightness or volume)
    _initializeGestureValue();
  }

  /// Initialize gesture by fetching current system value
  Future<void> _initializeGestureValue() async {
    try {
      if (_isBrightnessGesture) {
        _gestureStartValue = await _gestureControl.getBrightness();
      } else {
        _gestureStartValue = await _gestureControl.getVolume();
      }
      _currentGestureValue = _gestureStartValue;
    } catch (e) {
      print('[VideoGestureOverlay] Failed to initialize gesture value: $e');
      _gestureStartValue = 0.5;
      _currentGestureValue = 0.5;
    }
  }

  /// Handle vertical drag updates (user is actively swiping)
  void _handleVerticalDragUpdate(DragUpdateDetails details, Size screenSize) {
    if (!_isGestureActive || _gestureStartPosition == null) return;

    setState(() {
      _showIndicator = true;

      // Calculate vertical distance from start position
      // Negative deltaY = swipe up (should increase value)
      // Positive deltaY = swipe down (should decrease value)
      final deltaY = details.globalPosition.dy - _gestureStartPosition!.dy;

      // Convert pixel movement to value change
      // Negative deltaY means swipe up, so we ADD to increase
      final valueDelta = -deltaY * _sensitivityFactor;

      // Calculate new value and clamp to valid range [0.0, 1.0]
      _currentGestureValue = (_gestureStartValue + valueDelta).clamp(0.0, 1.0);
    });

    // Apply the change to system brightness or volume
    _applyGestureValue();

    // Reset the hide timer so indicator stays visible during gesture
    _resetHideTimer();
  }

  /// Apply current gesture value to system brightness or volume
  Future<void> _applyGestureValue() async {
    try {
      if (_isBrightnessGesture) {
        await _gestureControl.setBrightness(_currentGestureValue);
      } else {
        await _gestureControl.setVolume(_currentGestureValue);
      }
    } catch (e) {
      print('[VideoGestureOverlay] Failed to apply gesture value: $e');
    }
  }

  /// Handle the end of a vertical drag gesture
  void _handleVerticalDragEnd(DragEndDetails details) {
    setState(() {
      _isGestureActive = false;
      _gestureStartPosition = null;
    });

    // Notify observers that gesture ended
    widget.onGestureEnd?.call();

    // Start timer to hide indicator
    _resetHideTimer();
  }

  /// Reset the auto-hide timer for the visual indicator
  void _resetHideTimer() {
    _hideOverlayTimer?.cancel();
    _hideOverlayTimer = Timer(_indicatorDisplayDuration, () {
      if (mounted) {
        setState(() {
          _showIndicator = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Original video player child
        widget.child,

        // Gesture detection overlay (only on Android when enabled)
        if (widget.enabled && _gestureControl.isAvailable)
          _buildGestureLayer(screenSize),

        // Visual feedback indicator
        if (_showIndicator && _gestureControl.isAvailable)
          _buildIndicator(),
      ],
    );
  }

  /// Build the gesture detection layer (left and right zones)
  Widget _buildGestureLayer(Size screenSize) {
    return Positioned.fill(
      child: Row(
        children: [
          // LEFT SECTION: Brightness Control Zone
          Expanded(
            child: GestureDetector(
              // Use translucent behavior so taps pass through to underlying widgets
              behavior: HitTestBehavior.translucent,
              onVerticalDragStart: (details) => 
                  _handleVerticalDragStart(details, screenSize),
              onVerticalDragUpdate: (details) => 
                  _handleVerticalDragUpdate(details, screenSize),
              onVerticalDragEnd: _handleVerticalDragEnd,
              // Transparent container (invisible but detects gestures)
              child: Container(color: Colors.transparent),
            ),
          ),

          // RIGHT SECTION: Volume Control Zone
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragStart: (details) => 
                  _handleVerticalDragStart(details, screenSize),
              onVerticalDragUpdate: (details) => 
                  _handleVerticalDragUpdate(details, screenSize),
              onVerticalDragEnd: _handleVerticalDragEnd,
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the visual indicator overlay
  Widget _buildIndicator() {
    return Positioned(
      // Position indicator on the side where gesture was performed
      top: 80,
      left: _isBrightnessGesture ? 40 : null,
      right: !_isBrightnessGesture ? 40 : null,
      child: AnimatedOpacity(
        opacity: _showIndicator ? 1.0 : 0.0,
        duration: _indicatorFadeDuration,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon (brightness or volume)
              Icon(
                _isBrightnessGesture 
                    ? Icons.brightness_6 
                    : Icons.volume_up,
                color: Colors.white,
                size: 36,
              ),

              const SizedBox(height: 12),

              // Progress bar
              SizedBox(
                width: 140,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _currentGestureValue,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Percentage text
              Text(
                '${(_currentGestureValue * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Key Features:**
1. **Non-Conflicting Gestures:** Uses `onVerticalDragStart/Update/End` which doesn't conflict with `onTap` or `onDoubleTap`
2. **Platform Safety:** Checks `isAvailable` before any gesture handling
3. **Visual Feedback:** Shows animated indicator during adjustments
4. **Error Handling:** Graceful degradation if permissions denied
5. **Configurable:** Sensitivity and behavior can be adjusted via constants
6. **Well-Documented:** Comprehensive comments for maintainability

---

**Phase 3 Verification Checklist:**
- [ ] File created at `lib/widgets/video_gesture_overlay.dart`
- [ ] No import errors (check gesture_control_stub import)
- [ ] `flutter analyze` passes
- [ ] Widget compiles successfully

---

## Phase 4: Video Player Integration

### Step 4.1: Locate Video Player Screen

**Action:** Find the file containing the video player implementation

**Search Commands:**
```bash
# Find the video player screen file
find lib -name "*.dart" -exec grep -l "Video(" {} \;
find lib -name "*.dart" -exec grep -l "VideoController" {} \;
find lib -name "*video*" -type f
```

**Expected Locations:**
- `lib/screens/video_player_screen.dart`
- `lib/screens/player_screen.dart`
- `lib/screens/media_player_screen.dart`
- `lib/widgets/video_player_widget.dart`

**What to Look For:**
1. Import statement: `import 'package:media_kit_video/media_kit_video.dart';`
2. `Video()` widget from media_kit
3. VideoController or Player instance
4. Existing GestureDetector with tap handlers

---

### Step 4.2: Analyze Existing Gesture Implementation

**Expected Pattern (Typical MediaKit Implementation):**

```dart
// Example of what you might find
Stack(
  children: [
    Video(
      controller: controller,
    ),
    // Existing controls overlay
    GestureDetector(
      onTap: () => _toggleControls(),
      onDoubleTapDown: (details) {
        // Check if left or right side
        if (details.globalPosition.dx < MediaQuery.of(context).size.width / 2) {
          // Left side: Rewind
          _rewind();
        } else {
          // Right side: Fast forward
          _fastForward();
        }
      },
      child: Container(color: Colors.transparent),
    ),
  ],
)
```

**Key Points to Note:**
1. How double-tap gestures are currently implemented
2. Where the Video widget is positioned in the widget tree
3. Any existing Stack or overlay structures
4. Control visibility logic

---

### Step 4.3: Integrate VideoGestureOverlay

**Action:** Modify the video player screen file to integrate gesture overlay

**Strategy:** Wrap the existing Stack or Video widget with VideoGestureOverlay

#### Integration Pattern 1: Video Widget Only

**If current structure is:**
```dart
Video(
  controller: controller,
)
```

**Change to:**
```dart
import '../widgets/video_gesture_overlay.dart'; // Add this import

VideoGestureOverlay(
  enabled: true,
  child: Video(
    controller: controller,
  ),
)
```

---

#### Integration Pattern 2: Video with Stack

**If current structure is:**
```dart
Stack(
  children: [
    Video(controller: controller),
    GestureDetector(
      onDoubleTap: () => _handleDoubleTap(),
      child: Container(color: Colors.transparent),
    ),
    // Other overlays (controls, etc.)
  ],
)
```

**Change to:**
```dart
import '../widgets/video_gesture_overlay.dart'; // Add this import

Stack(
  children: [
    VideoGestureOverlay(
      enabled: true,
      child: Video(controller: controller),
    ),
    GestureDetector(
      onDoubleTap: () => _handleDoubleTap(),
      child: Container(color: Colors.transparent),
    ),
    // Other overlays remain unchanged
  ],
)
```

**Why this works:**
- `VideoGestureOverlay` uses `onVerticalDrag*` callbacks
- Existing `GestureDetector` uses `onTap` and `onDoubleTap` callbacks
- Flutter's gesture arena handles these independently (no conflicts)
- Vertical drags don't trigger taps and vice versa

---

#### Integration Pattern 3: Full Scaffold Context

**If current structure is:**
```dart
class VideoPlayerScreen extends StatefulWidget {
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player player;
  late final VideoController controller;

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Video(controller: controller),
          // Existing controls
        ],
      ),
    );
  }
}
```

**Change to:**
```dart
import '../widgets/video_gesture_overlay.dart'; // ADD THIS

class VideoPlayerScreen extends StatefulWidget {
  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player player;
  late final VideoController controller;

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VideoGestureOverlay(  // ADD THIS
        enabled: true,            // ADD THIS
        child: Stack(             // WRAP EXISTING Stack
          children: [
            Video(controller: controller),
            // Existing controls unchanged
          ],
        ),
      ),  // ADD THIS
    );
  }
}
```

---

### Step 4.4: Optional - Make Gesture Control Configurable

**Action:** Add toggle setting (optional, for user preference)

**If Plezy has a settings system:**

1. Add boolean preference:
```dart
// In settings model/provider
bool gestureControlsEnabled = true;
```

2. Use in video player:
```dart
VideoGestureOverlay(
  enabled: settings.gestureControlsEnabled, // From settings
  child: Video(controller: controller),
)
```

3. Add UI toggle in settings screen:
```dart
SwitchListTile(
  title: const Text('Video Gesture Controls'),
  subtitle: const Text('Swipe for brightness and volume (Android only)'),
  value: gestureControlsEnabled,
  onChanged: (value) {
    setState(() {
      gestureControlsEnabled = value;
    });
  },
)
```

---

**Phase 4 Verification Checklist:**
- [ ] Video player screen file located and backed up
- [ ] VideoGestureOverlay import added
- [ ] Widget wrapping applied correctly
- [ ] Existing gestures still compile (no syntax errors)
- [ ] App builds successfully for Android

---

## Phase 5: Visual Feedback System

### Overview
The visual feedback system is already implemented in `VideoGestureOverlay._buildIndicator()`. This phase covers customization options.

### Step 5.1: Customize Indicator Appearance

**File:** `lib/widgets/video_gesture_overlay.dart`

**Customization Options:**

#### Option 1: Change Indicator Position

**Current (top-left/top-right):**
```dart
Positioned(
  top: 80,
  left: _isBrightnessGesture ? 40 : null,
  right: !_isBrightnessGesture ? 40 : null,
  child: // indicator
)
```

**Alternative (center-left/center-right):**
```dart
Positioned(
  top: MediaQuery.of(context).size.height / 2 - 80,
  left: _isBrightnessGesture ? 40 : null,
  right: !_isBrightnessGesture ? 40 : null,
  child: // indicator
)
```

---

#### Option 2: Change Colors/Styling

**Current styling:**
```dart
decoration: BoxDecoration(
  color: Colors.black.withOpacity(0.75),
  borderRadius: BorderRadius.circular(16),
)
```

**Alternative (match Plezy theme):**
```dart
decoration: BoxDecoration(
  color: Theme.of(context).primaryColor.withOpacity(0.9),
  borderRadius: BorderRadius.circular(20),
  border: Border.all(
    color: Colors.white.withOpacity(0.3),
    width: 1,
  ),
)
```

---

#### Option 3: Change Icons

**Current icons:**
- Brightness: `Icons.brightness_6`
- Volume: `Icons.volume_up`

**Alternatives:**
- Brightness: `Icons.wb_sunny`, `Icons.light_mode`
- Volume: `Icons.volume_up_rounded`, `Icons.speaker`

---

### Step 5.2: Adjust Sensitivity

**File:** `lib/widgets/video_gesture_overlay.dart`

**Current sensitivity:**
```dart
static const double _sensitivityFactor = 0.0025;
```

**Adjustment Guide:**
- **More Sensitive (smaller swipe = bigger change):** Increase value (e.g., `0.004`)
- **Less Sensitive (larger swipe = smaller change):** Decrease value (e.g., `0.001`)
- **Recommended Range:** `0.001` to `0.005`

**Testing Method:**
1. Change value
2. Hot reload (`r` in terminal)
3. Test swipe gesture on device
4. Adjust until comfortable

---

**Phase 5 Verification Checklist:**
- [ ] Indicator displays correctly during gestures
- [ ] Indicator auto-hides after 1 second
- [ ] Indicator shows correct icon (brightness/volume)
- [ ] Percentage value updates in real-time
- [ ] Sensitivity feels natural (not too fast or slow)

---

## Phase 6: Testing & Validation

### Step 6.1: Android Testing

**Prerequisites:**
- Physical Android device (emulator may not support brightness control)
- USB debugging enabled
- Device running Android 6.0+

**Test Sequence:**

#### Test 1: Build & Install
```bash
# Build and install on connected device
flutter run --release

# Or build APK and install manually
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Expected Result:** App installs without errors

---

#### Test 2: Permission Verification

**Steps:**
1. Launch Plezy
2. Navigate to video player
3. Check Android settings:
   - Settings > Apps > Plezy > Permissions
   - Verify "Modify system settings" permission exists

**Expected Result:** Permission listed (may require manual grant)

---

#### Test 3: Brightness Gesture

**Steps:**
1. Play a video
2. Swipe up on the LEFT side of the screen
3. Observe screen brightness increasing
4. Swipe down on the LEFT side
5. Observe screen brightness decreasing

**Expected Results:**
- [ ] Indicator appears showing brightness icon
- [ ] Percentage value updates during swipe
- [ ] Screen brightness changes in real-time
- [ ] Indicator fades out after 1 second
- [ ] No lag or stuttering

---

#### Test 4: Volume Gesture

**Steps:**
1. Play a video
2. Swipe up on the RIGHT side of the screen
3. Observe volume increasing
4. Swipe down on the RIGHT side
5. Observe volume decreasing

**Expected Results:**
- [ ] Indicator appears showing volume icon
- [ ] Percentage value updates during swipe
- [ ] System volume changes (Android volume bar may appear)
- [ ] Indicator fades out after 1 second
- [ ] No lag or stuttering

---

#### Test 5: Gesture Coexistence

**Steps:**
1. Play a video
2. Double-tap LEFT side quickly
3. Verify video rewinds
4. Double-tap RIGHT side quickly
5. Verify video fast-forwards
6. Swipe up on LEFT side
7. Verify brightness increases (not rewind)

**Expected Results:**
- [ ] Double-tap gestures still work
- [ ] Swipe gestures work independently
- [ ] No gesture conflicts or interference
- [ ] Both gestures feel responsive

---

#### Test 6: Edge Cases

**Test 6.1: Rapid Gestures**
- Quickly swipe up and down repeatedly
- **Expected:** Smooth value changes, no crashes

**Test 6.2: Simultaneous Gestures**
- Swipe with two fingers (one on each side)
- **Expected:** One gesture takes priority, no crash

**Test 6.3: Swipe While Paused**
- Pause video, then swipe
- **Expected:** Brightness/volume still changes

**Test 6.4: Full Screen Mode**
- Enter full screen, then swipe
- **Expected:** Gestures work in full screen

**Test 6.5: Screen Rotation**
- Rotate device, then swipe
- **Expected:** Gestures work in landscape/portrait

---

### Step 6.2: Cross-Platform Verification

**Objective:** Ensure gesture controls don't break other platforms

#### iOS Testing

```bash
# Build for iOS (requires macOS)
flutter build ios --release --no-codesign

# Or run on simulator
flutter run -d iPhone
```

**Expected Results:**
- [ ] App builds successfully
- [ ] No compilation errors
- [ ] Video player works normally
- [ ] No gesture indicators appear (Android-only feature)
- [ ] No crashes

---

#### Desktop Testing (Windows/macOS/Linux)

```bash
# Windows
flutter build windows --release
flutter run -d windows

# macOS
flutter build macos --release
flutter run -d macos

# Linux
flutter build linux --release
flutter run -d linux
```

**Expected Results:**
- [ ] App builds successfully
- [ ] Video player works normally
- [ ] No gesture controls active
- [ ] No errors in console

---

#### Web Testing

```bash
flutter build web --release
flutter run -d chrome
```

**Expected Results:**
- [ ] App builds successfully
- [ ] Video player works normally
- [ ] No gesture controls active
- [ ] No console errors

---

### Step 6.3: Performance Testing

**Metrics to Monitor:**

1. **Frame Rate During Gesture:**
   - Enable performance overlay: `flutter run --profile`
   - Swipe during video playback
   - **Target:** 60 FPS maintained

2. **Memory Usage:**
   - Use Android Studio Profiler
   - Monitor during 5 minutes of gesture usage
   - **Target:** No memory leaks, stable memory

3. **Battery Impact:**
   - Play video for 30 minutes with frequent gestures
   - Compare battery drain to non-gesture playback
   - **Target:** <5% additional drain

---

**Phase 6 Verification Checklist:**
- [ ] All Android gesture tests pass
- [ ] iOS builds without errors
- [ ] Windows/macOS/Linux build without errors
- [ ] Web builds without errors
- [ ] No performance degradation
- [ ] No memory leaks detected

---

## Phase 7: Documentation

### Step 7.1: Update README.md

**File:** `README.md`

**Action:** Add new section about Android gesture controls

**Add after the "Features" section:**

```markdown
## 🎮 Gesture Controls (Android)

Plezy for Android includes intuitive gesture controls for adjusting brightness and volume during video playback, similar to popular video players like YouTube and VLC.

### How to Use

- **Brightness Control:** Swipe up or down on the **left half** of the video player
  - Swipe up: Increase screen brightness
  - Swipe down: Decrease screen brightness

- **Volume Control:** Swipe up or down on the **right half** of the video player
  - Swipe up: Increase media volume
  - Swipe down: Decrease media volume

### Visual Feedback

During gestures, an on-screen indicator shows:
- Current control type (brightness or volume icon)
- Current level (percentage)
- Progress bar visualization

The indicator automatically fades out after 1 second of inactivity.

### Platform Availability

Gesture controls are **Android-only** and automatically disabled on:
- iOS
- Windows
- macOS
- Linux
- Web

### Permissions

The following Android permissions are required:
- `MODIFY_AUDIO_SETTINGS` - For volume control (granted automatically)
- `WRITE_SETTINGS` - For brightness control (may require manual grant)

If brightness control doesn't work, grant the "Modify system settings" permission:
1. Open Android Settings
2. Navigate to Apps > Plezy > Permissions
3. Enable "Modify system settings"

### Compatibility with Existing Gestures

Gesture controls work seamlessly alongside existing double-tap gestures:
- **Double-tap left:** Rewind video (unchanged)
- **Double-tap right:** Fast-forward video (unchanged)
- **Swipe up/down left:** Brightness control (new)
- **Swipe up/down right:** Volume control (new)

### Configuration

Gesture controls can be disabled via settings if desired (optional feature).
```

---

### Step 7.2: Create Internal Documentation

**File:** `docs/GESTURE_CONTROLS.md` (create new file)

**Action:** Create comprehensive developer documentation

```markdown
# Gesture Controls Implementation Documentation

## Architecture Overview

### Component Structure

```
lib/
├── services/
│   └── gesture_controls/
│       ├── gesture_control_interface.dart    # Abstract interface
│       ├── gesture_control_stub.dart         # Conditional import hub
│       ├── gesture_control_android.dart      # Android implementation
│       └── gesture_control_other.dart        # No-op for other platforms
├── widgets/
│   └── video_gesture_overlay.dart            # Gesture detection & UI
└── screens/
    └── video_player_screen.dart              # Integration point
```

### Design Patterns

1. **Interface-Based Design:** `GestureControlInterface` defines contract
2. **Factory Pattern:** `createGestureControl()` provides platform-specific instance
3. **Conditional Compilation:** Dart's conditional imports for platform isolation
4. **Overlay Pattern:** `VideoGestureOverlay` wraps video player non-invasively

## Platform Abstraction

### How Conditional Imports Work

```dart
// gesture_control_stub.dart
export 'gesture_control_other.dart'
    if (dart.library.io) 'gesture_control_android.dart';
```

**Compilation Process:**
1. Dart compiler checks target platform
2. If `dart:io` available (Android/iOS/Desktop): uses `gesture_control_android.dart`
3. Otherwise (Web): uses `gesture_control_other.dart`
4. Unused implementation is tree-shaken (removed from final binary)

**Result:** Zero code overhead on non-Android platforms

### Platform Detection

```dart
// In gesture_control_android.dart
@override
bool get isAvailable => Platform.isAndroid;
```

**Runtime Check:**
- Returns `true` only on Android
- Returns `false` on iOS, Windows, macOS, Linux
- Prevents execution of Android-specific code on wrong platforms

## Gesture Detection

### GestureDetector Configuration

```dart
GestureDetector(
  behavior: HitTestBehavior.translucent,
  onVerticalDragStart: _handleStart,
  onVerticalDragUpdate: _handleUpdate,
  onVerticalDragEnd: _handleEnd,
  child: Container(color: Colors.transparent),
)
```

**Key Points:**
- `behavior: translucent` allows tap gestures to pass through
- Vertical drag callbacks don't conflict with tap/double-tap
- Transparent container makes entire area interactive

### Gesture Arena Resolution

Flutter's gesture system handles conflicts via gesture arena:

| Gesture Type | Priority | Conflicts With |
|--------------|----------|----------------|
| Tap | High | - |
| Double Tap | High | Tap (resolved via delay) |
| Vertical Drag | Medium | Horizontal Drag |

**Vertical drag + Tap/Double-tap = No Conflict**

Vertical drags require minimum movement threshold before recognition, so quick taps complete before drag detection begins.

## Sensitivity Calculation

### Algorithm

```dart
final deltaY = currentPosition.dy - startPosition.dy;
final valueDelta = -deltaY * _sensitivityFactor;
final newValue = (startValue + valueDelta).clamp(0.0, 1.0);
```

### Sensitivity Factor

| Factor | Pixels for 50% Change | Description |
|--------|----------------------|-------------|
| 0.001 | 500px | Very low sensitivity |
| 0.0025 | 200px | Default (recommended) |
| 0.005 | 100px | High sensitivity |

**Tuning Guide:**
- Taller devices: Lower sensitivity (more pixels available)
- Shorter devices: Higher sensitivity (fewer pixels available)
- User preference: Make configurable in settings

## Error Handling

### Graceful Degradation

All Android-specific operations are wrapped in try-catch:

```dart
try {
  await _manager.setBrightness(value);
} catch (e) {
  print('[GestureControl] Failed: $e');
  // Continue execution, use cached value
}
```

**Failure Scenarios:**
1. **Permission denied:** Silent failure, no crash
2. **Platform API unavailable:** Uses cached values
3. **Invalid values:** Clamped to valid range [0.0, 1.0]

### Permission Handling

**WRITE_SETTINGS Permission:**
- Special permission requiring user action
- Cannot be requested programmatically (Android 6.0+)
- If denied: brightness control silently fails, app continues

**User Guidance:**
- Document permission requirement in README
- Consider showing in-app prompt with instructions

## Performance Considerations

### Optimization Strategies

1. **Cached Values:**
   ```dart
   double _currentBrightness = 0.5;
   ```
   Avoids repeated system calls, fallback on errors

2. **Throttled Updates:**
   System calls only on `onVerticalDragUpdate` (60 FPS max)

3. **Minimal Rebuilds:**
   Only indicator widget rebuilds during gesture, video player untouched

### Memory Management

- `Timer` for indicator auto-hide (properly cancelled in dispose)
- Gesture control service disposed with widget
- No listeners or subscriptions that could leak

## Testing Guidelines

### Unit Testing

```dart
// Example test
testWidgets('Gesture overlay renders', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: VideoGestureOverlay(
        enabled: true,
        child: Container(),
      ),
    ),
  );
  expect(find.byType(VideoGestureOverlay), findsOneWidget);
});
```

### Integration Testing

```dart
// Example integration test
testWidgets('Vertical swipe changes brightness', (tester) async {
  // Requires actual Android device with permissions
  await tester.drag(
    find.byType(VideoGestureOverlay),
    Offset(0, -100), // Swipe up 100px
  );
  // Verify brightness increased
});
```

### Manual Testing Checklist

See [Phase 6: Testing & Validation](#phase-6-testing--validation)

## Future Enhancements

### Potential Improvements

1. **Horizontal Gestures:**
   - Left swipe: Previous episode/track
   - Right swipe: Next episode/track

2. **Pinch Gestures:**
   - Pinch in/out: Adjust playback speed
   - Two-finger tap: Toggle subtitles

3. **Configurable Sensitivity:**
   - Add slider in settings
   - Save preference per user

4. **Haptic Feedback:**
   - Vibrate on gesture start
   - Pulse at 0% and 100%

5. **Sound Effects:**
   - Optional audio feedback during adjustments

### Known Limitations

1. **Brightness Permission:**
   - Cannot be requested programmatically on Android 6.0+
   - User must manually grant in system settings

2. **Emulator Support:**
   - Brightness control may not work on emulators
   - Requires physical device for full testing

3. **Multi-Touch:**
   - Currently handles single pointer only
   - Multiple fingers may cause unexpected behavior

## Troubleshooting

See [Troubleshooting Guide](#troubleshooting-guide) section

## References

- [Flutter GestureDetector API](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)
- [brightness_volume_manager Package](https://pub.dev/packages/brightness_volume_manager)
- [Android WRITE_SETTINGS Permission](https://developer.android.com/reference/android/Manifest.permission#WRITE_SETTINGS)
- [Dart Conditional Imports](https://dart.dev/guides/libraries/create-library-packages#conditionally-importing-and-exporting-library-files)
```

---

### Step 7.3: Add Code Comments

**Action:** Ensure all new code is well-commented

**Guidelines:**
- Every class has a doc comment (`///`)
- Every public method has a doc comment
- Complex logic has inline comments (`//`)
- Constants explain their purpose and valid ranges

**Verification:**
```bash
# Check for missing doc comments
flutter analyze --no-fatal-infos
```

---

**Phase 7 Verification Checklist:**
- [ ] README.md updated with user-facing documentation
- [ ] GESTURE_CONTROLS.md created with developer documentation
- [ ] All code properly commented
- [ ] No `flutter analyze` warnings about missing documentation

---

## Troubleshooting Guide

### Issue 1: Brightness Control Not Working

**Symptoms:**
- Volume gesture works fine
- Brightness indicator shows but value doesn't change
- No errors in console

**Causes:**
1. WRITE_SETTINGS permission not granted
2. Running on emulator (limited support)
3. Device manufacturer limitations (some OEMs restrict brightness control)

**Solutions:**

**Solution 1: Grant Permission Manually**
```
1. Open Android Settings
2. Tap Apps / Application Manager
3. Find Plezy in the list
4. Tap Permissions
5. Look for "Modify system settings"
6. Toggle to ON/Enabled
```

**Solution 2: Test on Physical Device**
- Brightness control often fails on emulators
- Always test on real Android hardware

**Solution 3: Check Device Compatibility**
```dart
// Add debug logging in gesture_control_android.dart
@override
Future<void> setBrightness(double value) async {
  try {
    await _manager.setBrightness(value);
    print('[DEBUG] Brightness set successfully: $value');
  } catch (e) {
    print('[DEBUG] Brightness set failed: $e');
    // Check the error message for clues
  }
}
```

---

### Issue 2: Gestures Conflict with Taps

**Symptoms:**
- Double-tap gestures stop working
- Taps trigger swipes accidentally
- Swipes trigger taps accidentally

**Causes:**
1. Incorrect gesture detector configuration
2. HitTestBehavior set incorrectly
3. Multiple overlapping GestureDetectors

**Solutions:**

**Solution 1: Verify HitTestBehavior**
```dart
// Should be translucent, not opaque
GestureDetector(
  behavior: HitTestBehavior.translucent,  // CORRECT
  // NOT: behavior: HitTestBehavior.opaque,
  ...
)
```

**Solution 2: Check GestureDetector Stacking**
```dart
// VideoGestureOverlay should wrap Video, not sit above it
Stack(
  children: [
    VideoGestureOverlay(
      child: Video(...),  // CORRECT
    ),
    GestureDetector(...), // Tap gestures on top
  ],
)
```

**Solution 3: Add Gesture Recognition Delay**
```dart
// In existing tap gesture handler
GestureDetector(
  onDoubleTapDown: (details) async {
    await Future.delayed(Duration(milliseconds: 50));
    // Handle double tap
  },
)
```

---

### Issue 3: Indicator Doesn't Show

**Symptoms:**
- Gestures seem to work (brightness/volume changes)
- No visual indicator appears
- No indicator animation

**Causes:**
1. Indicator widget not in render tree
2. Opacity stuck at 0
3. Z-index issue (indicator behind video)

**Solutions:**

**Solution 1: Verify Stack Order**
```dart
// Indicator must be LAST child in Stack
Stack(
  children: [
    widget.child,        // Video player
    _buildGestureLayer(), // Gesture detection
    _buildIndicator(),   // Visual indicator (MUST BE LAST)
  ],
)
```

**Solution 2: Force Indicator Visibility**
```dart
// Temporarily set to always show for debugging
AnimatedOpacity(
  opacity: 1.0,  // Change from _showIndicator ? 1.0 : 0.0
  duration: _indicatorFadeDuration,
  child: // indicator
)
```

**Solution 3: Check State Updates**
```dart
// Ensure setState is called
void _handleVerticalDragUpdate(...) {
  setState(() {  // MUST wrap state changes
    _showIndicator = true;
    _currentGestureValue = ...;
  });
}
```

---

### Issue 4: Build Fails on iOS/Desktop

**Symptoms:**
- Android builds successfully
- iOS/Desktop/Web builds fail with import errors
- Errors mention dart:io or Platform

**Causes:**
1. Conditional imports not set up correctly
2. Platform-specific code leaking into shared files
3. Missing export statements

**Solutions:**

**Solution 1: Verify Conditional Import Syntax**
```dart
// gesture_control_stub.dart should have EXACTLY this format
export 'gesture_control_other.dart'
    if (dart.library.io) 'gesture_control_android.dart';
```

**Solution 2: Check Import Statements**
```dart
// In video_player_screen.dart
import '../services/gesture_controls/gesture_control_stub.dart';
// NOT: import '../services/gesture_controls/gesture_control_android.dart';
```

**Solution 3: Verify Platform Checks**
```dart
// Platform.isAndroid should ONLY appear in gesture_control_android.dart
// NOT in gesture_control_interface.dart or gesture_control_stub.dart
```

---

### Issue 5: Sensitivity Too High/Low

**Symptoms:**
- Tiny swipe causes huge change (too sensitive)
- Large swipe causes tiny change (not sensitive enough)
- Difficult to control precisely

**Solutions:**

**Solution 1: Adjust Sensitivity Factor**
```dart
// In video_gesture_overlay.dart
static const double _sensitivityFactor = 0.0025;  // Default

// For less sensitive (larger swipes needed):
static const double _sensitivityFactor = 0.001;

// For more sensitive (smaller swipes needed):
static const double _sensitivityFactor = 0.005;
```

**Solution 2: Implement Non-Linear Scaling**
```dart
// Replace linear calculation with curve
final valueDelta = -deltaY * _sensitivityFactor;
final curvedDelta = valueDelta * valueDelta.sign * 0.5;  // Square for non-linear
_currentGestureValue = (_gestureStartValue + curvedDelta).clamp(0.0, 1.0);
```

**Solution 3: Add Dead Zone**
```dart
// Ignore small movements (< 10px)
final deltaY = details.globalPosition.dy - _gestureStartPosition!.dy;
if (deltaY.abs() < 10) return;  // Dead zone
```

---

### Issue 6: Memory Leaks

**Symptoms:**
- App becomes slow over time
- Memory usage increases continuously
- Crashes after extended use

**Causes:**
1. Timer not cancelled in dispose
2. Gesture control service not disposed
3. Listeners not removed

**Solutions:**

**Solution 1: Verify Dispose Method**
```dart
@override
void dispose() {
  _hideOverlayTimer?.cancel();  // MUST cancel timer
  _gestureControl.dispose();    // MUST dispose service
  super.dispose();               // MUST call super
}
```

**Solution 2: Check for Listeners**
```dart
// Search codebase for addListener calls
// Each addListener MUST have corresponding removeListener in dispose
controller.addListener(_listener);

@override
void dispose() {
  controller.removeListener(_listener);  // Don't forget this!
  super.dispose();
}
```

**Solution 3: Use Memory Profiler**
```bash
# Run with profiling enabled
flutter run --profile

# In Android Studio:
# View > Tool Windows > Flutter Performance
# Monitor memory allocation during gestures
```

---

### Issue 7: Permission Dialog Not Showing

**Symptoms:**
- WRITE_SETTINGS permission not requested
- No system dialog appears
- Brightness control fails silently

**Expected Behavior:**
- WRITE_SETTINGS cannot be requested programmatically on Android 6.0+
- User must manually grant in system settings

**Solutions:**

**Solution 1: Add In-App Guidance**
```dart
// Show dialog guiding user to settings
if (!await _hasWriteSettingsPermission()) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Permission Required'),
      content: Text(
        'To control brightness, please enable "Modify system settings" '
        'in Android Settings > Apps > Plezy > Permissions'
      ),
      actions: [
        TextButton(
          onPressed: () => _openAppSettings(),
          child: Text('Open Settings'),
        ),
      ],
    ),
  );
}
```

**Solution 2: Add Permission Check**
```dart
// Check if permission granted
Future<bool> _hasWriteSettingsPermission() async {
  // Use permission_handler package
  return await Permission.systemSettings.isGranted;
}
```

---

### Debug Logging

**Enable Verbose Logging:**

Add this flag to existing print statements:

```dart
// In gesture_control_android.dart
static const bool _debugMode = true;

void _log(String message) {
  if (_debugMode) {
    print('[GestureControl] $message');
  }
}

// Usage
@override
Future<void> setBrightness(double value) async {
  _log('setBrightness called: $value');
  try {
    await _manager.setBrightness(value);
    _log('setBrightness succeeded');
  } catch (e) {
    _log('setBrightness failed: $e');
  }
}
```

**View Logs:**
```bash
# Android
adb logcat | grep GestureControl

# Flutter
flutter run --verbose
```

---

### Getting Help

If issues persist after trying these solutions:

1. **Check Flutter Version:**
   ```bash
   flutter doctor -v
   ```

2. **Clean and Rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

3. **Create Minimal Reproduction:**
   - Isolate the issue in a separate test file
   - Remove unrelated code
   - Share code snippet when asking for help

4. **Community Resources:**
   - [Flutter Discord](https://discord.gg/flutter)
   - [StackOverflow - flutter tag](https://stackoverflow.com/questions/tagged/flutter)
   - [Plezy GitHub Issues](https://github.com/bizzkoot/plezy/issues)

---

## Appendix

### A. Complete File Checklist

Verify all files are created:

```
☐ android/app/src/main/AndroidManifest.xml (modified)
☐ pubspec.yaml (modified)
☐ lib/services/gesture_controls/gesture_control_interface.dart (new)
☐ lib/services/gesture_controls/gesture_control_stub.dart (new)
☐ lib/services/gesture_controls/gesture_control_android.dart (new)
☐ lib/services/gesture_controls/gesture_control_other.dart (new)
☐ lib/widgets/video_gesture_overlay.dart (new)
☐ lib/screens/video_player_screen.dart (modified)
☐ README.md (modified)
☐ docs/GESTURE_CONTROLS.md (new)
```

---

### B. Build Commands Reference

```bash
# Development
flutter run                          # Debug mode
flutter run --release                # Release mode
flutter run --profile                # Profile mode (performance testing)

# Android
flutter build apk --release          # Build APK
flutter build appbundle --release    # Build App Bundle (for Play Store)
adb install <path-to-apk>           # Install APK on connected device

# iOS (requires macOS)
flutter build ios --release --no-codesign
flutter run -d iPhone               # Run on simulator

# Desktop
flutter build windows --release     # Windows
flutter build macos --release       # macOS
flutter build linux --release       # Linux

# Web
flutter build web --release
flutter run -d chrome

# Cleaning
flutter clean                       # Clean build cache
flutter pub get                     # Re-download dependencies
```

---

### C. Useful Flutter Commands

```bash
# Analysis
flutter analyze                     # Run static analysis
flutter analyze --no-fatal-infos   # Ignore info-level issues

# Testing
flutter test                        # Run unit tests
flutter drive                       # Run integration tests

# Debugging
flutter logs                        # View logs from all devices
flutter devices                     # List connected devices
flutter doctor                      # Check Flutter installation

# Hot Reload
r                                   # Hot reload (in flutter run)
R                                   # Hot restart (in flutter run)
q                                   # Quit (in flutter run)
```

---

### D. Android Permission Reference

| Permission | Type | Auto-Granted | Purpose |
|------------|------|--------------|---------|
| `INTERNET` | Normal | Yes | Network access (media streaming) |
| `MODIFY_AUDIO_SETTINGS` | Normal | Yes | Volume control |
| `WRITE_SETTINGS` | Special | No | Brightness control |

**Special Permission Handling:**
```xml
<!-- In AndroidManifest.xml -->
<uses-permission 
    android:name="android.permission.WRITE_SETTINGS"
    tools:ignore="ProtectedPermissions" />
```

**Requesting at Runtime:**
```dart
// Use permission_handler package
import 'package:permission_handler/permission_handler.dart';

// Check permission
bool granted = await Permission.systemSettings.isGranted;

// Open settings (user must grant manually)
if (!granted) {
  await openAppSettings();
}
```

---

### E. Gesture Sensitivity Calculator

Use this formula to calculate required swipe distance:

```
Distance (pixels) = (Desired Change %) / (Sensitivity Factor × 100)

Examples:
- Sensitivity 0.0025, 50% change: 500 / (0.0025 × 100) = 200px
- Sensitivity 0.001, 50% change: 500 / (0.001 × 100) = 500px
- Sensitivity 0.005, 50% change: 500 / (0.005 × 100) = 100px
```

**Device Screen Sizes:**
- Small phones: ~1280px height
- Medium phones: ~1920px height
- Large phones: ~2560px height

**Recommendation:**
- Use sensitivity that requires 1/4 to 1/3 of screen height for full range
- Example: For 1920px screen, 500px for full range = sensitivity 0.002

---

### F. Flutter GestureDetector Callbacks

| Callback | Trigger | Conflicts With |
|----------|---------|----------------|
| `onTap` | Single quick tap | - |
| `onDoubleTap` | Two quick taps | `onTap` (resolved with delay) |
| `onLongPress` | Tap and hold | - |
| `onVerticalDragStart` | Vertical swipe begins | `onHorizontalDrag*` |
| `onVerticalDragUpdate` | Vertical swipe continues | `onHorizontalDrag*` |
| `onVerticalDragEnd` | Vertical swipe ends | `onHorizontalDrag*` |
| `onHorizontalDragStart` | Horizontal swipe begins | `onVerticalDrag*` |
| `onHorizontalDragUpdate` | Horizontal swipe continues | `onVerticalDrag*` |
| `onHorizontalDragEnd` | Horizontal swipe ends | `onVerticalDrag*` |
| `onPanStart` | Any drag begins | Directional drags |
| `onPanUpdate` | Any drag continues | Directional drags |
| `onPanEnd` | Any drag ends | Directional drags |
| `onScaleStart` | Pinch/zoom begins | - |
| `onScaleUpdate` | Pinch/zoom continues | - |
| `onScaleEnd` | Pinch/zoom ends | - |

**Key Insight:**
- `onVerticalDrag*` + `onTap`/`onDoubleTap` = No conflict ✓
- `onVerticalDrag*` + `onHorizontalDrag*` = Conflict (gesture arena resolves)
- `onPan*` + `onVerticalDrag*` = Conflict (use one or the other)

---

### G. MediaKit Video Player Reference

**Basic Setup:**
```dart
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

// Create player
final player = Player();

// Create controller
final controller = VideoController(player);

// Play video
await player.open(Media('https://example.com/video.mp4'));

// Dispose
player.dispose();
```

**Gesture-Friendly Structure:**
```dart
Stack(
  children: [
    VideoGestureOverlay(
      child: Video(controller: controller),
    ),
    // Custom controls on top
  ],
)
```

---

### H. Implementation Timeline

**Estimated Time:** 3-4 hours

| Phase | Task | Duration |
|-------|------|----------|
| 1 | Dependencies & Permissions | 20 min |
| 2 | Platform Abstraction Layer | 45 min |
| 3 | Gesture Overlay Widget | 60 min |
| 4 | Video Player Integration | 30 min |
| 5 | Visual Feedback (included) | - |
| 6 | Testing & Validation | 60 min |
| 7 | Documentation | 30 min |

**Milestones:**
- ☐ Phase 1-2 Complete: Compiles on all platforms
- ☐ Phase 3-4 Complete: Gestures work on Android
- ☐ Phase 6 Complete: All tests pass
- ☐ Phase 7 Complete: Documentation updated

---

## Summary

This implementation plan provides a comprehensive, step-by-step guide to adding brightness and volume gesture controls to your Plezy fork. The solution:

✅ **Preserves existing functionality** - Double-tap gestures unaffected  
✅ **Android-only implementation** - Zero impact on other platforms  
✅ **Platform-safe architecture** - Conditional imports and abstraction layers  
✅ **Professional code quality** - Error handling, documentation, testing  
✅ **User-friendly UX** - Visual feedback and intuitive gestures  
✅ **Maintainable codebase** - Clean separation of concerns  

Follow the phases in order, verify each step, and refer to the troubleshooting guide if issues arise. This document is designed for use with AI coding assistants like Cline/Claude Code for semi-automated implementation.

**Good luck with your implementation! 🚀**

---

*Document Version: 1.0*  
*Last Updated: November 11, 2025*  
*Author: AI Implementation Guide for Plezy Gesture Controls*  
*License: Same as Plezy (GPL-3.0)*
