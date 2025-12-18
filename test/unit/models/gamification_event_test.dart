import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/core/models/gamification_event.dart';

import '../../helpers/model_factories.dart';

void main() {
  group('GamificationEvent Model', () {
    // =====================================================
    // EVENT TYPE TESTS
    // =====================================================
    group('GamificationEventType', () {
      test('should have 5 event types', () {
        expect(GamificationEventType.values.length, equals(5));
      });

      test('should include all expected types', () {
        expect(GamificationEventType.values, contains(GamificationEventType.pointsEarned));
        expect(GamificationEventType.values, contains(GamificationEventType.badgeUnlocked));
        expect(GamificationEventType.values, contains(GamificationEventType.levelUp));
        expect(GamificationEventType.values, contains(GamificationEventType.streakIncreased));
        expect(GamificationEventType.values, contains(GamificationEventType.streakMilestone));
      });
    });

    // =====================================================
    // POINTS EARNED EVENT TESTS
    // =====================================================
    group('pointsEarned factory', () {
      test('should create points earned event with correct type', () {
        final event = GamificationEvent.pointsEarned(
          userId: 'test-user',
          points: 20,
          source: 'visit',
        );

        expect(event.type, equals(GamificationEventType.pointsEarned));
        expect(event.userId, equals('test-user'));
      });

      test('should store points in data', () {
        final event = GamificationEvent.pointsEarned(
          userId: 'test-user',
          points: 15,
          source: 'gift',
        );

        expect(event.data['points'], equals(15));
        expect(event.data['source'], equals('gift'));
      });

      test('should have points getter', () {
        final event = createTestPointsEarnedEvent(points: 25, source: 'event');

        expect(event.points, equals(25));
      });

      test('should have timestamp', () {
        final event = createTestPointsEarnedEvent();

        expect(event.timestamp, isNotNull);
        expect(event.timestamp.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
      });

      test('should accept custom timestamp', () {
        final customTime = DateTime(2024, 1, 1, 12, 0, 0);
        final event = createTestPointsEarnedEvent(timestamp: customTime);

        expect(event.timestamp, equals(customTime));
      });
    });

    // =====================================================
    // BADGE UNLOCKED EVENT TESTS
    // =====================================================
    group('badgeUnlocked factory', () {
      test('should create badge unlocked event with correct type', () {
        final event = GamificationEvent.badgeUnlocked(
          userId: 'test-user',
          badgeId: 'first_interaction',
          badgeName: 'أول تفاعل',
          badgeDescription: 'سجلت أول تفاعل لك',
        );

        expect(event.type, equals(GamificationEventType.badgeUnlocked));
        expect(event.userId, equals('test-user'));
      });

      test('should store badge info in data', () {
        final event = GamificationEvent.badgeUnlocked(
          userId: 'test-user',
          badgeId: 'streak_7',
          badgeName: 'أسبوع متواصل',
          badgeDescription: 'تفاعلت لمدة 7 أيام متتالية',
        );

        expect(event.data['badge_id'], equals('streak_7'));
        expect(event.data['badge_name'], equals('أسبوع متواصل'));
        expect(event.data['badge_description'], equals('تفاعلت لمدة 7 أيام متتالية'));
      });

      test('should have badge getters', () {
        final event = createTestBadgeUnlockedEvent(
          badgeId: 'interactions_10',
          badgeName: '10 تفاعلات',
          badgeDescription: 'أكملت 10 تفاعلات',
        );

        expect(event.badgeId, equals('interactions_10'));
        expect(event.badgeName, equals('10 تفاعلات'));
        expect(event.badgeDescription, equals('أكملت 10 تفاعلات'));
      });
    });

    // =====================================================
    // LEVEL UP EVENT TESTS
    // =====================================================
    group('levelUp factory', () {
      test('should create level up event with correct type', () {
        final event = GamificationEvent.levelUp(
          userId: 'test-user',
          oldLevel: 1,
          newLevel: 2,
          currentXP: 100,
          xpToNextLevel: 150,
        );

        expect(event.type, equals(GamificationEventType.levelUp));
        expect(event.userId, equals('test-user'));
      });

      test('should store level info in data', () {
        final event = GamificationEvent.levelUp(
          userId: 'test-user',
          oldLevel: 3,
          newLevel: 4,
          currentXP: 500,
          xpToNextLevel: 500,
        );

        expect(event.data['old_level'], equals(3));
        expect(event.data['new_level'], equals(4));
        expect(event.data['current_xp'], equals(500));
        expect(event.data['xp_to_next_level'], equals(500));
      });

      test('should have level getters', () {
        final event = createTestLevelUpEvent(
          oldLevel: 5,
          newLevel: 6,
          currentXP: 2000,
          xpToNextLevel: 1500,
        );

        expect(event.oldLevel, equals(5));
        expect(event.newLevel, equals(6));
        expect(event.currentXP, equals(2000));
        expect(event.xpToNextLevel, equals(1500));
      });
    });

    // =====================================================
    // STREAK INCREASED EVENT TESTS
    // =====================================================
    group('streakIncreased factory', () {
      test('should create streak increased event with correct type', () {
        final event = GamificationEvent.streakIncreased(
          userId: 'test-user',
          currentStreak: 5,
          longestStreak: 10,
        );

        expect(event.type, equals(GamificationEventType.streakIncreased));
        expect(event.userId, equals('test-user'));
      });

      test('should store streak info in data', () {
        final event = GamificationEvent.streakIncreased(
          userId: 'test-user',
          currentStreak: 15,
          longestStreak: 30,
        );

        expect(event.data['current_streak'], equals(15));
        expect(event.data['longest_streak'], equals(30));
      });

      test('should have currentStreak getter', () {
        final event = createTestStreakIncreasedEvent(
          currentStreak: 7,
          longestStreak: 14,
        );

        expect(event.currentStreak, equals(7));
      });
    });

    // =====================================================
    // STREAK MILESTONE EVENT TESTS
    // =====================================================
    group('streakMilestone factory', () {
      test('should create streak milestone event with correct type', () {
        final event = GamificationEvent.streakMilestone(
          userId: 'test-user',
          streak: 7,
        );

        expect(event.type, equals(GamificationEventType.streakMilestone));
        expect(event.userId, equals('test-user'));
      });

      test('should store streak in data', () {
        final event = GamificationEvent.streakMilestone(
          userId: 'test-user',
          streak: 30,
        );

        expect(event.data['streak'], equals(30));
      });

      test('should have streak getter via currentStreak', () {
        final event = createTestStreakMilestoneEvent(streak: 100);

        expect(event.streak, equals(100));
        expect(event.currentStreak, equals(100));
      });
    });

    // =====================================================
    // IS STREAK MILESTONE TESTS
    // =====================================================
    group('isStreakMilestone', () {
      test('should return true for 7-day milestone', () {
        expect(GamificationEvent.isStreakMilestone(7), isTrue);
      });

      test('should return true for 14-day milestone', () {
        expect(GamificationEvent.isStreakMilestone(14), isTrue);
      });

      test('should return true for 30-day milestone', () {
        expect(GamificationEvent.isStreakMilestone(30), isTrue);
      });

      test('should return true for 50-day milestone', () {
        expect(GamificationEvent.isStreakMilestone(50), isTrue);
      });

      test('should return true for 100-day milestone', () {
        expect(GamificationEvent.isStreakMilestone(100), isTrue);
      });

      test('should return false for non-milestone values', () {
        final nonMilestones = [1, 2, 3, 5, 6, 8, 10, 15, 20, 25, 35, 45, 75, 99];
        for (final streak in nonMilestones) {
          expect(
            GamificationEvent.isStreakMilestone(streak),
            isFalse,
            reason: 'Streak $streak should not be a milestone',
          );
        }
      });

      test('should return false for 0', () {
        expect(GamificationEvent.isStreakMilestone(0), isFalse);
      });

      test('should return false for negative values', () {
        expect(GamificationEvent.isStreakMilestone(-1), isFalse);
        expect(GamificationEvent.isStreakMilestone(-7), isFalse);
      });
    });

    // =====================================================
    // GETTER TESTS
    // =====================================================
    group('Getters', () {
      test('points getter should return null for non-points event', () {
        final event = createTestBadgeUnlockedEvent();
        expect(event.points, isNull);
      });

      test('badgeId getter should return null for non-badge event', () {
        final event = createTestPointsEarnedEvent();
        expect(event.badgeId, isNull);
      });

      test('badgeName getter should return null for non-badge event', () {
        final event = createTestPointsEarnedEvent();
        expect(event.badgeName, isNull);
      });

      test('oldLevel getter should return null for non-level event', () {
        final event = createTestPointsEarnedEvent();
        expect(event.oldLevel, isNull);
      });

      test('newLevel getter should return null for non-level event', () {
        final event = createTestPointsEarnedEvent();
        expect(event.newLevel, isNull);
      });

      test('currentXP getter should return null for non-level event', () {
        final event = createTestPointsEarnedEvent();
        expect(event.currentXP, isNull);
      });

      test('xpToNextLevel getter should return null for non-level event', () {
        final event = createTestPointsEarnedEvent();
        expect(event.xpToNextLevel, isNull);
      });

      test('currentStreak getter should return value from either key', () {
        // From streak_increased (uses current_streak)
        final streakIncreased = createTestStreakIncreasedEvent(currentStreak: 10);
        expect(streakIncreased.currentStreak, equals(10));

        // From streak_milestone (uses streak)
        final streakMilestone = createTestStreakMilestoneEvent(streak: 30);
        expect(streakMilestone.currentStreak, equals(30));
      });
    });

    // =====================================================
    // TO STRING TESTS
    // =====================================================
    group('toString', () {
      test('should include type in string representation', () {
        final event = createTestPointsEarnedEvent();
        expect(event.toString(), contains('pointsEarned'));
      });

      test('should include userId in string representation', () {
        final event = createTestPointsEarnedEvent(userId: 'custom-user');
        expect(event.toString(), contains('custom-user'));
      });

      test('should include data in string representation', () {
        final event = createTestPointsEarnedEvent(points: 50);
        expect(event.toString(), contains('50'));
      });

      test('should include timestamp in string representation', () {
        final event = createTestPointsEarnedEvent();
        expect(event.toString(), contains('timestamp'));
      });
    });

    // =====================================================
    // EVENT DATA INTEGRITY TESTS
    // =====================================================
    group('Event Data Integrity', () {
      test('pointsEarned event should have required data keys', () {
        final event = createTestPointsEarnedEvent(points: 10, source: 'call');

        expect(event.data.containsKey('points'), isTrue);
        expect(event.data.containsKey('source'), isTrue);
      });

      test('badgeUnlocked event should have required data keys', () {
        final event = createTestBadgeUnlockedEvent(
          badgeId: 'test',
          badgeName: 'Test',
          badgeDescription: 'Description',
        );

        expect(event.data.containsKey('badge_id'), isTrue);
        expect(event.data.containsKey('badge_name'), isTrue);
        expect(event.data.containsKey('badge_description'), isTrue);
      });

      test('levelUp event should have required data keys', () {
        final event = createTestLevelUpEvent();

        expect(event.data.containsKey('old_level'), isTrue);
        expect(event.data.containsKey('new_level'), isTrue);
        expect(event.data.containsKey('current_xp'), isTrue);
        expect(event.data.containsKey('xp_to_next_level'), isTrue);
      });

      test('streakIncreased event should have required data keys', () {
        final event = createTestStreakIncreasedEvent();

        expect(event.data.containsKey('current_streak'), isTrue);
        expect(event.data.containsKey('longest_streak'), isTrue);
      });

      test('streakMilestone event should have required data keys', () {
        final event = createTestStreakMilestoneEvent();

        expect(event.data.containsKey('streak'), isTrue);
      });
    });
  });
}
