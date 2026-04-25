#!/usr/bin/env bash
#
# Generalized version of scripts/dump_chat_tables_for_capture.sh.
# Takes one or more table names as arguments and emits the canonical
# CREATE TABLE / ALTER / INDEX / RLS / GRANT / POLICY / COMMENT
# statements for them, extracted from `supabase db dump`.
#
# Used to capture ghost tables in migrations. See
# DATABASE_WAVE_1_5_REPORT.md and GHOST_TABLES_RECONNAISSANCE.md for the
# full ghost-table list and the rationale.
#
# Prerequisites:
#   - `supabase login` already done
#   - `supabase link --project-ref <ref>` already done
#
# Usage:
#   bash scripts/dump_tables_for_capture.sh users relatives interactions \
#        reminder_schedules notification_history notification_tokens \
#        admin_announcements > /tmp/wave_1_5_dump.sql
#
#   bash scripts/dump_tables_for_capture.sh fcm_tokens > /tmp/fcm_tokens_dump.sql

set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <table_name> [<table_name> ...]" >&2
  exit 2
fi

# Build a regex alternation of the requested table names with word boundaries.
# Escape `.` defensively though table names shouldn't contain it.
table_regex=""
for t in "$@"; do
  escaped=$(echo "$t" | sed 's/[][\.*^$/]/\\&/g')
  if [ -z "$table_regex" ]; then
    table_regex="$escaped"
  else
    table_regex="$table_regex|$escaped"
  fi
done

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

echo "Dumping public schema from linked Supabase project..." >&2
supabase db dump --schema public --data-only=false > "$TMP"

# Extract every statement that mentions one of the requested tables.
# Multi-line statements are kept intact via the in_block state machine.
{
  echo "-- Auto-extracted from prod via supabase db dump"
  echo "-- Source: scripts/dump_tables_for_capture.sh"
  echo "-- Tables requested: $*"
  echo "-- Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""
  awk -v regex="\\b($table_regex)\\b" '
    BEGIN { in_block = 0 }
    # Open a block on any DDL whose first line mentions a target table.
    /^(CREATE TABLE|ALTER TABLE|CREATE INDEX|CREATE UNIQUE INDEX|GRANT|REVOKE|CREATE POLICY|ALTER POLICY|COMMENT ON TABLE|COMMENT ON COLUMN|CREATE TRIGGER)/ {
      if ($0 ~ regex) {
        in_block = 1
        print
        if (/;$/) { in_block = 0; print "" }
        next
      }
    }
    in_block == 1 {
      print
      if (/;$/) { in_block = 0; print "" }
    }
  ' "$TMP"
} >&1

echo "" >&2
echo "✓ Dump complete." >&2
echo "Sanity check: confirm CREATE TABLE for each of: $*" >&2
echo "Then send the output back so the capture migration can be filled in" >&2
echo "with byte-for-byte accurate definitions wrapped in IF NOT EXISTS." >&2
