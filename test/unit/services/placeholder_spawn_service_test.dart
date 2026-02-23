import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_tree/models/family_graph.dart';
import 'package:silni_app/features/family_tree/services/placeholder_spawn_service.dart';
import 'package:silni_app/shared/models/relative_model.dart';

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

Relative _makeRelative({
  String id = 'rel-1',
  required RelationshipType type,
  Gender? gender,
  FamilySide? side,
}) {
  return Relative(
    id: id,
    userId: 'user-1',
    fullName: 'Test',
    relationshipType: type,
    gender: gender,
    familySide: side,
    createdAt: DateTime.now(),
  );
}

final _father = _makeRelative(
  id: 'father-id',
  type: RelationshipType.father,
  gender: Gender.male,
);

final _mother = _makeRelative(
  id: 'mother-id',
  type: RelationshipType.mother,
  gender: Gender.female,
);

final _brother = _makeRelative(
  id: 'brother-id',
  type: RelationshipType.brother,
  gender: Gender.male,
);

final _paternalUncle = _makeRelative(
  id: 'uncle-pat-id',
  type: RelationshipType.uncle,
  gender: Gender.male,
  side: FamilySide.paternal,
);

final _maternalUncle = _makeRelative(
  id: 'uncle-mat-id',
  type: RelationshipType.uncle,
  gender: Gender.male,
  side: FamilySide.maternal,
);

final _paternalAunt = _makeRelative(
  id: 'aunt-pat-id',
  type: RelationshipType.aunt,
  gender: Gender.female,
  side: FamilySide.paternal,
);

final _paternalGrandfather = _makeRelative(
  id: 'gf-pat-id',
  type: RelationshipType.grandfather,
  gender: Gender.male,
  side: FamilySide.paternal,
);

final _paternalGrandmother = _makeRelative(
  id: 'gm-pat-id',
  type: RelationshipType.grandmother,
  gender: Gender.female,
  side: FamilySide.paternal,
);

final _wife = _makeRelative(
  id: 'wife-id',
  type: RelationshipType.wife,
  gender: Gender.female,
);

