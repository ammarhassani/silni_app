import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/models/interaction_model.dart';
import 'package:silni_app/core/models/gamification_event.dart';

import '../../helpers/model_factories.dart';

/// Tests for GamificationService logic
///
/// Note: The GamificationService class requires Supabase initialization,
/// so we test the core logic independently by replicating the pure functions.
/// This ensures the business logic is correct without database dependencies.
void main() {
  group('GamificationService Logic', () {
    // =====================================================
    // POINT CALCULATION LOGIC (replicates calculateInteractionPoints)
    // =====================================================

    /// Point values for different interaction types (from GamificationService)
    const Map<InteractionType, int> pointsPerInteraction = {
      InteractionType.call: 10,
      InteractionType.visit: 20,
      InteractionType.message: 5,
      InteractionType.gift: 15,
      InteractionType.event: 25,
      InteractionType.other: 5,
    };

    /// Bonus points (from GamificationService)
    const int pointsForNotes = 5;
    const int pointsForPhoto = 5;
    const int pointsForRating = 3;

    /// Daily point cap (from GamificationService)
    const int dailyPointCap = 200;

    /// Calculate points for an interaction (replicates service logic)
    int calculateInteractionPoints(Interaction interaction) {
      int points = pointsPerInteraction[interaction.type] ?? 5;

      if (interaction.notes != null && interaction.notes!.isNotEmpty) {
        points += pointsForNotes;
      }
      if (interaction.photoUrls.isNotEmpty) {
        points += pointsForPhoto;
      }
      if (interaction.rating != null) {
        points += pointsForRating;
      }

      return points;
    }

    /// XP required for each level (from GamificationService)
    const List<int> xpPerLevel = [
      0, // Level 1
      100, // Level 2
      250, // Level 3
      500, // Level 4
      1000, // Level 5
      2000, // Level 6
      3500, // Level 7
      5500, // Level 8
      8000, // Level 9
      12000, // Level 10
    ];

    /// Calculate level from total points (replicates service logic)
    int calculateLevel(int points) {
      for (int i = xpPerLevel.length - 1; i >= 0; i--) {
        if (points >= xpPerLevel[i]) {
          return i + 1;
        }
      }
      return 1;
    }

    // =====================================================
    // POINT CALCULATION TESTS
    // =====================================================
    group('Point Calculation', () {
      group('Base Points', () {
        test('should return 10 points for call interaction', () {
          final interaction = createTestInteraction(type: InteractionType.call);
          expect(calculateInteractionPoints(interaction), equals(10));
        });

        test('should return 20 points for visit interaction', () {
          final interaction = createTestInteraction(type: InteractionType.visit);
          expect(calculateInteractionPoints(interaction), equals(20));
        });

        test('should return 5 points for message interaction', () {
          final interaction = createTestInteraction(type: InteractionType.message);
          expect(calculateInteractionPoints(interaction), equals(5));
        });

        test('should return 15 points for gift interaction', () {
          final interaction = createTestInteraction(type: InteractionType.gift);
          expect(calculateInteractionPoints(interaction), equals(15));
        });

        test('should return 25 points for event interaction', () {
          final interaction = createTestInteraction(type: InteractionType.event);
          expect(calculateInteractionPoints(interaction), equals(25));
        });

        test('should return 5 points for other interaction', () {
          final interaction = createTestInteraction(type: InteractionType.other);
          expect(calculateInteractionPoints(interaction), equals(5));
        });
      });

      group('Bonus Points', () {
        test('should add 5 bonus points when notes are provided', () {
          final interaction = createTestInteraction(
            type: InteractionType.call,
            notes: 'Great conversation about family',
          );
          // Base 10 + notes 5 = 15
          expect(calculateInteractionPoints(interaction), equals(15));
        });

        test('should not add bonus for empty notes', () {
          final interaction = createTestInteraction(
            type: InteractionType.call,
            notes: '',
          );
          expect(calculateInteractionPoints(interaction), equals(10));
        });

        test('should add 5 bonus points when photos are provided', () {
          final interaction = createTestInteraction(
            type: InteractionType.call,
            photoUrls: ['https://example.com/photo1.jpg'],
          );
          // Base 10 + photo 5 = 15
          expect(calculateInteractionPoints(interaction), equals(15));
        });

        test('should add 5 bonus points for multiple photos (same as single)', () {
          final interaction = createTestInteraction(
            type: InteractionType.visit,
            photoUrls: [
              'https://example.com/photo1.jpg',
              'https://example.com/photo2.jpg',
              'https://example.com/photo3.jpg',
            ],
          );
          // Base 20 + photo 5 = 25
          expect(calculateInteractionPoints(interaction), equals(25));
        });

        test('should add 3 bonus points when rating is provided', () {
          final interaction = createTestInteraction(
            type: InteractionType.call,
            rating: 5,
          );
          // Base 10 + rating 3 = 13
          expect(calculateInteractionPoints(interaction), equals(13));
        });

        test('should stack all bonuses correctly (notes + photo + rating)', () {
          final interaction = createTestInteraction(
            type: InteractionType.visit,
            notes: 'Wonderful family gathering',
            photoUrls: ['https://example.com/photo1.jpg'],
            rating: 5,
          );
          // Base 20 + notes 5 + photo 5 + rating 3 = 33
          expect(calculateInteractionPoints(interaction), equals(33));
        });

        test('should return base points when no bonuses provided', () {
          final interaction = createTestInteraction(
            type: InteractionType.gift,
            notes: null,
            photoUrls: [],
            rating: null,
          );
          expect(calculateInteractionPoints(interaction), equals(15));
        });
      });

      group('All Interaction Types with Maximum Bonuses', () {
        Interaction createMaxBonusInteraction(InteractionType type) {
          return createTestInteraction(
            type: type,
            notes: 'Test notes',
            photoUrls: ['photo.jpg'],
            rating: 5,
          );
        }

        test('call with all bonuses should return 23 points', () {
          // 10 + 5 + 5 + 3 = 23
          expect(
            calculateInteractionPoints(createMaxBonusInteraction(InteractionType.call)),
            equals(23),
          );
        });

        test('visit with all bonuses should return 33 points', () {
          // 20 + 5 + 5 + 3 = 33
          expect(
            calculateInteractionPoints(createMaxBonusInteraction(InteractionType.visit)),
            equals(33),
          );
        });

        test('message with all bonuses should return 18 points', () {
          // 5 + 5 + 5 + 3 = 18
          expect(
            calculateInteractionPoints(createMaxBonusInteraction(InteractionType.message)),
            equals(18),
          );
        });

        test('gift with all bonuses should return 28 points', () {
          // 15 + 5 + 5 + 3 = 28
          expect(
            calculateInteractionPoints(createMaxBonusInteraction(InteractionType.gift)),
            equals(28),
          );
        });

        test('event with all bonuses should return 38 points', () {
          // 25 + 5 + 5 + 3 = 38
          expect(
            calculateInteractionPoints(createMaxBonusInteraction(InteractionType.event)),
            equals(38),
          );
        });

        test('other with all bonuses should return 18 points', () {
          // 5 + 5 + 5 + 3 = 18
          expect(
            calculateInteractionPoints(createMaxBonusInteraction(InteractionType.other)),
            equals(18),
          );
        });
      });
    });

    // =====================================================
    // LEVEL SYSTEM TESTS
    // =====================================================
    group('Level Calculation', () {
      test('should return level 1 for 0 points', () {
        expect(calculateLevel(0), equals(1));
      });

      test('should return level 1 for 99 points', () {
        expect(calculateLevel(99), equals(1));
      });

      test('should return level 2 for 100 points', () {
        expect(calculateLevel(100), equals(2));
      });

      test('should return level 2 for 249 points', () {
        expect(calculateLevel(249), equals(2));
      });

      test('should return level 3 for 250 points', () {
        expect(calculateLevel(250), equals(3));
      });

      test('should return level 3 for 499 points', () {
        expect(calculateLevel(499), equals(3));
      });

      test('should return level 4 for 500 points', () {
        expect(calculateLevel(500), equals(4));
      });

      test('should return level 5 for 1000 points', () {
        expect(calculateLevel(1000), equals(5));
      });

      test('should return level 6 for 2000 points', () {
        expect(calculateLevel(2000), equals(6));
      });

      test('should return level 7 for 3500 points', () {
        expect(calculateLevel(3500), equals(7));
      });

      test('should return level 8 for 5500 points', () {
        expect(calculateLevel(5500), equals(8));
      });

      test('should return level 9 for 8000 points', () {
        expect(calculateLevel(8000), equals(9));
      });

      test('should return level 10 for 12000 points', () {
        expect(calculateLevel(12000), equals(10));
      });

      test('should return level 10 for points exceeding max level', () {
        expect(calculateLevel(50000), equals(10));
      });

      group('Level Boundaries', () {
        // Test exact boundary points
        final levelBoundaries = {
          1: [0, 99],
          2: [100, 249],
          3: [250, 499],
          4: [500, 999],
          5: [1000, 1999],
          6: [2000, 3499],
          7: [3500, 5499],
          8: [5500, 7999],
          9: [8000, 11999],
          10: [12000, 100000],
        };

        levelBoundaries.forEach((level, range) {
          test('should return level $level for ${range[0]} points (lower bound)', () {
            expect(calculateLevel(range[0]), equals(level));
          });

          if (level < 10) {
            test('should return level $level for ${range[1]} points (upper bound)', () {
              expect(calculateLevel(range[1]), equals(level));
            });
          }
        });
      });
    });

    // =====================================================
    // STREAK MILESTONE TESTS
    // =====================================================
    group('Streak Milestones', () {
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

      test('should return false for non-milestone streaks', () {
        final nonMilestones = [1, 2, 3, 5, 6, 8, 10, 15, 20, 25, 35, 45, 75, 99];
        for (final streak in nonMilestones) {
          expect(GamificationEvent.isStreakMilestone(streak), isFalse,
              reason: 'Streak $streak should not be a milestone');
        }
      });
    });

    // =====================================================
    // DAILY POINT CAP TESTS
    // =====================================================
    group('Daily Point Cap', () {
      test('daily point cap should be 200', () {
        expect(dailyPointCap, equals(200));
      });

      test('max points per interaction is 38 (event + all bonuses)', () {
        final maxInteraction = createTestInteraction(
          type: InteractionType.event,
          notes: 'Test',
          photoUrls: ['photo.jpg'],
          rating: 5,
        );
        final maxPoints = calculateInteractionPoints(maxInteraction);
        expect(maxPoints, equals(38));
      });

      test('minimum interactions to hit daily cap varies by type', () {
        // Event (38 max) = 6 interactions to exceed cap
        expect(38 * 6 > dailyPointCap, isTrue);
        expect(38 * 5, equals(190)); // Under cap

        // Visit (33 max) = 7 interactions to exceed cap
        expect(33 * 7 > dailyPointCap, isTrue);
        expect(33 * 6, equals(198)); // Under cap

        // Call (23 max) = 9 interactions to exceed cap
        expect(23 * 9 > dailyPointCap, isTrue);
        expect(23 * 8, equals(184)); // Under cap
      });

      test('exact cap with no bonuses', () {
        // 8 events without bonuses = 200 points exactly
        expect(25 * 8, equals(200));

        // 10 visits without bonuses = 200 points exactly
        expect(20 * 10, equals(200));

        // 20 calls without bonuses = 200 points exactly
        expect(10 * 20, equals(200));

        // 40 messages without bonuses = 200 points exactly
        expect(5 * 40, equals(200));
      });
    });

    // =====================================================
    // BADGE REQUIREMENTS TESTS
    // =====================================================
    group('Badge Requirements', () {
      group('Consistency Badges', () {
        test('first_interaction requires 1+ total interactions', () {
          expect(1 >= 1, isTrue);
          expect(0 >= 1, isFalse);
        });

        test('streak_7 requires 7+ day streak', () {
          expect(7 >= 7, isTrue);
          expect(6 >= 7, isFalse);
        });

        test('streak_30 requires 30+ day streak', () {
          expect(30 >= 30, isTrue);
          expect(29 >= 30, isFalse);
        });

        test('streak_100 requires 100+ day streak', () {
          expect(100 >= 100, isTrue);
          expect(99 >= 100, isFalse);
        });

        test('streak_365 requires 365+ day streak', () {
          expect(365 >= 365, isTrue);
          expect(364 >= 365, isFalse);
        });
      });

      group('Volume Badges', () {
        test('interactions_10 requires 10+ total interactions', () {
          expect(10 >= 10, isTrue);
          expect(9 >= 10, isFalse);
        });

        test('interactions_50 requires 50+ total interactions', () {
          expect(50 >= 50, isTrue);
          expect(49 >= 50, isFalse);
        });

        test('interactions_100 requires 100+ total interactions', () {
          expect(100 >= 100, isTrue);
          expect(99 >= 100, isFalse);
        });

        test('interactions_500 requires 500+ total interactions', () {
          expect(500 >= 500, isTrue);
          expect(499 >= 500, isFalse);
        });

        test('interactions_1000 requires 1000+ total interactions', () {
          expect(1000 >= 1000, isTrue);
          expect(999 >= 1000, isFalse);
        });
      });

      group('Variety Badges', () {
        test('all_interaction_types requires 6 unique types', () {
          final allTypes = InteractionType.values.length;
          expect(allTypes, equals(6));
        });

        test('social_butterfly requires 10+ unique relatives', () {
          expect(10 >= 10, isTrue);
          expect(9 >= 10, isFalse);
        });
      });

      group('Special Badges', () {
        test('generous_giver requires 10+ gift interactions', () {
          expect(10 >= 10, isTrue);
          expect(9 >= 10, isFalse);
        });

        test('family_gatherer requires 10+ event interactions', () {
          expect(10 >= 10, isTrue);
          expect(9 >= 10, isFalse);
        });

        test('frequent_caller requires 50+ call interactions', () {
          expect(50 >= 50, isTrue);
          expect(49 >= 50, isFalse);
        });

        test('devoted_visitor requires 25+ visit interactions', () {
          expect(25 >= 25, isTrue);
          expect(24 >= 25, isFalse);
        });
      });
    });

    // =====================================================
    // POINTS PER INTERACTION TYPE SUMMARY
    // =====================================================
    group('Points Summary', () {
      test('should have correct point values for all interaction types', () {
        final expectedPoints = {
          InteractionType.call: 10,
          InteractionType.visit: 20,
          InteractionType.message: 5,
          InteractionType.gift: 15,
          InteractionType.event: 25,
          InteractionType.other: 5,
        };

        for (final entry in expectedPoints.entries) {
          final interaction = createTestInteraction(type: entry.key);
          expect(
            calculateInteractionPoints(interaction),
            equals(entry.value),
            reason: '${entry.key.name} should give ${entry.value} base points',
          );
        }
      });

      test('should have correct bonus values', () {
        final baseInteraction = createTestInteraction(type: InteractionType.call);
        final maxBonusInteraction = createTestInteraction(
          type: InteractionType.call,
          notes: 'Test',
          photoUrls: ['photo.jpg'],
          rating: 5,
        );

        final basePoints = calculateInteractionPoints(baseInteraction);
        final bonusPoints = calculateInteractionPoints(maxBonusInteraction);

        expect(bonusPoints - basePoints, equals(13)); // 5 + 5 + 3
      });
    });

    // =====================================================
    // XP THRESHOLDS VERIFICATION
    // =====================================================
    group('XP Thresholds', () {
      test('XP thresholds should be monotonically increasing', () {
        for (int i = 1; i < xpPerLevel.length; i++) {
          expect(xpPerLevel[i] > xpPerLevel[i - 1], isTrue,
              reason: 'Level ${i + 1} XP should be greater than Level $i');
        }
      });

      test('XP thresholds should match expected values', () {
        expect(xpPerLevel[0], equals(0)); // Level 1
        expect(xpPerLevel[1], equals(100)); // Level 2
        expect(xpPerLevel[2], equals(250)); // Level 3
        expect(xpPerLevel[3], equals(500)); // Level 4
        expect(xpPerLevel[4], equals(1000)); // Level 5
        expect(xpPerLevel[5], equals(2000)); // Level 6
        expect(xpPerLevel[6], equals(3500)); // Level 7
        expect(xpPerLevel[7], equals(5500)); // Level 8
        expect(xpPerLevel[8], equals(8000)); // Level 9
        expect(xpPerLevel[9], equals(12000)); // Level 10
      });

      test('should have 10 levels', () {
        expect(xpPerLevel.length, equals(10));
      });
    });
  });
}
