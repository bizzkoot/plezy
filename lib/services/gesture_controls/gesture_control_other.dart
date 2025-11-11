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