final _son = _makeRelative(
  id: 'son-id',
  type: RelationshipType.son,
  gender: Gender.male,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PlaceholderSpawnService', () {
    test('empty tree spawns father + mother + spouse placeholders', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [],
        userGender: Gender.male,
      );

      // father, mother, and spouse (wife for male user)
      expect(placeholders, hasLength(3));
      final types = placeholders.map((p) => p.type).toSet();
      expect(types, contains(RelationshipType.father));
      expect(types, contains(RelationshipType.mother));
      expect(types, contains(RelationshipType.wife));
    });

    test('adding father spawns paternal branch + sibling + mother still', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father],
        userGender: Gender.male,
      );

      final types = placeholders.map((p) => p.type).toList();

      // Mother still missing
      expect(types, contains(RelationshipType.mother));
      // Sibling appears (any parent exists)
      expect(
        types.any((t) =>
            t == RelationshipType.brother || t == RelationshipType.sister),
        isTrue,
      );
      // Paternal grandparents
      expect(types, contains(RelationshipType.grandfather));
      expect(types, contains(RelationshipType.grandmother));
      // Paternal uncle
      expect(types, contains(RelationshipType.uncle));
    });

    test('adding mother spawns maternal branch', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_mother],
        userGender: Gender.male,
      );

      final types = placeholders.map((p) => p.type).toList();

      // Father still missing
      expect(types, contains(RelationshipType.father));
      // Maternal grandparents
      expect(types, contains(RelationshipType.grandfather));
      expect(types, contains(RelationshipType.grandmother));
      // Maternal uncle (خال)
      expect(types, contains(RelationshipType.uncle));
    });

    test('paternal uncle placeholder has FamilySide.paternal', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father],
        userGender: Gender.male,
      );

      final uncles =
          placeholders.where((p) => p.type == RelationshipType.uncle);
      expect(uncles, isNotEmpty);
      expect(uncles.first.side, FamilySide.paternal);
      expect(uncles.first.parentNodeId, 'father-id');
    });

    test('maternal uncle placeholder has FamilySide.maternal', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _mother],
        userGender: Gender.male,
      );

      final uncles =
          placeholders.where((p) => p.type == RelationshipType.uncle);
      // Should have both paternal and maternal
      final paternalUncle =
          uncles.where((p) => p.side == FamilySide.paternal);
      final maternalUncle =
          uncles.where((p) => p.side == FamilySide.maternal);
      expect(paternalUncle, isNotEmpty);
      expect(maternalUncle, isNotEmpty);
      expect(maternalUncle.first.parentNodeId, 'mother-id');
    });

    test('paternal grandparent placeholders have FamilySide.paternal', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father],
        userGender: Gender.male,
      );

      final gf = placeholders
          .where((p) => p.type == RelationshipType.grandfather)
          .first;
      final gm = placeholders
          .where((p) => p.type == RelationshipType.grandmother)
          .first;
      expect(gf.side, FamilySide.paternal);
      expect(gm.side, FamilySide.paternal);
    });

    test('first sibling gets full placeholder', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father],
        userGender: Gender.male,
      );

      final sibPh = placeholders.where((p) =>
          p.type == RelationshipType.brother ||
          p.type == RelationshipType.sister);
      expect(sibPh, isNotEmpty);
      expect(sibPh.first.isCompact, false);
    });

    test('no sibling placeholder when sibling already exists', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _brother],
        userGender: Gender.male,
      );

      final sibPh = placeholders.where((p) =>
          p.type == RelationshipType.brother ||
          p.type == RelationshipType.sister);
      expect(sibPh, isEmpty);
    });

    test('adding uncle spawns cousin placeholder', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _mother, _maternalUncle],
        userGender: Gender.male,
      );

      final cousins =
          placeholders.where((p) => p.type == RelationshipType.cousin);
      expect(cousins, isNotEmpty);
      final maternalCousin =
          cousins.where((p) => p.side == FamilySide.maternal);
      expect(maternalCousin, isNotEmpty);
      expect(maternalCousin.first.parentNodeId, 'uncle-mat-id');
    });

    test('adding aunt also spawns cousin placeholder', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _mother, _paternalAunt],
        userGender: Gender.male,
      );

      final cousins =
          placeholders.where((p) => p.type == RelationshipType.cousin);
      final paternalCousin =
          cousins.where((p) => p.side == FamilySide.paternal);
      expect(paternalCousin, isNotEmpty);
      expect(paternalCousin.first.parentNodeId, 'aunt-pat-id');
    });

    test('spouse placeholder for male user shows wife type', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _mother],
        userGender: Gender.male,
      );

      final spouse =
          placeholders.where((p) => p.type == RelationshipType.wife);
      expect(spouse, isNotEmpty);
    });

    test('spouse placeholder for female user shows husband type', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _mother],
        userGender: Gender.female,
      );

      final spouse =
          placeholders.where((p) => p.type == RelationshipType.husband);
      expect(spouse, isNotEmpty);
    });

    test('no spouse placeholder when spouse exists', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _mother, _wife],
        userGender: Gender.male,
      );

      final spouse = placeholders.where((p) =>
          p.type == RelationshipType.wife ||
          p.type == RelationshipType.husband);
      expect(spouse, isEmpty);
    });

    test('children placeholder appears when spouse exists', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _mother, _wife],
        userGender: Gender.male,
      );

      final children = placeholders.where((p) =>
          p.type == RelationshipType.son ||
          p.type == RelationshipType.daughter);
      expect(children, isNotEmpty);
    });

    test('children placeholder compact when child exists', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _mother, _wife, _son],
        userGender: Gender.male,
      );

      final children = placeholders.where((p) =>
          p.type == RelationshipType.son ||
          p.type == RelationshipType.daughter);
      expect(children, isNotEmpty);
      expect(children.first.isCompact, true);
    });

    test('no children placeholder when no spouse', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _mother],
        userGender: Gender.male,
      );

      final children = placeholders.where((p) =>
          p.type == RelationshipType.son ||
          p.type == RelationshipType.daughter);
      expect(children, isEmpty);
    });

    test('no parent placeholders when both exist', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _mother],
        userGender: Gender.male,
      );

      final parents = placeholders.where((p) =>
          p.type == RelationshipType.father ||
          p.type == RelationshipType.mother);
      expect(parents, isEmpty);
    });

    test('existing paternal grandparents do not re-spawn', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [
          _father,
          _mother,
          _paternalGrandfather,
          _paternalGrandmother,
        ],
        userGender: Gender.male,
      );

      // Should have maternal grandparent placeholders but NOT paternal
      final gfPlaceholders =
          placeholders.where((p) => p.type == RelationshipType.grandfather);
      expect(
        gfPlaceholders.every((p) => p.side == FamilySide.maternal),
        isTrue,
      );
    });

    test('caps at 15 placeholders max', () {
      // Full tree with both parents — triggers many placeholders
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _mother],
        userGender: Gender.male,
      );

      expect(placeholders.length, lessThanOrEqualTo(15));
    });

    test('no uncle placeholder when uncle already exists on that side', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _mother, _paternalUncle],
        userGender: Gender.male,
      );

      final patUncles = placeholders.where(
          (p) => p.type == RelationshipType.uncle &&
                 p.side == FamilySide.paternal);
      // No placeholder since one already exists on paternal side
      expect(patUncles, isEmpty);

      // Maternal uncle placeholder should still exist
      final matUncles = placeholders.where(
          (p) => p.type == RelationshipType.uncle &&
                 p.side == FamilySide.maternal);
      expect(matUncles, isNotEmpty);
    });

    test('aunt placeholder spawns from parent', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _mother],
        userGender: Gender.male,
      );

      final aunts =
          placeholders.where((p) => p.type == RelationshipType.aunt);
      expect(aunts, isNotEmpty);
      // Should have both paternal and maternal aunt placeholders
      final patAunt = aunts.where((p) => p.side == FamilySide.paternal);
      final matAunt = aunts.where((p) => p.side == FamilySide.maternal);
      expect(patAunt, isNotEmpty);
      expect(matAunt, isNotEmpty);
    });

    test('null userGender still shows generic spouse placeholder', () {
      final placeholders = PlaceholderSpawnService.computePlaceholders(
        relatives: [_father, _mother],
        userGender: null,
      );

      final spouse = placeholders.where((p) =>
          p.type == RelationshipType.wife ||
          p.type == RelationshipType.husband);
      expect(spouse, isNotEmpty);
    });
  });
}
