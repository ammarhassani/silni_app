import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';

/// Represents a single step in the premium onboarding carousel
class OnboardingStep {
  /// Unique identifier for this step
  final String id;

  /// Arabic title displayed prominently
  final String titleArabic;

  /// Arabic description text
  final String descriptionArabic;

  /// Icon to display
  final IconData icon;

  /// Gradient for the icon background
  final Gradient gradient;

  /// Feature ID that maps to FeatureIds for gating
  final String featureId;

  /// Route path for "Try it now" navigation
  final String routePath;

  /// Bullet points highlighting key benefits
  final List<String> bulletPoints;

  /// Whether this is a primary feature (AI features)
  final bool isPrimary;

  /// Optional Lottie animation asset path
  final String? lottieAsset;

  const OnboardingStep({
    required this.id,
    required this.titleArabic,
    required this.descriptionArabic,
    required this.icon,
    required this.gradient,
    required this.featureId,
    required this.routePath,
    this.bulletPoints = const [],
    this.isPrimary = false,
    this.lottieAsset,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingStep && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Predefined onboarding steps for AI features (prioritized first)
class OnboardingSteps {
  OnboardingSteps._();

  /// AI Features - shown first in onboarding
  static const List<OnboardingStep> aiFeatures = [
    // 1. AI Counselor
    OnboardingStep(
      id: 'ai_counselor',
      titleArabic: 'المستشار الذكي',
      descriptionArabic: 'مستشارك الشخصي لصلة الرحم\nنصائح مخصصة لكل علاقة',
      icon: Icons.psychology_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF2D7A3E), Color(0xFF4CAF50)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      featureId: 'ai_chat',
      routePath: AppRoutes.aiChat,
      bulletPoints: [
        'نصائح مخصصة لكل قريب',
        'حلول للمواقف الصعبة',
        'إرشادات إسلامية',
      ],
      isPrimary: true,
    ),

    // 2. Message Composer
    OnboardingStep(
      id: 'message_composer',
      titleArabic: 'كاتب الرسائل',
      descriptionArabic: 'رسائل جميلة بضغطة زر\nللمناسبات والتهاني',
      icon: Icons.edit_note_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      featureId: 'message_composer',
      routePath: AppRoutes.aiMessages,
      bulletPoints: [
        'رسائل للأعياد والمناسبات',
        'تهاني مخصصة لكل قريب',
        'صياغة راقية ومؤثرة',
      ],
      isPrimary: true,
    ),

    // 3. Communication Scripts
    OnboardingStep(
      id: 'communication_scripts',
      titleArabic: 'سيناريوهات التواصل',
      descriptionArabic: 'كيف تبدأ المحادثة؟\nسيناريوهات جاهزة لكل موقف',
      icon: Icons.record_voice_over_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF6A5ACD), Color(0xFF9370DB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      featureId: 'communication_scripts',
      routePath: AppRoutes.aiScripts,
      bulletPoints: [
        'بداية محادثات سلسة',
        'التعامل مع المواقف الحرجة',
        'إصلاح العلاقات المتوترة',
      ],
      isPrimary: true,
    ),

    // 4. Relationship Analysis
    OnboardingStep(
      id: 'relationship_analysis',
      titleArabic: 'تحليل العلاقات',
      descriptionArabic: 'اكتشف صحة علاقاتك\nوكيف تحسّنها',
      icon: Icons.insights_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF00BCD4), Color(0xFF4DD0E1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      featureId: 'relationship_analysis',
      routePath: AppRoutes.aiAnalysis,
      bulletPoints: [
        'تحليل شامل لعلاقاتك',
        'توصيات للتحسين',
        'متابعة التقدم',
      ],
      isPrimary: true,
    ),
  ];

  /// Other premium features (shown after AI features)
  static const List<OnboardingStep> otherFeatures = [
    // 5. Smart Reminders
    OnboardingStep(
      id: 'smart_reminders_ai',
      titleArabic: 'التذكيرات الذكية',
      descriptionArabic: 'تذكيرات مخصصة بالذكاء الاصطناعي\nفي الوقت المناسب',
      icon: Icons.notifications_active_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFFFD60A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      featureId: 'smart_reminders_ai',
      routePath: AppRoutes.reminders,
      bulletPoints: [
        'تذكيرات غير محدودة',
        'توقيت ذكي لكل قريب',
        'اقتراحات مخصصة',
      ],
      isPrimary: false,
    ),

    // 6. Weekly Reports
    OnboardingStep(
      id: 'weekly_reports',
      titleArabic: 'التقارير الأسبوعية',
      descriptionArabic: 'ملخص أسبوعي لتواصلك\nمع عائلتك',
      icon: Icons.assessment_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF7B68EE), Color(0xFFBA55D3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      featureId: 'weekly_reports',
      routePath: AppRoutes.aiReport,
      bulletPoints: [
        'ملخص تواصلك الأسبوعي',
        'إحصائيات مفصلة',
        'توصيات للأسبوع القادم',
      ],
      isPrimary: false,
    ),
  ];

  /// All onboarding steps in order (AI features first)
  static List<OnboardingStep> get allSteps => [
        ...aiFeatures,
        ...otherFeatures,
      ];

  /// Get step by ID
  static OnboardingStep? getById(String id) {
    try {
      return allSteps.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get step index by ID
  static int getIndexById(String id) {
    return allSteps.indexWhere((s) => s.id == id);
  }

  /// Total number of steps
  static int get totalSteps => allSteps.length;
}
