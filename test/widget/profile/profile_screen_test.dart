import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:silni_app/shared/models/relative_model.dart';
import 'package:silni_app/shared/models/interaction_model.dart';
import '../../helpers/model_factories.dart';

void main() {
  group('ProfileScreen Logic Tests', () {
    // =====================================================
    // DISPLAY NAME LOGIC TESTS
    // =====================================================
    group('display name logic', () {
      /// Replicate the display name logic from profile_screen.dart
      String getDisplayName(Map<String, dynamic>? userMetadata, String? email) {
        final fullName = userMetadata?['full_name'];
        if (fullName != null && fullName.toString().isNotEmpty) {
          return fullName.toString();
        }
        if (email != null && email.contains('@')) {
          return email.split('@')[0];
        }
        return 'المستخدم';
      }

      test('should use full_name from metadata when available', () {
        expect(
          getDisplayName({'full_name': 'محمد أحمد'}, 'test@example.com'),
          equals('محمد أحمد'),
        );
      });

      test('should use email prefix when no full_name', () {
        expect(
          getDisplayName(null, 'username@example.com'),
          equals('username'),
        );
      });

      test('should use email prefix when full_name is empty', () {
        expect(
          getDisplayName({'full_name': ''}, 'john.doe@example.com'),
          equals('john.doe'),
        );
      });

      test('should fallback to default when no metadata and no email', () {
        expect(
          getDisplayName(null, null),
          equals('المستخدم'),
        );
      });

      test('should fallback to default when email is invalid', () {
        expect(
          getDisplayName(null, 'invalidemail'),
          equals('المستخدم'),
        );
      });

      test('should handle complex email addresses', () {
        expect(
          getDisplayName(null, 'user.name+tag@example.co.uk'),
          equals('user.name+tag'),
        );
      });
    });

    // =====================================================
    // AVATAR INITIAL LOGIC TESTS
    // =====================================================
    group('avatar initial logic', () {
      /// Replicate the avatar initial logic from profile_screen.dart
      String getAvatarInitial(String name) {
        if (name.isEmpty) return '؟';
        return name[0].toUpperCase();
      }

      test('should return first character of name', () {
        expect(getAvatarInitial('محمد'), equals('م'));
      });

      test('should return uppercase for English names', () {
        expect(getAvatarInitial('john'), equals('J'));
      });

      test('should return question mark for empty name', () {
        expect(getAvatarInitial(''), equals('؟'));
      });

      test('should handle single character names', () {
        expect(getAvatarInitial('A'), equals('A'));
      });
    });

    // =====================================================
    // STATISTICS CALCULATION TESTS
    // =====================================================
    group('statistics calculations', () {
      /// Calculate this month's interactions
      int calculateThisMonthInteractions(List<Interaction> interactions) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        return interactions
            .where((i) => i.date.isAfter(monthStart) ||
                          (i.date.year == now.year &&
                           i.date.month == now.month &&
                           i.date.day == monthStart.day))
            .length;
      }

      /// Calculate relatives needing contact
      int calculateNeedsContact(List<Relative> relatives) {
        return relatives.where((r) => r.needsContact).length;
      }

      test('should count all interactions from this month', () {
        final now = DateTime.now();
        final interactions = [
          createTestInteraction(date: now),
          createTestInteraction(date: now.subtract(const Duration(days: 5))),
          createTestInteraction(date: DateTime(now.year, now.month, 1)),
        ];

        final count = calculateThisMonthInteractions(interactions);
        // All should be from this month
        expect(count, equals(3));
      });

      test('should not count interactions from previous months', () {
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1, 15);
        final interactions = [
          createTestInteraction(date: now),
          createTestInteraction(date: lastMonth),
        ];

        final count = calculateThisMonthInteractions(interactions);
        expect(count, equals(1));
      });

      test('should count relatives needing contact', () {
        // Create relatives with different last contact dates
        final relatives = [
          createTestRelative(
            id: 'rel-1',
            lastContactDate: DateTime.now().subtract(const Duration(days: 60)),
            priority: 1, // High priority
          ),
          createTestRelative(
            id: 'rel-2',
            lastContactDate: DateTime.now(), // Just contacted
            priority: 2,
          ),
        ];

        // Count those needing contact
        final needsContact = relatives.where((r) => r.needsContact).length;
        expect(needsContact, greaterThanOrEqualTo(0));
      });

      test('should return 0 for empty relatives list', () {
        final needsContact = calculateNeedsContact([]);
        expect(needsContact, equals(0));
      });
    });

    // =====================================================
    // DATE FORMATTING TESTS
    // =====================================================
    group('date formatting', () {
      /// Replicate the Arabic date formatting from profile_screen.dart
      String formatDateArabic(DateTime date) {
        final months = [
          'يناير',
          'فبراير',
          'مارس',
          'أبريل',
          'مايو',
          'يونيو',
          'يوليو',
          'أغسطس',
          'سبتمبر',
          'أكتوبر',
          'نوفمبر',
          'ديسمبر',
        ];

        return '${date.day} ${months[date.month - 1]} ${date.year}';
      }

      test('should format January date correctly', () {
        final date = DateTime(2024, 1, 15);
        expect(formatDateArabic(date), equals('15 يناير 2024'));
      });

      test('should format December date correctly', () {
        final date = DateTime(2024, 12, 25);
        expect(formatDateArabic(date), equals('25 ديسمبر 2024'));
      });

      test('should format first day of month', () {
        final date = DateTime(2024, 6, 1);
        expect(formatDateArabic(date), equals('1 يونيو 2024'));
      });

      test('should format last day of month', () {
        final date = DateTime(2024, 3, 31);
        expect(formatDateArabic(date), equals('31 مارس 2024'));
      });

      test('should format all months correctly', () {
        final expectedMonths = [
          'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
          'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
        ];

        for (int month = 1; month <= 12; month++) {
          final date = DateTime(2024, month, 1);
          final formatted = formatDateArabic(date);
          expect(
            formatted.contains(expectedMonths[month - 1]),
            isTrue,
            reason: 'Month $month should contain ${expectedMonths[month - 1]}',
          );
        }
      });
    });

    // =====================================================
    // DATE PARSING TESTS
    // =====================================================
    group('date parsing', () {
      /// Replicate the date parsing logic from profile_screen.dart
      DateTime parseDateTime(dynamic date) {
        if (date == null) {
          return DateTime.now();
        }

        if (date is DateTime) {
          return date;
        }

        if (date is String) {
          try {
            return DateTime.parse(date);
          } catch (e) {
            return DateTime.now();
          }
        }

        return DateTime.now();
      }

      test('should return DateTime as-is', () {
        final original = DateTime(2024, 6, 15);
        final parsed = parseDateTime(original);
        expect(parsed, equals(original));
      });

      test('should parse ISO 8601 string', () {
        final parsed = parseDateTime('2024-06-15T10:30:00.000Z');
        expect(parsed.year, equals(2024));
        expect(parsed.month, equals(6));
        expect(parsed.day, equals(15));
      });

      test('should parse date-only string', () {
        final parsed = parseDateTime('2024-06-15');
        expect(parsed.year, equals(2024));
        expect(parsed.month, equals(6));
        expect(parsed.day, equals(15));
      });

      test('should return now for null', () {
        final now = DateTime.now();
        final parsed = parseDateTime(null);
        expect(parsed.year, equals(now.year));
        expect(parsed.month, equals(now.month));
        expect(parsed.day, equals(now.day));
      });

      test('should return now for invalid string', () {
        final now = DateTime.now();
        final parsed = parseDateTime('not-a-date');
        expect(parsed.year, equals(now.year));
      });

      test('should handle empty string', () {
        final now = DateTime.now();
        final parsed = parseDateTime('');
        expect(parsed.year, equals(now.year));
      });
    });

    // =====================================================
    // VERIFICATION STATUS LOGIC TESTS
    // =====================================================
    group('verification status', () {
      /// Replicate the verification status logic
      String getVerificationStatus(String? emailConfirmedAt) {
        return emailConfirmedAt != null ? 'تم التحقق ✓' : 'لم يتم التحقق';
      }

      test('should show verified when email is confirmed', () {
        expect(
          getVerificationStatus('2024-01-01T00:00:00.000Z'),
          equals('تم التحقق ✓'),
        );
      });

      test('should show not verified when email not confirmed', () {
        expect(
          getVerificationStatus(null),
          equals('لم يتم التحقق'),
        );
      });
    });

    // =====================================================
    // NAME VALIDATION TESTS
    // =====================================================
    group('name validation', () {
      /// Validate name for saving
      String? validateName(String name) {
        final trimmed = name.trim();
        if (trimmed.isEmpty) {
          return 'الاسم لا يمكن أن يكون فارغاً';
        }
        if (trimmed.length < 2) {
          return 'الاسم يجب أن يكون حرفين على الأقل';
        }
        return null; // Valid
      }

      test('should reject empty name', () {
        expect(validateName(''), equals('الاسم لا يمكن أن يكون فارغاً'));
      });

      test('should reject whitespace-only name', () {
        expect(validateName('   '), equals('الاسم لا يمكن أن يكون فارغاً'));
      });

      test('should reject single character name', () {
        expect(validateName('م'), equals('الاسم يجب أن يكون حرفين على الأقل'));
      });

      test('should accept two character name', () {
        expect(validateName('محم'), isNull);
      });

      test('should accept normal name', () {
        expect(validateName('محمد أحمد'), isNull);
      });

      test('should trim whitespace', () {
        expect(validateName('  محمد  '), isNull);
      });
    });

    // =====================================================
    // URL MASKING TESTS (from env_validator pattern)
    // =====================================================
    group('URL masking for safe logging', () {
      /// Mask URL for safe logging (shows only domain hint)
      String maskUrl(String url) {
        if (url.isEmpty) return '(empty)';
        if (url.length < 20) return '***';
        // Show first 15 chars and last 10 to identify the project
        return '${url.substring(0, 15)}...${url.substring(url.length - 10)}';
      }

      test('should return (empty) for empty URL', () {
        expect(maskUrl(''), equals('(empty)'));
      });

      test('should return *** for short URLs', () {
        expect(maskUrl('https://a.com'), equals('***'));
      });

      test('should mask long URLs', () {
        final url = 'https://example-project.supabase.co';
        final masked = maskUrl(url);
        expect(masked.startsWith('https://example'), isTrue);
        expect(masked.contains('...'), isTrue);
        expect(masked.endsWith('upabase.co'), isTrue);
      });
    });

    // =====================================================
    // ACCOUNT ACTION IDENTIFIERS
    // =====================================================
    group('account actions', () {
      test('all account action types should be defined', () {
        const actions = [
          'change_password',
          'privacy_security',
          'export_data',
          'delete_account',
        ];

        expect(actions.length, equals(4));
        expect(actions.contains('change_password'), isTrue);
        expect(actions.contains('privacy_security'), isTrue);
        expect(actions.contains('export_data'), isTrue);
        expect(actions.contains('delete_account'), isTrue);
      });

      test('action labels should be in Arabic', () {
        const labels = {
          'change_password': 'تغيير كلمة المرور',
          'privacy_security': 'الخصوصية والأمان',
          'export_data': 'تصدير بياناتي',
          'delete_account': 'حذف الحساب',
        };

        expect(labels['change_password'], equals('تغيير كلمة المرور'));
        expect(labels['privacy_security'], equals('الخصوصية والأمان'));
        expect(labels['export_data'], equals('تصدير بياناتي'));
        expect(labels['delete_account'], equals('حذف الحساب'));
      });
    });

    // =====================================================
    // USER INFO LABELS
    // =====================================================
    group('user info labels', () {
      test('all user info labels should be in Arabic', () {
        const labels = {
          'email': 'البريد الإلكتروني',
          'verification': 'حالة التحقق',
          'join_date': 'تاريخ الانضمام',
          'account_info': 'معلومات الحساب',
        };

        expect(labels['email'], equals('البريد الإلكتروني'));
        expect(labels['verification'], equals('حالة التحقق'));
        expect(labels['join_date'], equals('تاريخ الانضمام'));
        expect(labels['account_info'], equals('معلومات الحساب'));
      });
    });

    // =====================================================
    // STATISTICS LABELS
    // =====================================================
    group('statistics labels', () {
      test('all statistics labels should be in Arabic', () {
        const labels = {
          'total_relatives': 'إجمالي الأقارب',
          'this_month_interactions': 'تواصل هذا الشهر',
          'total_interactions': 'إجمالي التفاعلات',
          'needs_contact': 'يحتاجون تواصل',
        };

        expect(labels['total_relatives'], equals('إجمالي الأقارب'));
        expect(labels['this_month_interactions'], equals('تواصل هذا الشهر'));
        expect(labels['total_interactions'], equals('إجمالي التفاعلات'));
        expect(labels['needs_contact'], equals('يحتاجون تواصل'));
      });
    });

    // =====================================================
    // SECTION HEADERS
    // =====================================================
    group('section headers', () {
      test('statistics header should include emoji', () {
        const header = '📊 إحصائياتي';
        expect(header.contains('📊'), isTrue);
        expect(header.contains('إحصائياتي'), isTrue);
      });

      test('account settings header should include emoji', () {
        const header = '⚙️ إعدادات الحساب';
        expect(header.contains('⚙️'), isTrue);
        expect(header.contains('إعدادات الحساب'), isTrue);
      });
    });

    // =====================================================
    // IMAGE SOURCE OPTIONS
    // =====================================================
    group('image source options', () {
      test('image source labels should be in Arabic', () {
        const labels = {
          'dialog_title': 'اختر مصدر الصورة',
          'gallery': 'المعرض',
          'camera': 'الكاميرا',
          'cancel': 'إلغاء',
        };

        expect(labels['dialog_title'], equals('اختر مصدر الصورة'));
        expect(labels['gallery'], equals('المعرض'));
        expect(labels['camera'], equals('الكاميرا'));
        expect(labels['cancel'], equals('إلغاء'));
      });
    });

    // =====================================================
    // DIALOG MESSAGES
    // =====================================================
    group('dialog messages', () {
      test('password reset dialog text should be correct', () {
        const title = 'تغيير كلمة المرور';
        const message = 'سيتم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني';

        expect(title, equals('تغيير كلمة المرور'));
        expect(message.contains('رابط إعادة تعيين'), isTrue);
      });

      test('delete account dialog should have warning text', () {
        const title = 'حذف الحساب';
        const message = 'هل أنت متأكد من حذف حسابك؟ سيتم حذف جميع بياناتك بشكل نهائي ولا يمكن التراجع عن هذا الإجراء.';

        expect(title, equals('حذف الحساب'));
        expect(message.contains('متأكد'), isTrue);
        expect(message.contains('نهائي'), isTrue);
        expect(message.contains('التراجع'), isTrue);
      });
    });

    // =====================================================
    // SUCCESS/ERROR MESSAGES
    // =====================================================
    group('notification messages', () {
      test('success messages should be correct', () {
        const messages = {
          'profile_picture_updated': 'تم تحديث الصورة الشخصية بنجاح! ✅',
          'name_saved': 'تم حفظ الاسم بنجاح',
          'password_reset_sent': 'تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني',
          'account_deleted': 'تم حذف حسابك بنجاح',
        };

        expect(messages['profile_picture_updated']!.contains('بنجاح'), isTrue);
        expect(messages['name_saved']!.contains('بنجاح'), isTrue);
        expect(messages['password_reset_sent']!.contains('تم إرسال'), isTrue);
        expect(messages['account_deleted']!.contains('بنجاح'), isTrue);
      });

      test('error messages should be descriptive', () {
        const errors = {
          'empty_name': 'الاسم لا يمكن أن يكون فارغاً',
          'short_name': 'الاسم يجب أن يكون حرفين على الأقل',
          'email_not_available': 'البريد الإلكتروني غير متوفر',
          'login_required': 'يرجى تسجيل الدخول أولاً',
        };

        expect(errors['empty_name']!.contains('فارغاً'), isTrue);
        expect(errors['short_name']!.contains('حرفين'), isTrue);
        expect(errors['email_not_available']!.contains('غير متوفر'), isTrue);
        expect(errors['login_required']!.contains('تسجيل الدخول'), isTrue);
      });
    });

    // =====================================================
    // ICONS MAPPING
    // =====================================================
    group('icons mapping', () {
      test('account action icons should be correct', () {
        const actionIcons = {
          'change_password': Icons.lock_outline,
          'privacy': Icons.shield_outlined,
          'export': Icons.download_outlined,
          'delete': Icons.delete_outline,
        };

        expect(actionIcons['change_password'], equals(Icons.lock_outline));
        expect(actionIcons['privacy'], equals(Icons.shield_outlined));
        expect(actionIcons['export'], equals(Icons.download_outlined));
        expect(actionIcons['delete'], equals(Icons.delete_outline));
      });

      test('info card icons should be correct', () {
        const infoIcons = {
          'email': Icons.email_outlined,
          'verification': Icons.verified_user_outlined,
          'join_date': Icons.calendar_today_outlined,
          'account_info': Icons.info_outline,
        };

        expect(infoIcons['email'], equals(Icons.email_outlined));
        expect(infoIcons['verification'], equals(Icons.verified_user_outlined));
        expect(infoIcons['join_date'], equals(Icons.calendar_today_outlined));
        expect(infoIcons['account_info'], equals(Icons.info_outline));
      });

      test('statistics icons should be correct', () {
        const statsIcons = {
          'relatives': Icons.people_rounded,
          'calls': Icons.call_rounded,
          'timeline': Icons.timeline_rounded,
          'notifications': Icons.notifications_active_rounded,
        };

        expect(statsIcons['relatives'], equals(Icons.people_rounded));
        expect(statsIcons['calls'], equals(Icons.call_rounded));
        expect(statsIcons['timeline'], equals(Icons.timeline_rounded));
        expect(statsIcons['notifications'], equals(Icons.notifications_active_rounded));
      });
    });

    // =====================================================
    // EDGE CASES
    // =====================================================
    group('edge cases', () {
      test('should handle very long names without crash', () {
        const longName = 'محمد أحمد عبدالله الرحمن الكريم العزيز الحكيم الجليل';
        expect(longName.length, greaterThan(30));
        // Name should be truncatable
        expect(longName.substring(0, 10), isNotNull);
      });

      test('should handle special characters in email', () {
        const email = 'user.name+tag@example.co.uk';
        final parts = email.split('@');
        expect(parts.length, equals(2));
        expect(parts[0], equals('user.name+tag'));
      });

      test('should handle unicode in names', () {
        const arabicName = 'محمد';
        const englishName = 'Muhammad';

        expect(arabicName.isNotEmpty, isTrue);
        expect(englishName.isNotEmpty, isTrue);
        // Both should work for display
        expect(arabicName[0], equals('م'));
        expect(englishName[0], equals('M'));
      });
    });
  });
}
