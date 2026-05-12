/// Pure decision for the paywall's main headline.
///
/// Three inputs decide the copy:
/// - [contextHeadline]: explicit override (e.g. feature-trigger copy).
/// - [isFromOnboarding]: true when the paywall is being pushed from the
///   onboarding wizard's finish step. Suppresses loss-framed copy because
///   a brand-new user has never used a feature.
/// - [isPostTrial]: derived from RevenueCat state. True when the user has
///   already burned a trial and is not subscribed — the natural moment
///   for "features you were using" framing.
///
/// Defect 1 fix: previously the headline only checked [isPostTrial]. For
/// new users whose RevenueCat state momentarily flipped post-trial (slow
/// load, regional ineligibility), the wizard finish step would surface
/// "ميزات كنت تستخدمها" — copy that implies prior usage they don't have.
String selectPaywallHeadline({
  required String? contextHeadline,
  required bool isFromOnboarding,
  required bool isPostTrial,
}) {
  if (contextHeadline != null) return contextHeadline;
  if (isFromOnboarding) return 'الاشتراك المميز';
  if (isPostTrial) return 'ميزات كنت تستخدمها';
  return 'الاشتراك المميز';
}
