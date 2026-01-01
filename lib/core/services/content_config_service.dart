import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Singleton service that fetches and caches content from admin tables.
/// Provides dynamic content for hadith, quotes, MOTD, and banners.
class ContentConfigService {
  ContentConfigService._();
  static final ContentConfigService instance = ContentConfigService._();

  final SupabaseClient _supabase = SupabaseConfig.client;

  // Cache variables
  List<AdminHadith>? _hadithCache;
  List<AdminQuote>? _quotesCache;
  List<AdminMOTD>? _motdCache;
  List<AdminBanner>? _bannersCache;

  DateTime? _lastRefresh;
  static const Duration _cacheDuration = Duration(minutes: 10);

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
        _fetchMOTD(),
        _fetchBanners(),
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
    if (_lastRefresh == null ||
        DateTime.now().difference(_lastRefresh!) > _cacheDuration) {
      await refresh();
    }
  }

  /// Clear all caches
  void clearCache() {
    _hadithCache = null;
    _quotesCache = null;
    _motdCache = null;
    _bannersCache = null;
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

  // ============ Message of the Day ============

  Future<void> _fetchMOTD() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0]; // Date only
      final response = await _supabase
          .from('admin_motd')
          .select()
          .eq('is_active', true)
          .or('start_date.is.null,start_date.lte.$today')
          .or('end_date.is.null,end_date.gte.$today')
          .order('display_priority', ascending: false);
      _motdCache = (response as List)
          .map((json) => AdminMOTD.fromJson(json))
          .toList();
      debugPrint('[ContentConfigService] Loaded ${_motdCache?.length} MOTD');
    } catch (e) {
      debugPrint('[ContentConfigService] Error fetching MOTD: $e');
    }
  }

  List<AdminMOTD> get motdList =>
      _motdCache ?? AdminMOTD.fallbackMOTD();

  /// Get current MOTD (highest priority active message)
  AdminMOTD? getCurrentMOTD() {
    final list = motdList;
    if (list.isEmpty) return null;

    // Filter by valid date range
    final now = DateTime.now();
    final valid = list.where((m) {
      if (m.validFrom != null && now.isBefore(m.validFrom!)) return false;
      if (m.validUntil != null && now.isAfter(m.validUntil!)) return false;
      return true;
    }).toList();

    if (valid.isEmpty) return list.first; // Fallback to first
    return valid.first; // Already sorted by priority
  }

  /// Get MOTD by type
  List<AdminMOTD> getMOTDByType(String type) {
    return motdList.where((m) => m.messageType == type).toList();
  }

  // ============ Banners ============

  Future<void> _fetchBanners() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('admin_banners')
          .select()
          .eq('is_active', true)
          .or('start_date.is.null,start_date.lte.$now')
          .or('end_date.is.null,end_date.gte.$now')
          .order('display_priority', ascending: false);
      _bannersCache = (response as List)
          .map((json) => AdminBanner.fromJson(json))
          .toList();
      debugPrint('[ContentConfigService] Loaded ${_bannersCache?.length} banners');
    } catch (e) {
      debugPrint('[ContentConfigService] Error fetching banners: $e');
    }
  }

  List<AdminBanner> get bannersList => _bannersCache ?? [];

  /// Get banners for a specific position
  List<AdminBanner> getBannersForPosition(String position) {
    final now = DateTime.now();
    return bannersList.where((b) {
      if (b.position != position) return false;
      if (b.startDate != null && now.isBefore(b.startDate!)) return false;
      if (b.endDate != null && now.isAfter(b.endDate!)) return false;
      return true;
    }).toList();
  }

  /// Get banners for a specific audience
  List<AdminBanner> getBannersForAudience(String audience, String position) {
    return getBannersForPosition(position).where((b) {
      return b.targetAudience == 'all' || b.targetAudience == audience;
    }).toList();
  }

  /// Track banner impression
  Future<void> trackBannerImpression(String bannerId) async {
    try {
      await _supabase.rpc('increment_banner_impressions', params: {
        'banner_id': bannerId,
      });
    } catch (e) {
      debugPrint('[ContentConfigService] Error tracking impression: $e');
    }
  }

  /// Track banner click
  Future<void> trackBannerClick(String bannerId) async {
    try {
      await _supabase.rpc('increment_banner_clicks', params: {
        'banner_id': bannerId,
      });
    } catch (e) {
      debugPrint('[ContentConfigService] Error tracking click: $e');
    }
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

class AdminMOTD {
  final String id;
  final String messageType; // tip, motivation, reminder, announcement, celebration
  final String titleAr;
  final String? titleEn;
  final String contentAr;
  final String? contentEn;
  final String? emoji;
  final String? actionType;
  final String? actionTarget;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int displayPriority;

  AdminMOTD({
    required this.id,
    required this.messageType,
    required this.titleAr,
    this.titleEn,
    required this.contentAr,
    this.contentEn,
    this.emoji,
    this.actionType,
    this.actionTarget,
    this.validFrom,
    this.validUntil,
    required this.displayPriority,
  });

  factory AdminMOTD.fromJson(Map<String, dynamic> json) {
    // Map database columns to model properties
    // DB: title, message, type, icon, action_text, action_route, start_date, end_date
    return AdminMOTD(
      id: json['id'] as String,
      messageType: json['type'] as String? ?? 'tip',
      titleAr: json['title'] as String,
      titleEn: null, // Not in DB schema
      contentAr: json['message'] as String,
      contentEn: null, // Not in DB schema
      emoji: json['icon'] as String?, // Map icon to emoji
      actionType: json['action_route'] != null ? 'route' : null,
      actionTarget: json['action_route'] as String?,
      validFrom: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      validUntil: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      displayPriority: json['display_priority'] as int? ?? 0,
    );
  }

  static List<AdminMOTD> fallbackMOTD() {
    return [
      AdminMOTD(
        id: 'fallback_1',
        messageType: 'tip',
        titleAr: 'نصيحة اليوم',
        contentAr: 'تواصل مع أقاربك اليوم، رسالة بسيطة تصنع الفرق',
        emoji: '💡',
        displayPriority: 1,
      ),
    ];
  }
}

class AdminBanner {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final Map<String, dynamic>? backgroundGradient;
  final String actionType; // none, route, url, action
  final String? actionTarget;
  final String position; // home_top, home_bottom, profile, reminders
  final String targetAudience; // all, free, premium
  final DateTime? startDate;
  final DateTime? endDate;
  final int displayPriority;
  final int impressions;
  final int clicks;

  AdminBanner({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.backgroundGradient,
    required this.actionType,
    this.actionTarget,
    required this.position,
    required this.targetAudience,
    this.startDate,
    this.endDate,
    required this.displayPriority,
    this.impressions = 0,
    this.clicks = 0,
  });

  factory AdminBanner.fromJson(Map<String, dynamic> json) {
    return AdminBanner(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      backgroundGradient: json['background_gradient'] as Map<String, dynamic>?,
      actionType: json['action_type'] as String? ?? 'none',
      actionTarget: json['action_value'] as String?, // DB column is action_value
      position: json['position'] as String? ?? 'home_top',
      targetAudience: json['target_audience'] as String? ?? 'all',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      displayPriority: json['display_priority'] as int? ?? 0,
      impressions: json['impressions'] as int? ?? 0,
      clicks: json['clicks'] as int? ?? 0,
    );
  }

  /// Get gradient colors for UI
  List<int>? get gradientColors {
    if (backgroundGradient == null) return null;
    final start = backgroundGradient!['start'] as String?;
    final end = backgroundGradient!['end'] as String?;
    if (start == null || end == null) return null;

    return [
      int.parse('FF${start.replaceFirst('#', '')}', radix: 16),
      int.parse('FF${end.replaceFirst('#', '')}', radix: 16),
    ];
  }
}
