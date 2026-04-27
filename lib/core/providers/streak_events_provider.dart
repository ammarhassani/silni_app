import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/streak_event.dart';
import '../services/app_logger_service.dart';

/// Global broadcast stream for streak events. Emit from streak services,
/// listen from UI (modal triggers, snackbars, notifications).
class StreakEventsController {
  final StreamController<StreakEvent> _controller;
  final AppLoggerService _logger = AppLoggerService();

  StreakEventsController()
      : _controller = StreamController<StreakEvent>.broadcast();

  void emit(StreakEvent event) {
    if (_controller.isClosed) {
      _logger.warning(
        'Attempted to emit on closed StreakEventsController',
        category: LogCategory.gamification,
        tag: 'StreakEventsController',
        metadata: {'eventType': event.type.toString()},
      );
      return;
    }
    try {
      _controller.add(event);
    } catch (e) {
      _logger.warning(
        'Failed to emit streak event: $e',
        category: LogCategory.gamification,
        tag: 'StreakEventsController',
        metadata: {'eventType': event.type.toString()},
      );
    }
  }

  Stream<StreakEvent> get events => _controller.stream;

  void dispose() => _controller.close();
}

final streakEventsControllerProvider = Provider<StreakEventsController>((ref) {
  final controller = StreakEventsController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final streakEventsStreamProvider = StreamProvider<StreakEvent>((ref) {
  final controller = ref.watch(streakEventsControllerProvider);
  return controller.events;
});

extension StreakEventsEmitter on WidgetRef {
  void emitStreakEvent(StreakEvent event) {
    read(streakEventsControllerProvider).emit(event);
  }
}
