# Flat Relationship Picker — Design Document

**Goal:** Replace ambiguous relationship pickers with a single unified widget where every card maps to exactly one (type, side, gender) tuple. One tap, zero confusion.

**Problem:** Current pickers show generic labels like "عمة/خالة" requiring a second step to pick family side. The side picker is buggy (race conditions, missing data on some code paths). Multiple picker implementations exist (SmartRelationshipPicker, RelationshipSpecificationDialog) with inconsistent behavior.

**Solution:** One shared `FlatRelationshipPicker` widget used everywhere. All relationships are flattened into distinct visual cards grouped by generation.

---

## Card Grid

3-column grid, grouped by generation with section labels.

### الأهل (Parents & Grandparents)
| Emoji | Label | Type | Side | Gender |
|-------|-------|------|------|--------|
| 🧔 | أب | father | — | male |
| 🧕 | أم | mother | — | female |
| 👴 | جد أبوي | grandfather | paternal | male |
| 👵 | جدة أبوية | grandmother | paternal | female |
| 👴 | جد أمي | grandfather | maternal | male |
| 👵 | جدة أمية | grandmother | maternal | female |

### الزوج (Spouse)
| 🧔 | زوج | husband | — | male |
| 🧕 | زوجة | wife | — | female |

### الإخوان (Siblings)
| 👨 | أخ | brother | — | male |
| 🧕 | أخت | sister | — | female |

### الأعمام والأخوال (Uncles & Aunts)
| 🧔 | عم | uncle | paternal | male |
| 🧔 | خال | uncle | maternal | male |
| 🧕 | عمة | aunt | paternal | female |
| 🧕 | خالة | aunt | maternal | female |

### أبناء العم/الخال (Cousins)
| 👨 | ابن العم | cousin | paternal | male |
| 👩 | بنت العم | cousin | paternal | female |
| 👨 | ابن الخال | cousin | maternal | male |
| 👩 | بنت الخال | cousin | maternal | female |

### الأبناء (Children)
| 👦 | ابن | son | — | male |
| 👧 | ابنة | daughter | — | female |

### أبناء الإخوان (Nephews/Nieces)
| 🧑 | ابن أخ/أخت | nephew | — | male |
| 👧 | ابنة أخ/أخت | niece | — | female |

### أخرى
| 👨 | أخرى | other | — | — |

**Total: 23 cards** (before singleton hiding)

---

## Visual Card Design

- Emoji (24px) centered above Arabic label
- GlassCard background (`Colors.white.withValues(alpha: 0.1)`)
- Selected state: primary gradient + white glow border + scale spring
- Aspect ratio ~1.2 (taller than wide)
- `AppTypography.labelSmall` for label
- Haptic feedback on tap

## Section Headers

- Right-aligned label (RTL) in `AppTypography.labelMedium`, white at 60% opacity
- No divider — spacing alone separates sections
- All sections visible, scrollable in `SingleChildScrollView`

## Singleton Hiding

Same logic as current SmartRelationshipPicker:
- Hide أب if father exists
- Hide أم if mother exists
- Hide زوج/زوجة if husband/wife exists
- Hide جد أبوي if paternal grandfather exists (etc.)

## Widget API

```dart
class FlatRelationshipPicker extends StatelessWidget {
  final RelationshipType selected;
  final FamilySide? selectedSide;
  final Gender? selectedGender;
  final List<Relative> existingRelatives;
  final void Function(RelationshipType type, FamilySide? side, Gender? gender) onSelectionChanged;
}
```

## What Gets Replaced

1. `SmartRelationshipPicker` — retired entirely
2. `_buildRelationshipSelector` in `RelationshipSpecificationDialog` — replaced with `FlatRelationshipPicker`
3. Side picker ("من طرف أبوك ولا أمك؟") — gone (baked into cards)
4. Gender picker for cousin — gone (each cousin variant is a separate card)
5. "Show all" toggle — gone (everything visible)
6. AI suggestions section — gone (all cards visible)

## Consumers

1. `add_relative_screen.dart` — replaces SmartRelationshipPicker
2. `relationship_specification_dialog.dart` — replaces inline relationship selector
3. `family_tree_screen.dart` — replaces SmartRelationshipPicker in bottom sheet

## Data Flow

Card tap → `onSelectionChanged(type, side, gender)` → consumer sets all three atomically in one `setState`. No race conditions possible.
