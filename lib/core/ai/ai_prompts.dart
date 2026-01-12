// AI System Prompts Library
// Contains all system prompts for different AI features

import '../../shared/models/relative_model.dart';
import '../services/ai_config_service.dart';
import 'ai_context_engine.dart';
import 'ai_identity.dart';
import 'ai_models.dart';

/// System prompts for the AI assistant
class AIPrompts {
  AIPrompts._();

  /// Get dynamic personality prompt from admin config (with fallback)
  ///
  /// Uses [AIIdentity.personality] as single source of truth.
  static String get dynamicPersonality => AIIdentity.personality;

  /// Get mode instructions from admin config (with fallback)
  static String getDynamicModeInstructions(String modeKey) {
    final config = AIConfigService.instance;
    final mode = config.getModeByKey(modeKey);
    if (mode != null) {
      return '''
## وضع ${mode.displayNameAr}:
${mode.modeInstructions}
''';
    }
    // Fallback to hardcoded
    return getModeInstructions(CounselingMode.fromString(modeKey));
  }

  /// Base personality prompt for واصل (the family assistant) - FALLBACK
  static const String basePersonality = '''
أنت "واصل"، مساعد ذكي متخصص في صلة الرحم والعلاقات الأسرية.

## شخصيتك الأساسية:
- تتحدث بالعامية السعودية البيضاء بأسلوب دافئ ومحب وطبيعي
- تجسّد قيم الإسلام بشكل طبيعي: المحبة، الرحمة، الصبر، والإحسان

## لهجتك:
- استخدم العامية السعودية البيضاء (المفهومة لجميع السعوديين)
- لا تستخدم الفصحى الأدبية المتكلفة أو اللغة الرسمية
- اكتب كما يتحدث الناس عادةً في الحياة اليومية
- أمثلة على الأسلوب الصحيح:
  ✓ "وش رايك تتصل على أبوك اليوم؟"
  ✓ "حاول تزوره هالأسبوع"
  ✓ "ما تشوف إنك تأخرت عليه؟"
  ✓ "ليه ما تكلمه وتسأل عنه؟"
  ✓ "خلك على تواصل معاه"
- أمثلة على الأسلوب الخاطئ (تجنبه):
  ✗ "ما رأيك في أن تقوم بالاتصال بوالدك؟"
  ✗ "أقترح عليك زيارته في هذا الأسبوع"
  ✗ "ينبغي عليك المبادرة بالتواصل"
  ✗ "أنصحك بأن تبادر إلى صلة رحمك"
- لا تكتفي باقتباس الأحاديث، بل تعيش معانيها في كل نصيحة
- تعامل كل مستخدم كصديق تريد له الخير
- تستخدم التعاطف الحقيقي وليس العبارات الجاهزة

## ذكاءك العاطفي:
- تلتقط مشاعر المستخدم من كلماته (قلق، حزن، غضب، إحباط)
- ترد على المشاعر أولاً قبل تقديم النصيحة
- تستخدم عبارات تعكس الفهم: "أشعر بما تمر به..."، "هذا موقف صعب فعلاً..."
- لا تتسرع في الحلول، أحياناً المستخدم يريد من يستمع له فقط
- تعرف متى تسأل أسئلة استكشافية بدلاً من تقديم إجابات مباشرة

## قيمك الثابتة:
- صلة الرحم فريضة وليست اختياراً
- العائلة هي أساس المجتمع الصالح
- الصبر والحلم في التعامل مع الخلافات
- لا تشجّع على أي علاقات محرمة أو مخالفة للشريعة

## أسلوبك في النصح:
- استمع جيداً قبل النصيحة
- تفهّم مشاعر المستخدم وصدّقها
- قدّم نصائح عملية وقابلة للتطبيق فوراً
- استخدم الحكمة الإسلامية بشكل طبيعي غير متكلف
- شجّع دائماً على التواصل والمصالحة
- قدّم خيارات متعددة واترك القرار للمستخدم
- استخدم أمثلة عملية من الحياة اليومية

## ما يجب تجنبه:
- الأحكام القاسية أو اللوم المباشر
- النصائح السطحية أو العامة جداً
- تشجيع القطيعة إلا في حالات الضرر الشديد
- الدخول في مواضيع فقهية معقدة (وجّه للعلماء)
- الردود الطويلة المملة - كن موجزاً ومركزاً
- تكرار نفس العبارات في كل رد

## قاعدة صارمة - الدقة المطلقة:
⚠️ لا تختلق أو تفترض أي معلومات غير موجودة في السياق.
⚠️ إذا لم تجد بيانات عن تواصل المستخدم، لا تدّعي أنه تواصل مع أحد.
⚠️ لا تقل "أرى أنك تواصلت" إلا إذا كانت البيانات موجودة فعلاً.
⚠️ إذا لم تكن متأكداً، اسأل المستخدم بدلاً من الافتراض.
⚠️ الصدق أهم من الظهور بمظهر المطّلع.
''';

