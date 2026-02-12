#!/usr/bin/env bash
# Auto-bump version based on conventional commits since the last version tag.
#
# Rules (semver):
#   BREAKING CHANGE / feat!: → major bump
#   feat:                    → minor bump
#   fix: / refactor: / etc.  → patch bump
#
# Build number always increments by 1.
#
# Usage:
#   ./scripts/bump_version.sh          # auto-detect bump type
#   ./scripts/bump_version.sh --dry    # preview without writing
#   ./scripts/bump_version.sh patch    # force patch
#   ./scripts/bump_version.sh minor    # force minor
#   ./scripts/bump_version.sh major    # force major

set -euo pipefail

PUBSPEC="pubspec.yaml"
DRY_RUN=false
FORCE_BUMP=""

for arg in "$@"; do
  case "$arg" in
    --dry)    DRY_RUN=true ;;
    patch)    FORCE_BUMP="patch" ;;
    minor)    FORCE_BUMP="minor" ;;
    major)    FORCE_BUMP="major" ;;
  esac
done

# --- Read current version from pubspec.yaml ---
CURRENT=$(grep '^version:' "$PUBSPEC" | sed 's/version: *//')
VERSION=$(echo "$CURRENT" | cut -d'+' -f1)
BUILD=$(echo "$CURRENT" | cut -d'+' -f2)

MAJOR=$(echo "$VERSION" | cut -d'.' -f1)
MINOR=$(echo "$VERSION" | cut -d'.' -f2)
PATCH=$(echo "$VERSION" | cut -d'.' -f3)

echo "Current: $VERSION+$BUILD"

# --- Find last version tag, or use root commit ---
LAST_TAG=$(git tag -l 'v*' --sort=-v:refname | head -1 2>/dev/null || true)
if [ -z "$LAST_TAG" ]; then
  # No tags — look at all commits since root
  SINCE_REF=$(git rev-list --max-parents=0 HEAD | head -1)
  echo "No version tags found — scanning all commits"
else
  SINCE_REF="$LAST_TAG"
  echo "Last tag: $LAST_TAG"
fi

# --- Analyze commits ---
COMMITS=$(git log "$SINCE_REF"..HEAD --oneline 2>/dev/null || git log --oneline)

FEAT_COUNT=$(echo "$COMMITS" | grep -c '^[a-f0-9]* feat' || true)
FIX_COUNT=$(echo "$COMMITS" | grep -c '^[a-f0-9]* fix' || true)
BREAKING_COUNT=$(echo "$COMMITS" | grep -ci 'BREAKING CHANGE\|^[a-f0-9]* feat!' || true)
TOTAL=$(echo "$COMMITS" | wc -l | tr -d ' ')

echo ""
echo "Commits since last release: $TOTAL"
echo "  feat:     $FEAT_COUNT"
echo "  fix:      $FIX_COUNT"
echo "  breaking: $BREAKING_COUNT"

# --- Determine bump type ---
if [ -n "$FORCE_BUMP" ]; then
  BUMP="$FORCE_BUMP"
  echo ""
  echo "Forced bump: $BUMP"
elif [ "$BREAKING_COUNT" -gt 0 ]; then
  BUMP="major"
elif [ "$FEAT_COUNT" -gt 0 ]; then
  BUMP="minor"
elif [ "$FIX_COUNT" -gt 0 ]; then
  BUMP="patch"
else
  BUMP="patch"
fi

# --- Calculate new version ---
case "$BUMP" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
esac

NEW_BUILD=$((BUILD + 1))
NEW_VERSION="$MAJOR.$MINOR.$PATCH+$NEW_BUILD"

echo ""
echo "Bump: $BUMP"
echo "New:  $MAJOR.$MINOR.$PATCH+$NEW_BUILD"

if [ "$DRY_RUN" = true ]; then
  echo ""
  echo "(dry run — no changes written)"
  exit 0
fi

# --- Write to pubspec.yaml ---
sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"

echo ""
echo "Updated $PUBSPEC to version: $NEW_VERSION"

# --- Tag the commit (after you commit the version bump) ---
echo ""
echo "Next steps:"
echo "  1. Commit: git commit -am 'chore: bump version to $MAJOR.$MINOR.$PATCH'"
echo "  2. Tag:    git tag v$MAJOR.$MINOR.$PATCH"
echo "  3. Build:  flutter build ios / flutter build appbundle"
