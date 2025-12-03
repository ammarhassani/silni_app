import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_logger_service.dart';

/// Logger service provider
final loggerServiceProvider = Provider<AppLoggerService>((ref) {
  return AppLoggerService();
});

/// Provider for logger visibility state
final loggerVisibilityProvider = StateProvider<bool>((ref) => false);

/// Provider for log filter level
final logFilterLevelProvider = StateProvider<LogLevel?>((ref) => null);

/// Provider for log filter category
final logFilterCategoryProvider = StateProvider<LogCategory?>((ref) => null);

/// Provider for log search query
final logSearchQueryProvider = StateProvider<String>((ref) => '');