  /// Get mode-specific instructions
  static String getModeInstructions(CounselingMode mode) {
    switch (mode) {
      case CounselingMode.general:
        return '''
## وضع المحادثة العامة:
- ساعد المستخدم في أي موضوع يخص العائلة
- اقترح طرقاً للتواصل مع الأقارب
- قدّم تشجيعاً مستمراً على صلة الرحم
- كن مرناً في المواضيع المطروحة
''';
      case CounselingMode.relationship:
        return '''
## وضع نصائح العلاقات:
- ركّز على تعزيز الروابط الأسرية
- اقترح أنشطة مشتركة وطرق تواصل
- ساعد في فهم احتياجات كل طرف
- شجّع على الزيارات والاتصالات المنتظمة
- قدّم أفكاراً لتقوية العلاقة
''';
      case CounselingMode.conflict:
        return '''
## وضع حل الخلافات:
- استمع بتعاطف دون انحياز
- ساعد في فهم وجهة نظر الطرف الآخر
- اقترح خطوات عملية للمصالحة
- ذكّر بأهمية العفو والتسامح
- لا تشجّع على القطيعة إلا في حالات الضرر الشديد
- ساعد في صياغة كلمات الاعتذار إن لزم
''';
      case CounselingMode.communication:
        return '''
## وضع التواصل الفعّال:
- ساعد في صياغة رسائل ومحادثات
- علّم أساليب التواصل اللطيف
- اقترح أوقات وطرق مناسبة للتواصل
- ساعد في التعامل مع الشخصيات المختلفة
- قدّم نصوصاً جاهزة للمحادثات الصعبة
''';
    }
  }

  /// Build context for a specific relative
  static String buildRelativeContext(Relative relative) {
    final buffer = StringBuffer();
    buffer.writeln('''

## معلومات القريب الحالي:
- الاسم: ${relative.fullName}
- العلاقة: ${relative.relationshipType.arabicName}
- الأولوية: ${_getPriorityArabic(relative.priority)}
''');

    if (relative.lastContactDate != null) {
      final days = relative.daysSinceLastContact ?? 0;
      if (days == 0) {
        buffer.writeln('- آخر تواصل: اليوم ✓');
      } else if (days == 1) {
        buffer.writeln('- آخر تواصل: أمس');
      } else if (days <= 7) {
        buffer.writeln('- آخر تواصل: منذ $days أيام');
      } else if (days <= 30) {
        buffer.writeln('- آخر تواصل: منذ ${(days / 7).round()} أسابيع ⚠️');
      } else {
        buffer.writeln('- آخر تواصل: منذ ${(days / 30).round()} شهور 🔴');
      }
    }

    // Add health status
    final healthScore = relative.healthScore;
    if (healthScore != null) {
      final healthStatus = relative.healthStatus2;
      String healthLabel;
      switch (healthStatus) {
        case RelationshipHealthStatus.healthy:
          healthLabel = 'صحية 🟢';
        case RelationshipHealthStatus.needsAttention:
          healthLabel = 'تحتاج اهتمام 🟡';
        case RelationshipHealthStatus.atRisk:
          healthLabel = 'معرضة للخطر 🔴';
        case RelationshipHealthStatus.unknown:
          healthLabel = 'غير محددة';
      }
      buffer.writeln('- صحة العلاقة: $healthLabel ($healthScore%)');
    }

    if (relative.personalityType != null) {
      buffer.writeln('- نوع الشخصية: ${relative.personalityType}');
    }

    if (relative.communicationStyle != null) {
      buffer.writeln('- أسلوب التواصل المفضل: ${relative.communicationStyle}');
    }

    if (relative.interests != null && relative.interests!.isNotEmpty) {
      buffer.writeln('- الاهتمامات: ${relative.interests!.join("، ")}');
    }

    if (relative.sensitiveTopics != null && relative.sensitiveTopics!.isNotEmpty) {
      buffer.writeln('- ⚠️ مواضيع حساسة يجب تجنبها: ${relative.sensitiveTopics!.join("، ")}');
    }

    if (relative.relationshipChallenges != null) {
      buffer.writeln('- تحديات العلاقة: ${relative.relationshipChallenges}');
    }

    if (relative.relationshipStrengths != null) {
      buffer.writeln('- نقاط قوة العلاقة: ${relative.relationshipStrengths}');
    }

    if (relative.conflictHistory != null) {
      buffer.writeln('- تاريخ الخلافات: ${relative.conflictHistory}');
    }

    if (relative.aiNotes != null) {
      buffer.writeln('- ملاحظات إضافية: ${relative.aiNotes}');
    }

    return buffer.toString();
  }

  static String _getPriorityArabic(int priority) {
    switch (priority) {
      case 1:
        return 'عالية (والدين، زوج/ة)';
      case 2:
        return 'متوسطة (إخوة، أجداد)';
      default:
        return 'عادية (أقارب آخرون)';
    }
  }

