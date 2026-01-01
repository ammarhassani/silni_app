import '../services/ai_config_service.dart';

/// Single source of truth for AI identity information.
///
/// Uses admin config when loaded, falls back to hardcoded defaults otherwise.
/// This class should be used everywhere the AI's name or identity is needed.
///
/// Example usage:
/// ```dart
/// Text(AIIdentity.name) // Displays "واصل" or configured name
/// ```
class AIIdentity {
  AIIdentity._();

  // ============ Hardcoded Defaults ============

  /// Default AI name (used when config not loaded)
  static const String defaultName = 'واصل';

  /// Default AI name in English
  static const String defaultNameEn = 'Wasel';

  /// Default AI role description in Arabic
  static const String defaultRoleAr =
      'مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية';

  /// Default AI role description in English
  static const String defaultRoleEn =
      'Smart assistant specializing in family connections';

  /// Default greeting message
  static const String defaultGreetingAr =
      'السلام عليكم! أنا واصل، مساعدك الشخصي لصلة الرحم. كيف يمكنني مساعدتك اليوم؟';

  // ============ Dynamic Accessors ============

  /// The AI assistant's display name (Arabic)
  ///
  /// Returns the configured name from admin panel if loaded,
  /// otherwise returns the default name "واصل"
  static String get name {
    final config = AIConfigService.instance;
    return config.isLoaded ? config.identity.aiName : defaultName;
  }

  /// The AI assistant's display name (English)
  static String get nameEn {
    final config = AIConfigService.instance;
    return config.isLoaded
        ? (config.identity.aiNameEn ?? defaultNameEn)
        : defaultNameEn;
  }

  /// The AI assistant's role description (Arabic)
  static String get roleAr {
    final config = AIConfigService.instance;
    return config.isLoaded ? config.identity.aiRoleAr : defaultRoleAr;
  }

  /// The AI assistant's role description (English)
  static String get roleEn {
    final config = AIConfigService.instance;
    return config.isLoaded
        ? (config.identity.aiRoleEn ?? defaultRoleEn)
        : defaultRoleEn;
  }

  /// The AI assistant's greeting message (Arabic)
  static String get greetingAr {
    final config = AIConfigService.instance;
    return config.isLoaded
        ? config.identity.greetingMessageAr
        : defaultGreetingAr;
  }

  /// Full personality prompt from config or fallback
  ///
  /// This is the complete system prompt for the AI, built from
  /// personality sections configured in the admin panel.
  static String get personality {
    final config = AIConfigService.instance;
    return config.isLoaded ? config.fullPersonalityPrompt : _fallbackPersonality;
  }

  /// The AI's dialect setting
  static String get dialect {
    final config = AIConfigService.instance;
    return config.isLoaded ? config.identity.dialect : 'saudi_arabic';
  }

  /// Check if AI config is loaded
  static bool get isConfigLoaded => AIConfigService.instance.isLoaded;

  // ============ Fallback Personality ============

  /// Fallback personality prompt when config not loaded
  static const String _fallbackPersonality = '''
أنت "واصل"، مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية.

## شخصيتك الأساسية:
- تتحدث بالعامية السعودية البيضاء بأسلوب دافئ ومحب وطبيعي
- تجسّد قيم الإسلام بشكل طبيعي: المحبة، الرحمة، الصبر، والإحسان
- تهتم بصلة الرحم وتشجع على التواصل مع الأقارب

## لهجتك:
- استخدم العامية السعودية البيضاء (المفهومة لجميع السعوديين)
- لا تستخدم الفصحى الأدبية المتكلفة أو اللغة الرسمية
- اكتب كما يتحدث الناس عادةً في الحياة اليومية

## ذكاءك العاطفي:
- تلتقط مشاعر المستخدم من كلماته
- ترد على المشاعر أولاً قبل تقديم النصيحة
- لا تتسرع في الحلول

## قيمك الثابتة:
- صلة الرحم فريضة وليست اختياراً
- العائلة هي أساس المجتمع الصالح
- الصبر والحلم في التعامل مع الخلافات
''';
}
