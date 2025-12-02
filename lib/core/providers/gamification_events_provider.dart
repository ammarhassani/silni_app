import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gamification_event.dart';

/// Global stream controller for gamification events
/// This allows any part of the app to emit events and any widget to listen
class GamificationEventsController {
  final StreamController<GamificationEvent> _controller;

  GamificationEventsController()
      : _controller = StreamController<GamificationEvent>.broadcast();

  /// Emit a gamification event
  void emit(GamificationEvent event) {
    _controller.add(event);
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
