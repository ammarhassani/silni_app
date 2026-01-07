import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'cache_config_service.dart';

/// Singleton service that fetches and caches content from admin tables.
/// Provides dynamic content for hadith and quotes.
/// Note: MOTD and Banners are now handled by MessageService (unified messaging system).
class ContentConfigService {
  ContentConfigService._();
  static final ContentConfigService instance = ContentConfigService._();

  final SupabaseClient _supabase = SupabaseConfig.client;

  // Cache variables
  List<AdminHadith>? _hadithCache;
  List<AdminQuote>? _quotesCache;

  DateTime? _lastRefresh;
  final CacheConfigService _cacheConfig = CacheConfigService();
  static const String _serviceKey = 'content_config';

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool get isLoaded => _hadithCache != null;

  /// Refresh all content from admin tables
  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      await Future.wait([
        _fetchHadith(),
        _fetchQuotes(),
      ]);
      _lastRefresh = DateTime.now();
      debugPrint('[ContentConfigService] Refreshed all content');
    } catch (e) {
      debugPrint('[ContentConfigService] Error refreshing: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Check if cache is stale and needs refresh
  Future<void> ensureFresh() async {
    if (_cacheConfig.isCacheExpired(_serviceKey, _lastRefresh)) {
      await refresh();
    }
  }

  /// Clear all caches
  void clearCache() {
    _hadithCache = null;
    _quotesCache = null;
    _lastRefresh = null;
  }

  // ============ Hadith ============

  Future<void> _fetchHadith() async {
    try {
      final response = await _supabase
          .from('admin_hadith')
          .select()
          .eq('is_active', true)
          .order('display_priority', ascending: false);
      _hadithCache = (response as List)
          .map((json) => AdminHadith.fromJson(json))
          .toList();
      debugPrint('[ContentConfigService] Loaded ${_hadithCache?.length} hadith');
    } catch (e) {
      debugPrint('[ContentConfigService] Error fetching hadith: $e');
    }
  }

  List<AdminHadith> get hadithList =>
      _hadithCache ?? AdminHadith.fallbackHadith();

  /// Get a daily hadith (rotates based on day of year)
  AdminHadith? getDailyHadith() {
    final list = hadithList;
    if (list.isEmpty) return null;
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return list[dayOfYear % list.length];
  }

  /// Get a random hadith
  AdminHadith? getRandomHadith() {
    final list = hadithList;
    if (list.isEmpty) return null;
    return list[Random().nextInt(list.length)];
  }

  /// Get daily Islamic content (alternates between hadith and quotes)
  /// Returns either AdminHadith or AdminQuote based on the day
  dynamic getDailyIslamicContent() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;

    // Alternate between hadith and quotes
    if (dayOfYear % 2 == 0) {
      // Even days: hadith
      final list = hadithList;
      if (list.isNotEmpty) {
        return list[(dayOfYear ~/ 2) % list.length];
      }
    } else {
      // Odd days: quotes
      final list = quotesList;
      if (list.isNotEmpty) {
        return list[(dayOfYear ~/ 2) % list.length];
      }
    }

    // Fallback to hadith if quotes empty
    return getDailyHadith();
  }

  // ============ Quotes ============

  Future<void> _fetchQuotes() async {
    try {
      final response = await _supabase
          .from('admin_quotes')
          .select()
          .eq('is_active', true)
          .order('display_priority', ascending: false);
      _quotesCache = (response as List)
          .map((json) => AdminQuote.fromJson(json))
          .toList();
      debugPrint('[ContentConfigService] Loaded ${_quotesCache?.length} quotes');
    } catch (e) {
      debugPrint('[ContentConfigService] Error fetching quotes: $e');
    }
  }

  List<AdminQuote> get quotesList =>
      _quotesCache ?? AdminQuote.fallbackQuotes();

  /// Get a daily quote (rotates based on day of year)
  AdminQuote? getDailyQuote() {
    final list = quotesList;
    if (list.isEmpty) return null;
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return list[dayOfYear % list.length];
  }

  /// Get quotes by category
  List<AdminQuote> getQuotesByCategory(String category) {
    return quotesList.where((q) => q.category == category).toList();
  }

}

// ============ Models ============

class AdminHadith {
  final String id;
  final String hadithText;
  final String source;
  final String? narrator;
  final String? grade;
  final String category;
  final List<String> tags;
  final int displayPriority;

