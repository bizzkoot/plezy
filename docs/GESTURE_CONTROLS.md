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
@Override
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

**Vertical drag + Tap/Double-tap = No Conflict ✓**

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

See [Phase 6: Testing & Validation](#phase-6-testing--validation) in implementation plan

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

See [Troubleshooting Guide](#troubleshooting-guide) in implementation plan

## References

- [Flutter GestureDetector API](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)
- [brightness_volume_manager Package](https://pub.dev/packages/brightness_volume_manager)
- [Android WRITE_SETTINGS Permission](https://developer.android.com/reference/android/Manifest.permission#WRITE_SETTINGS)
- [Dart Conditional Imports](https://dart.dev/guides/libraries/create-library-packages#conditionally-importing-and-exporting-library-files)