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