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
      // Retrieve current system values and ensure double types
      final dynamic b = await _manager.getBrightness();
      final dynamic v = await _manager.getVolume();
      _currentBrightness = (b is num) ? b.toDouble() : 0.5;
      _currentVolume = (v is num) ? v.toDouble() : 0.5;
      _isInitialized = true;
    } catch (e) {
      print('[GestureControl] Initialization failed: $e');
      // Common cause: WRITE_SETTINGS not granted on Android. Guide the user.
      if (Platform.isAndroid) {
        print(
          '[GestureControl] If brightness control does not work, ensure Plezy has "Modify system settings" permission '
          '(Settings > Apps > Plezy > Modify system settings).'
        );
      }
      _isInitialized = false;
    }
  }

  @override
  Future<double> getBrightness() async {
    if (!isAvailable || !_isInitialized) return _currentBrightness;

    try {
      final dynamic b = await _manager.getBrightness();
      _currentBrightness = (b is num) ? b.toDouble() : _currentBrightness;
      return _currentBrightness;
    } catch (e) {
      print('[GestureControl] Failed to get brightness: $e');
      return _currentBrightness; // Return cached value on error
    }
  }

  @override
  Future<void> setBrightness(double value) async {
    if (!isAvailable || !_isInitialized) return;

    // Clamp value to valid range and ensure double type
    final double clampedValue = (value.clamp(0.0, 1.0) as num).toDouble();

    try {
      await _manager.setBrightness(clampedValue);
      _currentBrightness = clampedValue;
    } catch (e) {
      print('[GestureControl] Failed to set brightness: $e');
      // Note: WRITE_SETTINGS permission might not be granted. Provide guidance.
      if (Platform.isAndroid) {
        print(
          '[GestureControl] Brightness change may require "Modify system settings" permission. '
          'Ask the user to grant it via Settings > Apps > Plezy > Modify system settings.'
        );
      }
    }
  }

  @override
  Future<double> getVolume() async {
    if (!isAvailable || !_isInitialized) return _currentVolume;

    try {
      final dynamic v = await _manager.getVolume();
      _currentVolume = (v is num) ? v.toDouble() : _currentVolume;
      return _currentVolume;
    } catch (e) {
      print('[GestureControl] Failed to get volume: $e');
      return _currentVolume; // Return cached value on error
    }
  }

  @override
  Future<void> setVolume(double value) async {
    if (!isAvailable || !_isInitialized) return;

    // Clamp value to valid range and ensure double type
    final double clampedValue = (value.clamp(0.0, 1.0) as num).toDouble();

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