#!/usr/bin/env bash
#
# Lints supabase/migrations/*.sql for foreign-key references to user-id
# columns that lack an explicit ON DELETE clause. This is the class of
# bug that bit us in DATABASE_AUDIT C2 (delete_user_account rolling back
# because family_groups.created_by, family_group_members.user_id,
# node_invitations.invited_by/accepted_by, and admin_audit_log.user_id
# all FK'd to auth.users with no ON DELETE behavior declared).
#
# Bounded scope: this script does ONE thing — checks that every FK
# targeting auth.users(id) or public.users(id) in any new migration
# declares ON DELETE {CASCADE | SET NULL | RESTRICT | NO ACTION}.
# It does NOT lint other constraints, formatting, idempotency, or
# anything else.
#
# Exits 0 if every user-id FK is explicit. Exits 1 with a list of
# offending migrations otherwise.
#
# Usage:
#   bash scripts/check_migrations_for_missing_on_delete.sh
#       Scan the whole supabase/migrations tree. Will fail on the
#       historical violations documented in DATABASE_AUDIT.md C2 — useful
#       for full audits but not appropriate for CI.
#
#   bash scripts/check_migrations_for_missing_on_delete.sh --diff-only BASE_REF
#       Only check migration files that have been added or modified
#       relative to BASE_REF (e.g. origin/main). This is the CI mode —
#       fails only on NEW debt, not the 5 historical FKs.
#
#   bash scripts/check_migrations_for_missing_on_delete.sh path/to/specific.sql
#       Check a single file.

set -euo pipefail

DIFF_ONLY=0
BASE_REF=""
TARGET="supabase/migrations"

while [ $# -gt 0 ]; do
  case "$1" in
    --diff-only)
      DIFF_ONLY=1
      BASE_REF="${2:-origin/main}"
      shift 2 || shift
      ;;
    *)
      TARGET="$1"
      shift
      ;;
  esac
done

# Build the list of files to scan. Using a temp file rather than mapfile
# because the latter isn't available on macOS's default bash 3.2.
files_tmp=$(mktemp)
trap 'rm -f "$files_tmp"' EXIT

if [ "$DIFF_ONLY" -eq 1 ]; then
  # Only files changed against BASE_REF that live under supabase/migrations.
  git diff --name-only --diff-filter=AM "$BASE_REF" -- 'supabase/migrations/*.sql' \
    | sort > "$files_tmp" || true
  if [ ! -s "$files_tmp" ]; then
    echo "✓ No migration files changed against $BASE_REF — nothing to check."
    exit 0
  fi
elif [ -f "$TARGET" ]; then
  echo "$TARGET" > "$files_tmp"
elif [ -d "$TARGET" ]; then
  find "$TARGET" -name "*.sql" | sort > "$files_tmp"
else
  echo "error: $TARGET is not a file or directory" >&2
  exit 2
fi

total=$(wc -l < "$files_tmp" | tr -d ' ')
violations_tmp=$(mktemp)
trap 'rm -f "$files_tmp" "$violations_tmp"' EXIT
# Re-trap because the earlier trap referenced only files_tmp.

while IFS= read -r f; do
  # Strip line comments so a `-- REFERENCES auth.users` in a comment
  # doesn't trip the regex. We keep the file structure (newline count)
  # for line-number reporting via grep -n later.
  stripped=$(sed -E 's/--.*$//' "$f")

  # We're looking for the pattern:
  #   REFERENCES <schema?>users(id)
  # followed (within ~80 chars or up to the next comma/closing paren
  # at the same nesting level) by an ON DELETE clause.
  #
  # awk is more forgiving than grep across line breaks, but for this
  # codebase every REFERENCES clause is on a single line, so a simple
  # line-by-line check is sufficient and easier to debug.

  # Find candidate REFERENCES lines targeting user-id columns.
  # The column may be omitted (rare) or written as users(id).
  while IFS=':' read -r lineno line; do
    # Accept the four legal ON DELETE clauses anywhere on the same line.
    if echo "$line" | grep -qE 'ON DELETE (CASCADE|SET NULL|SET DEFAULT|RESTRICT|NO ACTION)'; then
      continue
    fi
    echo "$f:$lineno: $line" >> "$violations_tmp"
  done < <(echo "$stripped" | grep -nE 'REFERENCES[[:space:]]+(public\.|auth\.)?users[[:space:]]*\(' || true)
done < "$files_tmp"

violation_count=$(wc -l < "$violations_tmp" | tr -d ' ')

if [ "$violation_count" -gt 0 ]; then
  echo "✗ Found $violation_count foreign-key reference(s) to user-id columns missing an explicit ON DELETE clause."
  echo ""
  echo "Every FK targeting auth.users or public.users MUST declare one of:"
  echo "    ON DELETE CASCADE       — dependent rows have no value without the user"
  echo "    ON DELETE SET NULL      — historical/audit records that outlive the user"
  echo "    ON DELETE RESTRICT      — explicit reasoning required in a comment"
  echo "    ON DELETE NO ACTION     — explicit reasoning required in a comment"
  echo ""
  echo "Offending lines:"
  while IFS= read -r v; do
    echo "  $v"
  done < "$violations_tmp"
  echo ""
  echo "See CONTRIBUTING.md > Database migration rules and DATABASE_AUDIT.md > C2."
  exit 1
fi

# Count what we did scan so the success message is honest.
checked=$(xargs grep -lE 'REFERENCES[[:space:]]+(public\.|auth\.)?users[[:space:]]*\(' < "$files_tmp" 2>/dev/null | wc -l | tr -d ' ')
echo "✓ Checked $total migration file(s); $checked file(s) contained user-id FK references; all are explicit about ON DELETE."
exit 0
