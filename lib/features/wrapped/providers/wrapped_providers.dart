import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/providers/cache_provider.dart';
import '../models/monthly_wrapped_model.dart';
import '../services/wrapped_generator_service.dart';

/// Provides a [MonthlyWrapped] for the given calendar month.
///
/// Fetches interactions from the interactions repository (streams the first
/// emission) and relatives from the relatives repository, then delegates to
/// [WrappedGeneratorService.generate].
///
/// The parameter is a [DateTime] anywhere within the target month.
final monthlyWrappedProvider =
    FutureProvider.autoDispose.family<MonthlyWrapped, DateTime>(
  (ref, month) async {
    final userId = SupabaseConfig.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final interactionsRepo = ref.read(interactionsRepositoryProvider);
    final relativesRepo = ref.read(relativesRepositoryProvider);

    // Stream-based repos: take the first emission which includes cached data.
    final interactions =
        await interactionsRepo.watchUserInteractions(userId).first;
    final relatives = await relativesRepo.watchRelatives(userId).first;

    return WrappedGeneratorService.generate(
      interactions: interactions,
      relatives: relatives,
      month: month,
    );
  },
);
