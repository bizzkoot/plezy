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

  // Configuration constants are defined globally for easy customization

  /// Screen division ratio for left/right gesture zones
  /// 0.5 = 50% left for brightness, 50% right for volume
  static const double _screenSectionDivider = 0.5;

  /// Duration to show indicator after gesture ends
  static const Duration _indicatorDisplayDuration = Duration(milliseconds: 1000);

  /// Animation duration for indicator fade in/out
  static const Duration _indicatorFadeDuration = Duration(milliseconds: 200);

  /// Sensitivity factor for gesture-to-value conversion
  /// Higher = more sensitive (smaller swipe changes value more)
  /// Lower = less sensitive (larger swipe needed to change value)
  ///
  /// Recommended range: 0.001 to 0.005
  /// Current tuned for 1080p displays - may need adjustment for different screen sizes
  static const double _sensitivityFactor = 0.0025;

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