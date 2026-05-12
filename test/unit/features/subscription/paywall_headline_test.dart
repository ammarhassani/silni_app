import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/subscription/screens/paywall_headline.dart';

void main() {
  group('selectPaywallHeadline', () {
    test('contextHeadline wins over every other input', () {
      expect(
        selectPaywallHeadline(
          contextHeadline: 'احصل على مساعد ذكي لعلاقاتك',
          isFromOnboarding: true,
          isPostTrial: true,
        ),
        'احصل على مساعد ذكي لعلاقاتك',
      );
    });

    test('isFromOnboarding suppresses loss-framed copy for brand-new users', () {
      // Defect 1 regression: a new user finishing the wizard should never
      // see "ميزات كنت تستخدمها" — they haven't used anything yet.
      expect(
        selectPaywallHeadline(
          contextHeadline: null,
          isFromOnboarding: true,
          isPostTrial: true,
        ),
        'الاشتراك المميز',
      );
    });

    test('post-trial returning user (not onboarding) sees loss-framed copy', () {
      expect(
        selectPaywallHeadline(
          contextHeadline: null,
          isFromOnboarding: false,
          isPostTrial: true,
        ),
        'ميزات كنت تستخدمها',
      );
    });

    test('trial-eligible user (not post-trial) sees the premium headline', () {
      expect(
        selectPaywallHeadline(
          contextHeadline: null,
          isFromOnboarding: false,
          isPostTrial: false,
        ),
        'الاشتراك المميز',
      );
    });

    test('onboarding flag wins even if post-trial somehow flips true', () {
      // Belt-and-suspenders: the underlying bug is RevenueCat occasionally
      // reporting isPostTrial=true for brand-new users. The onboarding
      // flag must short-circuit the loss-framed copy.
      expect(
        selectPaywallHeadline(
          contextHeadline: null,
          isFromOnboarding: true,
          isPostTrial: true,
        ),
        isNot('ميزات كنت تستخدمها'),
      );
    });
  });
}
