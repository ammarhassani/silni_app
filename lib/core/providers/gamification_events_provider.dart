import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gamification_event.dart';
import '../services/app_logger_service.dart';

/// Global stream controller for gamification events
/// This allows any part of the app to emit events and any widget to listen
class GamificationEventsController {
  final StreamController<GamificationEvent> _controller;
  final AppLoggerService _logger = AppLoggerService();

  GamificationEventsController()
      : _controller = StreamController<GamificationEvent>.broadcast();

  /// Emit a gamification event
  void emit(GamificationEvent event) {
    if (_controller.isClosed) {
      _logger.warning(
        'Attempted to emit event on closed controller',
        category: LogCategory.gamification,
        tag: 'GamificationEventsController',
        metadata: {'eventType': event.runtimeType.toString()},
      );
      return;
    }
    try {
      _controller.add(event);
    } catch (e) {
      // Log if controller is in an invalid state
      _logger.warning(
        'Failed to emit gamification event: $e',
        category: LogCategory.gamification,
        tag: 'GamificationEventsController',
        metadata: {'eventType': event.runtimeType.toString()},
      );
    }
  }

  /// Get the stream for listening
  Stream<GamificationEvent> get events => _controller.stream;

  /// Close the stream controller
  void dispose() {
    _controller.close();
  }
}

/// Provider for the gamification events controller
final gamificationEventsControllerProvider = Provider<GamificationEventsController>((ref) {
  final controller = GamificationEventsController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

/// Provider for the gamification events stream
final gamificationEventsStreamProvider = StreamProvider<GamificationEvent>((ref) {
  final controller = ref.watch(gamificationEventsControllerProvider);
  return controller.events;
});

/// Helper to emit events from anywhere in the app
extension GamificationEventsEmitter on WidgetRef {
  void emitGamificationEvent(GamificationEvent event) {
    read(gamificationEventsControllerProvider).emit(event);
  }
}