  AdminHadith({
    required this.id,
    required this.hadithText,
    required this.source,
    this.narrator,
    this.grade,
    required this.category,
    required this.tags,
    required this.displayPriority,
  });

  factory AdminHadith.fromJson(Map<String, dynamic> json) {
    return AdminHadith(
      id: json['id'] as String,
      hadithText: json['hadith_text'] as String,
      source: json['source'] as String,
      narrator: json['narrator'] as String?,
      grade: json['grade'] as String?,
      category: json['category'] as String? ?? 'general',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      displayPriority: json['display_priority'] as int? ?? 0,
    );
  }

  static List<AdminHadith> fallbackHadith() {
    return [
      AdminHadith(
        id: 'fallback_1',
        hadithText: 'قال رسول الله ﷺ: "مَن أَحَبَّ أَنْ يُبْسَطَ له في رِزْقِهِ، وَيُنْسَأَ له في أَثَرِهِ، فَلْيَصِلْ رَحِمَهُ"',
        source: 'صحيح البخاري',
        narrator: 'أنس بن مالك',
        grade: 'صحيح',
        category: 'silat_rahim',
        tags: ['صلة الرحم', 'الرزق'],
        displayPriority: 1,
      ),
      AdminHadith(
        id: 'fallback_2',
        hadithText: 'قال رسول الله ﷺ: "الرَّحِمُ مُعَلَّقَةٌ بالعَرْشِ تَقُولُ: مَن وصَلَنِي وصَلَهُ اللَّهُ، ومَن قَطَعَنِي قَطَعَهُ اللَّهُ"',
        source: 'صحيح البخاري',
        narrator: 'عبد الرحمن بن عوف',
        grade: 'صحيح',
        category: 'silat_rahim',
        tags: ['صلة الرحم'],
        displayPriority: 2,
      ),
      AdminHadith(
        id: 'fallback_3',
        hadithText: 'قال رسول الله ﷺ: "لا يَدْخُلُ الجَنَّةَ قاطِعُ رَحِمٍ"',
        source: 'صحيح البخاري',
        narrator: 'جبير بن مطعم',
        grade: 'صحيح',
        category: 'silat_rahim',
        tags: ['صلة الرحم', 'الجنة'],
        displayPriority: 3,
      ),
      AdminHadith(
        id: 'fallback_4',
        hadithText: 'قال رسول الله ﷺ: "ليس الواصِلُ بالمُكافِئِ، ولكنَّ الواصِلَ الذي إذا قُطِعَتْ رَحِمُهُ وصَلَها"',
        source: 'صحيح البخاري',
        narrator: 'عبد الله بن عمرو',
        grade: 'صحيح',
        category: 'silat_rahim',
        tags: ['صلة الرحم', 'الصبر'],
        displayPriority: 4,
      ),
    ];
  }
}

class AdminQuote {
  final String id;
  final String quoteText;
  final String category;
  final String? source;
  final String? author;
  final List<String> tags;
  final int displayPriority;

  AdminQuote({
    required this.id,
    required this.quoteText,
    required this.category,
    this.source,
    this.author,
    required this.tags,
    required this.displayPriority,
  });

  factory AdminQuote.fromJson(Map<String, dynamic> json) {
    return AdminQuote(
      id: json['id'] as String,
      quoteText: json['quote_text'] as String,
      category: json['category'] as String? ?? 'general',
      source: json['source'] as String?,
      author: json['author'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      displayPriority: json['display_priority'] as int? ?? 0,
    );
  }

  static List<AdminQuote> fallbackQuotes() {
    return [
      AdminQuote(
        id: 'fallback_1',
        quoteText: 'صلة الرحم من أعظم القربات وأجل الطاعات',
        category: 'wisdom',
        author: 'ابن قدامة المقدسي',
        source: 'المغني',
        tags: ['صلة الرحم'],
        displayPriority: 1,
      ),
      AdminQuote(
        id: 'fallback_2',
        quoteText: 'صلة الرحم تزيد في العمر وتوسع في الرزق وتدفع ميتة السوء',
        category: 'wisdom',
        author: 'الإمام أحمد',
        source: 'مسند الإمام أحمد',
        tags: ['صلة الرحم', 'البركة'],
        displayPriority: 2,
      ),
    ];
  }
}

// Note: AdminMOTD and AdminBanner classes have been removed.
// Use MessageService for unified messaging (MOTD, banners, in-app messages).