  /// Build full system prompt for chat with full context
  /// Uses dynamic config from admin panel with fallback to hardcoded values
  static String buildChatSystemPrompt({
    required CounselingMode mode,
    Relative? relative,
    List<Relative>? allRelatives,
    List<AIMemory>? memories,
  }) {
    // Use dynamic personality from admin config (falls back to hardcoded if not loaded)
    final buffer = StringBuffer(dynamicPersonality);
    buffer.writeln();
    // Use dynamic mode instructions from admin config
    buffer.writeln(getDynamicModeInstructions(mode.name));

    // Add all relatives context if available
    if (allRelatives != null && allRelatives.isNotEmpty) {
      buffer.writeln(buildAllRelativesContext(allRelatives));
    }

    // Add specific relative context if talking about one
    if (relative != null) {
      buffer.writeln('\n## القريب المحدد في هذه المحادثة:');
      buffer.writeln(buildRelativeContext(relative));
    }

    // Add memories context (prioritize memories about the specific relative if any)
    if (memories != null && memories.isNotEmpty) {
      buffer.writeln(buildMemoriesContext(memories, relativeId: relative?.id));
    }

    return buffer.toString();
  }

  /// Build enhanced system prompt using AIContext from AIContextEngine
  ///
  /// This provides richer context including:
  /// - Gamification data (level, points, streaks)
  /// - Upcoming occasions
  /// - Health summary across all relatives
  /// - Recent interactions
  static String buildEnhancedChatSystemPrompt({
    required CounselingMode mode,
    required AIContext context,
  }) {
    final buffer = StringBuffer(dynamicPersonality);
    buffer.writeln();
    buffer.writeln(getDynamicModeInstructions(mode.name));

    // Add gamification context
    buffer.writeln('''

## معلومات المستخدم:
- المستوى: ${context.gamification.level}
- إجمالي النقاط: ${context.gamification.totalPoints}
- إجمالي التفاعلات: ${context.gamification.totalInteractions}
- الشعلات النشطة: ${context.totalActiveStreaks}
''');

    // Add health summary
    buffer.writeln('''
## ملخص صحة العلاقات:
- علاقات صحية 🟢: ${context.healthSummary.healthyCount}
- تحتاج اهتمام 🟡: ${context.healthSummary.needsAttentionCount}
- معرضة للخطر 🔴: ${context.healthSummary.atRiskCount}
''');

    // Add upcoming occasions
    if (context.upcomingOccasions.isNotEmpty) {
      buffer.writeln('\n## مناسبات قادمة:');
      for (final occasion in context.upcomingOccasions.take(5)) {
        buffer.writeln('- ${occasion.relativeName}: ${occasion.occasionType} بعد ${occasion.daysUntil} يوم');
      }
    }

    // Add relatives context
    if (context.relatives.isNotEmpty) {
      buffer.writeln(buildAllRelativesContext(context.relatives));
    }

    // Add focus relative context if present
    if (context.focusRelative != null) {
      buffer.writeln('\n## القريب المحدد في هذه المحادثة:');
      buffer.writeln(buildRelativeContext(context.focusRelative!));

      // Add streak info for focus relative
      final streak = context.getStreakFor(context.focusRelative!.id);
      if (streak != null && streak.currentStreak > 0) {
        buffer.writeln('- شعلة التواصل: ${streak.currentStreak} يوم 🔥');
      }
    }

    // Add memories context
    if (context.memories.isNotEmpty) {
      buffer.writeln(buildMemoriesContext(context.memories, relativeId: context.focusRelative?.id));
    }

    return buffer.toString();
  }

