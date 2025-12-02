import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/gamification_provider.dart';
import '../services/interactions_service.dart';

/// Provider for the Interactions service with gamification support
final interactionsServiceProvider = Provider<InteractionsService>((ref) {
  final gamificationService = ref.watch(gamificationServiceProvider);
  return InteractionsService(gamificationService: gamificationService);
});
