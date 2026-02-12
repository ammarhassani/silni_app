import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:silni_app/core/services/error_handler_service.dart';

/// Unit tests for RPC exception → Arabic message mapping.
///
/// Tests verify that PostgrestExceptions with known RPC error messages
/// are correctly mapped to user-friendly Arabic messages.
void main() {
  late ErrorHandlerService errorHandler;

  setUp(() {
    errorHandler = ErrorHandlerService();
  });

  /// Helper: create a PostgrestException with a PGRST error code
  /// and the given message, then get the Arabic message from the handler.
  String getArabic(String rpcMessage) {
    final error = PostgrestException(
      message: rpcMessage,
      code: 'P0001', // PostgreSQL RAISE EXCEPTION code
    );
    return errorHandler.getArabicMessage(error);
  }

  group('RPC exception Arabic messages', () {
    // -----------------------------------------------------------------------
    // Group operations
    // -----------------------------------------------------------------------
    test('create group for another user', () {
      expect(
        getArabic('Cannot create group for another user'),
        'لا يمكن إنشاء مجموعة لمستخدم آخر',
      );
    });

    test('group name cannot be empty', () {
      expect(
        getArabic('Group name cannot be empty'),
        'اسم المجموعة لا يمكن أن يكون فارغًا',
      );
    });

    test('group name too long', () {
      expect(
        getArabic('Group name too long (max 100 characters)'),
        'اسم المجموعة طويل جدًا',
      );
    });

    // -----------------------------------------------------------------------
    // Admin operations
    // -----------------------------------------------------------------------
    test('transfer admin for another user', () {
      expect(
        getArabic('Cannot transfer admin for another user'),
        'لا يمكن نقل الإدارة لمستخدم آخر',
      );
    });

    test('only admins can transfer', () {
      expect(
        getArabic('Only admins can transfer admin role'),
        'فقط المسؤولون يمكنهم نقل الإدارة',
      );
    });

    test('only admins can remove members', () {
      expect(
        getArabic('Only admins can remove members'),
        'فقط المسؤولون يمكنهم إزالة الأعضاء',
      );
    });

    test('cannot remove another admin', () {
      expect(
        getArabic('Cannot remove another admin from the group'),
        'لا يمكن إزالة مسؤول آخر',
      );
    });

    test('cannot remove last admin', () {
      expect(
        getArabic('Cannot remove last admin from group while other members exist'),
        'لا يمكن إزالة المسؤول الأخير من المجموعة',
      );
    });

    test('cannot demote last admin', () {
      expect(
        getArabic('Cannot demote last admin'),
        'لا يمكن إزالة المسؤول الأخير من المجموعة',
      );
    });

    // -----------------------------------------------------------------------
    // Leave operations
    // -----------------------------------------------------------------------
    test('leave group for another user', () {
      expect(
        getArabic('Cannot leave group for another user'),
        'لا يمكن مغادرة المجموعة نيابة عن مستخدم آخر',
      );
    });

    // -----------------------------------------------------------------------
    // Membership
    // -----------------------------------------------------------------------
    test('caller not a member', () {
      expect(
        getArabic('Caller is not a member of this group'),
        'لست عضوًا في هذه المجموعة',
      );
    });

    test('target member not found', () {
      expect(
        getArabic('Target member not found in this group'),
        'العضو المطلوب غير موجود في المجموعة',
      );
    });

    test('use leave_group to remove yourself', () {
      expect(
        getArabic('Use leave_group to remove yourself'),
        'استخدم خيار المغادرة لإزالة نفسك',
      );
    });

    // -----------------------------------------------------------------------
    // Validation
    // -----------------------------------------------------------------------
    test('relative_id_in_tree validation', () {
      expect(
        getArabic('relative_id_in_tree must reference a relative in the same group'),
        'العضو المختار غير موجود في شجرة هذه المجموعة',
      );
    });

    // -----------------------------------------------------------------------
    // Unknown messages fall back to generic
    // -----------------------------------------------------------------------
    test('unknown RPC message falls back to generic database error', () {
      expect(
        getArabic('some unknown error from postgres'),
        'خطأ في قاعدة البيانات',
      );
    });

    // -----------------------------------------------------------------------
    // Non-PGRST codes still work with standard mappings
    // -----------------------------------------------------------------------
    test('unique constraint violation gives Arabic message', () {
      final error = PostgrestException(
        message: 'duplicate key violates unique constraint',
        code: '23505',
      );
      expect(
        errorHandler.getArabicMessage(error),
        'هذا العنصر موجود بالفعل',
      );
    });

    test('foreign key violation gives Arabic message', () {
      final error = PostgrestException(
        message: 'violates foreign key constraint',
        code: '23503',
      );
      expect(
        errorHandler.getArabicMessage(error),
        'لا يمكن حذف هذا العنصر لوجود بيانات مرتبطة به',
      );
    });

    test('insufficient privilege gives Arabic message', () {
      final error = PostgrestException(
        message: 'permission denied',
        code: '42501',
      );
      expect(
        errorHandler.getArabicMessage(error),
        'ليس لديك صلاحية للقيام بهذه العملية',
      );
    });
  });
}