  /// Build context for all user's relatives
  static String buildAllRelativesContext(List<Relative> relatives) {
    final buffer = StringBuffer();

    // Calculate health summary
    final healthyCount = relatives.where((r) => r.healthStatus2 == RelationshipHealthStatus.healthy).length;
    final needsAttentionCount = relatives.where((r) => r.healthStatus2 == RelationshipHealthStatus.needsAttention).length;
    final atRiskCount = relatives.where((r) => r.healthStatus2 == RelationshipHealthStatus.atRisk).length;

    buffer.writeln('''

## عائلة المستخدم:
المستخدم لديه ${relatives.length} قريب مسجل في التطبيق.

### ملخص صحة العلاقات:
- علاقات صحية 🟢: $healthyCount
- تحتاج اهتمام 🟡: $needsAttentionCount
- معرضة للخطر 🔴: $atRiskCount

### تفاصيل الأقارب:
''');

    // Group by relationship type for clarity
    final parents = relatives.where((r) =>
        r.relationshipType.arabicName.contains('أب') ||
        r.relationshipType.arabicName.contains('أم') ||
        r.relationshipType.arabicName.contains('والد'));
    final siblings = relatives.where((r) =>
        r.relationshipType.arabicName.contains('أخ') ||
        r.relationshipType.arabicName.contains('أخت'));
    final extended = relatives.where((r) =>
        !parents.contains(r) && !siblings.contains(r));

    if (parents.isNotEmpty) {
      buffer.writeln('#### الوالدين:');
      for (final relative in parents) {
        buffer.writeln(_buildBriefRelativeInfo(relative));
      }
    }

    if (siblings.isNotEmpty) {
      buffer.writeln('\n#### الإخوة والأخوات:');
      for (final relative in siblings) {
        buffer.writeln(_buildBriefRelativeInfo(relative));
      }
    }

    if (extended.isNotEmpty) {
      buffer.writeln('\n#### الأقارب الآخرون:');
      for (final relative in extended) {
        buffer.writeln(_buildBriefRelativeInfo(relative));
      }
    }

    // Highlight relatives needing attention
    final needingAttention = relatives
        .where((r) => r.healthStatus2 == RelationshipHealthStatus.needsAttention ||
                      r.healthStatus2 == RelationshipHealthStatus.atRisk)
        .toList();

    if (needingAttention.isNotEmpty) {
      buffer.writeln('\n### ⚠️ أقارب يحتاجون اهتماماً عاجلاً:');
      for (final relative in needingAttention) {
        final days = relative.daysSinceLastContact ?? 0;
        buffer.writeln('- **${relative.fullName}** (${relative.relationshipType.arabicName}) - لم يتواصل منذ $days يوم');
      }
    }

    buffer.writeln('''

**ملاحظة:** عندما يذكر المستخدم اسم أحد أقاربه أو صلة قرابته، استخدم هذه المعلومات لتقديم نصائح مخصصة.
إذا سأل عن نصيحة عامة، يمكنك الإشارة إلى الأقارب الذين يحتاجون اهتماماً.
''');

    return buffer.toString();
  }

  /// Brief info for a relative in the list
  static String _buildBriefRelativeInfo(Relative relative) {
    final buffer = StringBuffer();

    // Add health status indicator
    String healthIcon = '';
    switch (relative.healthStatus2) {
      case RelationshipHealthStatus.healthy:
        healthIcon = '🟢';
      case RelationshipHealthStatus.needsAttention:
        healthIcon = '🟡';
      case RelationshipHealthStatus.atRisk:
        healthIcon = '🔴';
      case RelationshipHealthStatus.unknown:
        healthIcon = '⚪';
    }

    buffer.write('- $healthIcon **${relative.fullName}** (${relative.relationshipType.arabicName})');

    final days = relative.daysSinceLastContact;
    if (days != null) {
      if (days == 0) {
        buffer.write(' - تواصل اليوم ✓');
      } else if (days == 1) {
        buffer.write(' - آخر تواصل: أمس');
      } else if (days <= 7) {
        buffer.write(' - آخر تواصل: منذ $days أيام');
      } else if (days <= 30) {
        buffer.write(' - آخر تواصل: منذ ${(days / 7).round()} أسابيع');
      } else {
        buffer.write(' - آخر تواصل: منذ ${(days / 30).round()} شهور ⚠️');
      }
    } else {
      buffer.write(' - [لا توجد بيانات تواصل مسجلة]');
    }

    if (relative.personalityType != null) {
      buffer.write(' | ${relative.personalityType}');
    }

    return buffer.toString();
  }

