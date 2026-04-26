// Regression test for the silent-drop bug in send-scheduled-reminders.
//
// The Deno/TypeScript edge function can't be exercised by the Flutter test
// runner directly (different runtime). This test enforces the invariant at
// the source level: the last_sent UPDATE must be guarded by a successful-
// delivery flag whose true-branch only fires on responseData.sent > 0.
// A future edit that strips the guard fails this test.
//
// Original bug (caught in DISCOVERY_AUDIT.md, fixed in Phase 4 Task 1):
// last_sent was updated regardless of whether send-push-notification
// succeeded. Any FCM failure (HTTP error, 0 tokens, network exception)
// would silently mark the reminder as delivered.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'send-scheduled-reminders: last_sent UPDATE is guarded by a '
    'sent>0 success check',
    () {
      final source = File(
        'supabase/functions/send-scheduled-reminders/index.ts',
      ).readAsStringSync();

      // 1. The success flag must be declared.
      expect(source, contains('let sentSuccessfully = false'),
          reason:
              'A boolean must gate last_sent; rewrites must keep this name '
              'or update this test in the same commit.');

      // 2. The flag must only flip true when responseData.sent > 0.
      final flagSet =
          RegExp(r'sentSuccessfully\s*=\s*true').firstMatch(source);
      expect(flagSet, isNotNull);
      final preFlag = source.substring(
        (flagSet!.start - 200).clamp(0, source.length),
        flagSet.start,
      );
      expect(preFlag, contains('sent > 0'),
          reason:
              'sentSuccessfully must only flip on confirmed delivery (≥1 '
              'device acknowledged), not on HTTP 200 with sent=0.');

      // 3. The last_sent UPDATE must be inside an if (sentSuccessfully) block.
      final updateIdx =
          source.indexOf('last_sent: new Date().toISOString()');
      expect(updateIdx, greaterThan(-1),
          reason: 'last_sent UPDATE statement not found.');
      final preUpdate = source.substring(
        (updateIdx - 300).clamp(0, source.length),
        updateIdx,
      );
      expect(preUpdate, contains('if (sentSuccessfully)'),
          reason:
              'last_sent UPDATE must be inside an if (sentSuccessfully) '
              'block; otherwise FCM failures silently mark the reminder as '
              'delivered.');
    },
  );
}
