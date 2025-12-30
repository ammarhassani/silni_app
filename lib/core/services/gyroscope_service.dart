import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../constants/pattern_animation_constants.dart';
import 'app_logger_service.dart';

/// Normalized gyroscope data for pattern parallax
class GyroscopeData {
  /// X-axis rotation rate (-1.0 to 1.0)
  final double x;

  /// Y-axis rotation rate (-1.0 to 1.0)
  final double y;

  /// Z-axis rotation rate (-1.0 to 1.0)
  final double z;

  const GyroscopeData({
    required this.x,
    required this.y,
    required this.z,
  });

  static const zero = GyroscopeData(x: 0, y: 0, z: 0);
}

/// Service for accessing device gyroscope data.
///
/// Battery-efficient: only active when explicitly started.
/// Provides normalized data suitable for parallax effects.
class GyroscopeService {
  static GyroscopeService? _instance;
  final AppLoggerService _logger = AppLoggerService();

  StreamSubscription<GyroscopeEvent>? _subscription;
  final _controller = StreamController<GyroscopeData>.broadcast();

  bool _isAvailable = false;
  bool _isListening = false;

  // Smoothing for parallax effect
  double _smoothX = 0;
  double _smoothY = 0;
  static const double _smoothingFactor = 0.15;

  GyroscopeService._() {
    _checkAvailability();
  }

  /// Singleton instance
  static GyroscopeService get instance {
    _instance ??= GyroscopeService._();
    return _instance!;
  }

  /// Stream of normalized gyroscope data
  Stream<GyroscopeData>? get stream => _isAvailable ? _controller.stream : null;

  /// Whether gyroscope is available on this device
  bool get isAvailable => _isAvailable;

  /// Whether currently listening to gyroscope events
  bool get isListening => _isListening;

  Future<void> _checkAvailability() async {
    try {
      // Try to get a single event to verify availability
      await gyroscopeEventStream().first.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          throw TimeoutException('Gyroscope not responding');
        },
      );
      _isAvailable = true;
      _logger.info(
        'Gyroscope is available',
        category: LogCategory.service,
        tag: 'GyroscopeService',
      );
    } catch (e) {
      _isAvailable = false;
      _logger.info(
        'Gyroscope not available on this device',
        category: LogCategory.service,
        tag: 'GyroscopeService',
        metadata: {'reason': e.toString()},
      );
    }
  }

  /// Start listening to gyroscope events
  void startListening() {
    if (!_isAvailable || _isListening) return;

    _subscription = gyroscopeEventStream(
      samplingPeriod: PatternAnimationConstants.gyroscopeSamplingPeriod,
    ).listen(
      _handleGyroscopeEvent,
      onError: (error) {
        _logger.warning(
          'Gyroscope error',
          category: LogCategory.service,
          tag: 'GyroscopeService',
          metadata: {'error': error.toString()},
        );
      },
    );

    _isListening = true;
    _logger.debug(
      'Started gyroscope listening',
      category: LogCategory.service,
      tag: 'GyroscopeService',
    );
  }

  void _handleGyroscopeEvent(GyroscopeEvent event) {
    // Normalize values to -1.0 to 1.0 range
    // Gyroscope typically reports rad/s, we clamp for reasonable tilt
    final normalizedX = (event.x / 2.0).clamp(-1.0, 1.0);
    final normalizedY = (event.y / 2.0).clamp(-1.0, 1.0);

    // Apply smoothing for fluid parallax motion
    _smoothX = _smoothX + (_smoothingFactor * (normalizedX - _smoothX));
    _smoothY = _smoothY + (_smoothingFactor * (normalizedY - _smoothY));

    _controller.add(GyroscopeData(
      x: _smoothX,
      y: _smoothY,
      z: (event.z / 2.0).clamp(-1.0, 1.0),
    ));
  }

  /// Stop listening to gyroscope events
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    _smoothX = 0;
    _smoothY = 0;

    _logger.debug(
      'Stopped gyroscope listening',
      category: LogCategory.service,
      tag: 'GyroscopeService',
    );
  }

  /// Clean up resources
  void dispose() {
    stopListening();
    _controller.close();
    _instance = null;
  }
}