  /// Build context from AI memories with better categorization
  /// Uses dynamic category config from admin panel
  static String buildMemoriesContext(List<AIMemory> memories, {String? relativeId}) {
    if (memories.isEmpty) return '';

    // Get active categories
    final activeKeys = activeMemoryCategoryKeys;

    // Filter to only active categories
    final activeMemories = memories.where((m) => activeKeys.contains(m.category.value)).toList();
    if (activeMemories.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('''

## ذاكرتي عن هذا المستخدم:
تذكر هذه المعلومات المهمة من محادثاتنا السابقة:
''');

    // Sort by importance
    final sortedMemories = [...activeMemories]
      ..sort((a, b) => b.importance.compareTo(a.importance));

    // If we have a specific relative context, prioritize their memories
    List<AIMemory> relevantMemories;
    if (relativeId != null) {
      final relativeMemories = sortedMemories
          .where((m) => m.relativeId == relativeId)
          .take(10)
          .toList();
      final otherMemories = sortedMemories
          .where((m) => m.relativeId != relativeId)
          .take(20)
          .toList();
      relevantMemories = [...relativeMemories, ...otherMemories];
    } else {
      relevantMemories = sortedMemories.take(30).toList();
    }

    // Get category display names from admin config
    final config = AIConfigService.instance;
    String getCategoryName(String key, String fallback) {
      if (!config.isLoaded) return fallback;
      final cat = config.memoryCategories.cast<AIMemoryCategoryConfig?>().firstWhere(
        (c) => c?.categoryKey == key,
        orElse: () => null,
      );
      return cat?.displayNameAr ?? fallback;
    }

    // Group by category and output only active ones
    final grouped = <String, List<AIMemory>>{};
    for (final memory in relevantMemories) {
      final key = memory.category.value;
      grouped.putIfAbsent(key, () => []).add(memory);
    }

    // Define category order and fallback names
    final categoryOrder = [
      ('user_preference', 'عن المستخدم'),
      ('relative_fact', 'عن الأقارب'),
      ('family_dynamic', 'ديناميكيات عائلية'),
      ('important_date', 'تواريخ مهمة'),
      ('conversation_insight', 'ملاحظات من محادثات سابقة'),
    ];

    for (final (key, fallbackName) in categoryOrder) {
      if (!activeKeys.contains(key)) continue;
      final categoryMemories = grouped[key];
      if (categoryMemories == null || categoryMemories.isEmpty) continue;

      final displayName = getCategoryName(key, fallbackName);
      buffer.writeln('### $displayName:');

      // Limit insights to 5
      final limit = key == 'conversation_insight' ? 5 : categoryMemories.length;
      for (final memory in categoryMemories.take(limit)) {
        buffer.writeln('- ${memory.content}');
      }
      buffer.writeln();
    }

    buffer.writeln('''
**استخدم هذه المعلومات لتقديم نصائح شخصية ومخصصة. لا تسأل عن معلومات تعرفها مسبقاً.**
''');

    return buffer.toString();
  }

  /// System prompt for extracting memories from conversation - FALLBACK
  /// IMPORTANT: This prompt explicitly tells AI NOT to extract data already in relatives table
  static const String _fallbackMemoryExtractionPrompt = '''
حلل هذه المحادثة واستخرج معلومات جديدة ومفيدة فقط.

⚠️ هام جداً - لا تستخرج هذه المعلومات (موجودة بالفعل في قاعدة البيانات):
- أسماء الأقارب (الأب، الأم، الإخوة، إلخ)
- نوع صلة القرابة
- معلومات أساسية عن الأقارب موجودة في ملفاتهم

✅ استخرج فقط:
- user_preference: تفضيلات شخصية للمستخدم (أسلوب تواصله، اهتماماته، شخصيته)
- important_date: تواريخ مهمة جديدة (مناسبات، ذكريات، أحداث قادمة)
- conversation_insight: مشاعر أو مخاوف أو أهداف عبّر عنها المستخدم

أعد JSON فقط بهذا الشكل:
{
  "memories": [
    {
      "category": "user_preference",
      "content": "المعلومة بالعربية",
      "importance": 7
    }
  ]
}

## أمثلة على ما يجب تجاهله:
❌ "اسم والد المستخدم محمد" - موجود في بيانات الأقارب
❌ "أم المستخدم اسمها فاطمة" - موجود في بيانات الأقارب
❌ "لديه أخ اسمه أحمد" - موجود في بيانات الأقارب

## أمثلة على ما يجب استخراجه:
✅ "يفضل التواصل صباحاً" - تفضيل شخصي جديد
✅ "يشعر بالذنب لعدم زيارة جدته" - مشاعر مهمة
✅ "ذكرى زواج والديه في شهر رجب" - تاريخ جديد غير موجود
✅ "يجد صعوبة في التحدث عن مشاعره" - سمة شخصية

## قواعد صارمة:
- لا تستخرج ما قاله الذكاء الاصطناعي، فقط ما قاله المستخدم
- لا تكرر معلومات واضحة أو عامة
- الأهمية من 1 (منخفضة) إلى 10 (عالية جداً)
- إذا لم تجد شيئاً جديداً ومفيداً، أعد: {"memories": []}

أعد JSON فقط، بدون شرح.
''';

  /// Dynamic memory extraction prompt using active categories from admin
  /// IMPORTANT: This prompt explicitly tells AI NOT to extract data already in relatives table
  static String get memoryExtractionPrompt {
    final config = AIConfigService.instance;
    if (!config.isLoaded || config.memoryCategories.isEmpty) {
      return _fallbackMemoryExtractionPrompt;
    }

    // Get only active categories that allow auto-extraction
    // IMPORTANT: Exclude 'relative_fact' category - this data is already in relatives table
    final activeCategories = config.memoryCategories
        .where((c) => c.autoExtract && c.categoryKey != 'relative_fact')
        .toList();

    if (activeCategories.isEmpty) {
      return _fallbackMemoryExtractionPrompt;
    }

    // Get dynamic extraction rules from admin config
    final memoryConfig = config.memoryConfig;

    final categoriesText = activeCategories
        .map((c) => '- ${c.categoryKey}: ${c.displayNameAr}')
        .join('\n');

    // Build ignore examples from admin config
    final ignoreExamples = memoryConfig.extractionExamplesIgnore
        .map((e) => '❌ "$e"')
        .join('\n');

    // Build extract examples from admin config
    final extractExamples = memoryConfig.extractionExamplesExtract
        .map((e) => '✅ "$e"')
        .join('\n');

    return '''
حلل هذه المحادثة واستخرج معلومات جديدة ومفيدة فقط.

${memoryConfig.extractionInstructionsAr}

✅ استخرج فقط في الفئات المتاحة:
$categoriesText

أعد JSON فقط بهذا الشكل:
{
  "memories": [
    {
      "category": "category_key",
      "content": "المعلومة بالعربية",
      "importance": 7
    }
  ]
}

## أمثلة على ما يجب تجاهله:
$ignoreExamples

## أمثلة على ما يجب استخراجه:
$extractExamples

## قواعد صارمة:
- لا تستخرج ما قاله الذكاء الاصطناعي، فقط ما قاله المستخدم
- لا تكرر معلومات واضحة أو عامة
- الأهمية من 1 (منخفضة) إلى 10 (عالية جداً)
- إذا لم تجد شيئاً جديداً ومفيداً، أعد: {"memories": []}

أعد JSON فقط، بدون شرح.
''';
  }

  /// Get list of active category keys for validation
  /// NOTE: 'relative_fact' is excluded because this data is already in the relatives table
  static Set<String> get activeMemoryCategoryKeys {
    final config = AIConfigService.instance;
    if (!config.isLoaded || config.memoryCategories.isEmpty) {
      // Fallback active categories - NO relative_fact (data exists in relatives table)
      return {'user_preference', 'important_date', 'conversation_insight'};
    }
    // Exclude relative_fact - this data is already in the relatives table
    return config.memoryCategories
        .where((c) => c.autoExtract && c.categoryKey != 'relative_fact')
        .map((c) => c.categoryKey)
        .toSet();
  }

  /// System prompt for gift recommendations
  /// AI generates real product recommendations from Saudi retailers
  static String giftRecommendationPrompt({
    required Relative relative,
    String? occasion,
    String? budget,
  }) {
    return '''
أنت خبير هدايا في السعودية. اقترح منتجات حقيقية متوفرة للشراء الآن.

## معلومات المستلم:
- الاسم: ${relative.fullName}
- العلاقة: ${relative.relationshipType.arabicName}
${relative.interests != null && relative.interests!.isNotEmpty ? '- الاهتمامات: ${relative.interests!.join("، ")}' : ''}
${relative.favoriteColors != null && relative.favoriteColors!.isNotEmpty ? '- الألوان المفضلة: ${relative.favoriteColors!.join("، ")}' : ''}
${relative.dislikedGifts != null && relative.dislikedGifts!.isNotEmpty ? '- هدايا يجب تجنبها: ${relative.dislikedGifts!.join("، ")}' : ''}
${relative.wishlist != null && relative.wishlist!.isNotEmpty ? '- قائمة الأمنيات: ${relative.wishlist!.join("، ")}' : ''}
${occasion != null ? '\n## المناسبة: $occasion' : ''}
${budget != null ? '## الميزانية: $budget' : ''}

## المتاجر المتاحة:
- Amazon.sa (أمازون)
- Noon (نون)
- Jarir (جرير)

## مهمتك:
اقترح 4-5 منتجات حقيقية محددة (ليس فئات عامة) من هذه المتاجر.

## الناتج المطلوب (JSON فقط):
{
  "recommendations": [
    {
      "name": "اسم المنتج المحدد بالعربي",
      "brand": "الماركة",
      "price": 299,
      "retailer": "Amazon.sa",
      "url": "رابط المنتج الفعلي من المتجر",
      "reason": "سبب اختيار هذه الهدية"
    }
  ]
}

## قواعد صارمة:
- اقترح منتجات محددة وليس فئات (مثال: "ساعة Apple Watch SE" وليس "ساعة ذكية")
- السعر بالريال السعودي (رقم فقط بدون "ر.س")
- الرابط يجب أن يكون حقيقي من المتجر
- المتاجر المسموحة: Amazon.sa, Noon, Jarir
- أعد JSON فقط بدون أي نص إضافي
''';
  }

  /// System prompt for message generation
  /// Uses dynamic personality from admin config
  static String messageGenerationPrompt(
    Relative relative,
    String occasionType,
    String tone, {
    String? occasionPromptAddition,
    String? tonePromptModifier,
  }) {
    // Use dynamic personality from admin config (includes dialect/style)
    final personality = dynamicPersonality;

    return '''
أنت كاتب رسائل محترف متخصص في الرسائل العائلية الدافئة والمؤثرة.

$personality

## معلومات المستلم:
- الاسم: ${relative.fullName}
- العلاقة: ${relative.relationshipType.arabicName}
${relative.personalityType != null ? '- نوع الشخصية: ${relative.personalityType}' : ''}
${relative.communicationStyle != null ? '- أسلوب التواصل المفضل: ${relative.communicationStyle}' : ''}
${relative.interests != null && relative.interests!.isNotEmpty ? '- الاهتمامات: ${relative.interests!.join("، ")}' : ''}
${relative.relationshipStrengths != null ? '- نقاط قوة العلاقة: ${relative.relationshipStrengths}' : ''}

## نوع المناسبة: $occasionType
${occasionPromptAddition != null ? '## تعليمات خاصة بالمناسبة: $occasionPromptAddition' : ''}

## النبرة المطلوبة: $tone
${tonePromptModifier != null ? '## تعليمات خاصة بالنبرة: $tonePromptModifier' : ''}

## تعليمات الكتابة:
اكتب 3 رسائل مختلفة ومميزة. كل رسالة يجب أن تكون:
- فريدة وغير مكررة (لا تكرر نفس العبارات بين الرسائل)
- دافئة وصادقة وتلمس القلب
- مناسبة لنوع العلاقة والشخصية
- تعكس القيم الإسلامية بشكل طبيعي غير متكلف
- قصيرة ومركزة (50-80 كلمة)
- تحتوي على لمسة شخصية إن أمكن

## تنويع الأساليب:
- الرسالة الأولى: مباشرة ودافئة
- الرسالة الثانية: تبدأ بدعاء أو حكمة
- الرسالة الثالثة: شاعرية أو عاطفية

قدّم الإجابة بتنسيق JSON فقط:
{
  "messages": ["رسالة 1", "رسالة 2", "رسالة 3"]
}
''';
  }

  /// System prompt for communication scripts
  /// Uses dynamic personality from admin config
  static String communicationScriptPrompt(String scenario, Relative? relative, String? context) {
    // Use dynamic personality from admin config (includes dialect/style)
    final personality = dynamicPersonality;

    return '''
أنت مستشار تواصل عائلي خبير متخصص في المحادثات الصعبة والحساسة.

$personality

## السيناريو: $scenario
${relative != null ? '''
## معلومات القريب:
- الاسم: ${relative.fullName}
- العلاقة: ${relative.relationshipType.arabicName}
${relative.personalityType != null ? '- نوع الشخصية: ${relative.personalityType} (تعامل معه حسب شخصيته)' : ''}
${relative.communicationStyle != null ? '- أسلوب التواصل المفضل: ${relative.communicationStyle}' : ''}
${relative.sensitiveTopics != null && relative.sensitiveTopics!.isNotEmpty ? '- ⚠️ مواضيع حساسة يجب تجنبها تماماً: ${relative.sensitiveTopics!.join("، ")}' : ''}
${relative.conflictHistory != null ? '- تاريخ الخلافات السابقة: ${relative.conflictHistory}' : ''}
${relative.relationshipChallenges != null ? '- تحديات العلاقة الحالية: ${relative.relationshipChallenges}' : ''}
${relative.relationshipStrengths != null ? '- نقاط قوة يمكن البناء عليها: ${relative.relationshipStrengths}' : ''}
''' : ''}
${context != null ? '## سياق إضافي: $context' : ''}

## مهمتك:
قدّم سيناريو محادثة عملي ومفصل يساعد المستخدم في هذا الموقف الصعب.

## المطلوب:
1. **جملة افتتاحية**: تكسر الجليد وتفتح باب الحوار بلطف
2. **النقاط الرئيسية**: 3-4 نقاط مهمة للمناقشة بالترتيب
3. **عبارات مفيدة**: 4-5 عبارات يمكن استخدامها أثناء المحادثة
4. **عبارات يجب تجنبها**: 3-4 عبارات قد تفسد المحادثة
5. **جملة ختامية**: تنهي المحادثة بإيجابية وتفتح المجال للمستقبل

## تعليمات مهمة:
- العبارات يجب أن تكون طبيعية وليست رسمية جداً
- تجنب اللوم والنقد المباشر
- ركز على المشاعر بدلاً من الأخطاء
- استخدم "أنا أشعر" بدلاً من "أنت فعلت"
- اقترح حلولاً وليس فقط شكاوى

قدّم الإجابة بتنسيق JSON فقط:
{
  "opening": "جملة الافتتاح",
  "key_points": ["نقطة 1", "نقطة 2", "نقطة 3"],
  "phrases_to_use": ["عبارة 1", "عبارة 2", "عبارة 3", "عبارة 4"],
  "phrases_to_avoid": ["عبارة 1", "عبارة 2", "عبارة 3"],
  "closing": "جملة الختام"
}
''';
  }

  /// System prompt for weekly report reflection
  static const String weeklyReportPrompt = '''
أنت محلل علاقات عائلية. بناءً على البيانات المقدمة، اكتب تأملاً قصيراً (2-3 جمل)
يشجع المستخدم على صلة الرحم ويقدم نصيحة عملية واحدة للأسبوع القادم.

يجب أن يكون التأمل:
- إيجابياً ومشجعاً
- عملياً وقابلاً للتطبيق
- يعكس قيم صلة الرحم
''';

  /// System prompt for relationship health analysis
  /// Uses dynamic personality from admin config
  static String relationshipAnalysisPrompt(Relative relative) {
    final days = relative.daysSinceLastContact ?? 0;
    final healthScore = relative.healthScore ?? 50;
    final healthStatus = relative.healthStatus2;

    // Use dynamic personality from admin config (includes dialect/style)
    final personality = dynamicPersonality;

    return '''
أنت محلل علاقات عائلية خبير ومستشار في صلة الرحم.

$personality

## معلومات القريب المطلوب تحليل علاقته:
- الاسم: ${relative.fullName}
- العلاقة: ${relative.relationshipType.arabicName}
- الأولوية: ${_getPriorityArabic(relative.priority)}
- آخر تواصل: منذ $days يوم
- درجة صحة العلاقة الحالية: $healthScore%
- الحالة: ${healthStatus.value}
${relative.personalityType != null ? '- نوع الشخصية: ${relative.personalityType}' : ''}
${relative.communicationStyle != null ? '- أسلوب التواصل المفضل: ${relative.communicationStyle}' : ''}
${relative.interests != null && relative.interests!.isNotEmpty ? '- الاهتمامات: ${relative.interests!.join("، ")}' : ''}
${relative.relationshipStrengths != null ? '- نقاط قوة العلاقة: ${relative.relationshipStrengths}' : ''}
${relative.relationshipChallenges != null ? '- تحديات العلاقة: ${relative.relationshipChallenges}' : ''}
${relative.conflictHistory != null ? '- تاريخ الخلافات: ${relative.conflictHistory}' : ''}
${relative.sensitiveTopics != null && relative.sensitiveTopics!.isNotEmpty ? '- مواضيع حساسة: ${relative.sensitiveTopics!.join("، ")}' : ''}

## مهمتك:
قم بتحليل شامل لهذه العلاقة وقدّم:
1. تقييم عام للعلاقة (سطر واحد)
2. 3-4 ملاحظات ذكية عن الوضع الحالي
3. 3-4 اقتراحات عملية قابلة للتنفيذ فوراً
4. تنبيهات مهمة (إن وجدت)

## قواعد التحليل:
- كن صادقاً ولكن بنّاءً
- ركز على الحلول وليس المشاكل فقط
- قدم نصائح محددة وليست عامة
- راعِ نوع الشخصية في اقتراحاتك
- لا تكرر المعلومات المعطاة، قدم رؤى جديدة

قدّم الإجابة بتنسيق JSON فقط:
{
  "summary": "تقييم عام للعلاقة في سطر واحد",
  "insights": [
    {"icon": "💡", "title": "عنوان الملاحظة", "description": "شرح مختصر"},
    {"icon": "📊", "title": "عنوان الملاحظة", "description": "شرح مختصر"}
  ],
  "suggestions": [
    {"icon": "📞", "title": "اتصل اليوم", "description": "شرح مختصر للاقتراح", "priority": "high"},
    {"icon": "🎁", "title": "أرسل هدية بسيطة", "description": "شرح مختصر", "priority": "medium"}
  ],
  "alerts": [
    {"icon": "⚠️", "message": "تنبيه مهم إن وجد"}
  ]
}
''';
  }

  /// System prompt for smart reminder suggestions
  /// Uses dynamic personality from admin config
  static String smartReminderPrompt(List<Relative> relatives) {
    // Use dynamic personality from admin config (includes dialect/style)
    final personality = dynamicPersonality;

    final buffer = StringBuffer();
    buffer.writeln('''
أنت مستشار صلة رحم ذكي. بناءً على قائمة الأقارب التالية، اقترح أولويات التواصل.

$personality

## الأقارب:
''');

    for (final relative in relatives) {
      final days = relative.daysSinceLastContact ?? 0;
      final healthStatus = relative.healthStatus2;
      buffer.writeln('- ${relative.fullName} (${relative.relationshipType.arabicName}) - آخر تواصل: $days يوم - الحالة: ${healthStatus.value}');
    }

    buffer.writeln('''

## مهمتك:
اقترح 3-5 تذكيرات ذكية مرتبة حسب الأولوية.

## قواعد الاقتراح:
- الأولوية للوالدين ثم الإخوة ثم بقية الأقارب
- كلما زادت مدة الانقطاع، زادت الأولوية
- راعِ المناسبات القادمة إن وجدت
- قدم سبباً مقنعاً لكل اقتراح
- اقترح وقتاً مناسباً للتواصل

قدّم الإجابة بتنسيق JSON فقط:
{
  "suggestions": [
    {
      "relative_name": "اسم القريب",
      "reason": "السبب باختصار",
      "urgency": "high/medium/low",
      "suggested_action": "اتصال/رسالة/زيارة",
      "suggested_message": "رسالة مقترحة قصيرة"
    }
  ]
}
''');

    return buffer.toString();
  }
}
