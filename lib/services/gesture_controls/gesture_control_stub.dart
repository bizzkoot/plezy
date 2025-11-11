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