#!/usr/bin/env bash
#
# Founder helper for DATABASE_AUDIT C1.
#
# The chat tables (chat_conversations, chat_messages, ai_memories) exist
# on production but are NOT defined in any migration AND are NOT in
# legacy/schema.sql either. The CTO sweep flagged that they were created
# either via the Supabase Studio UI or a manual SQL script that never
# made it to the repo.
#
# Until we have the canonical CREATE TABLE statements, we can't write
# the capture migration. This script runs `supabase db dump` against the
# linked project and emits a fragment we can paste into the migration.
#
# Prerequisites:
#   - `supabase login` already done.
#   - `supabase link --project-ref bapwklwxmwhpucutyras` already done
#     (Phase 0 hot-fix has used this).
#
# Usage:
#   bash scripts/dump_chat_tables_for_capture.sh > /tmp/chat_tables_schema.sql
#
# Then send /tmp/chat_tables_schema.sql back so the capture migration
# can be filled in with byte-for-byte accurate definitions.

set -euo pipefail

OUT="${1:-/tmp/chat_tables_schema.sql}"

# `supabase db dump` doesn't support filtering to specific tables, so we
# dump the whole schema and grep out the chat-table-related statements.
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

echo "Dumping public schema from linked Supabase project..." >&2
supabase db dump --schema public --data-only=false > "$TMP"

# Extract everything related to the three target tables. Includes the
# CREATE TABLE statement, indexes, RLS, GRANTs, and policies.
{
  echo "-- Auto-extracted from prod via supabase db dump"
  echo "-- Source: scripts/dump_chat_tables_for_capture.sh"
  echo "-- Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""
  awk '
    BEGIN { in_block = 0 }
    # Open a block on any statement targeting one of the chat tables.
    /^(CREATE TABLE|ALTER TABLE|CREATE INDEX|CREATE UNIQUE INDEX|GRANT|REVOKE|CREATE POLICY|ALTER POLICY|COMMENT ON TABLE|COMMENT ON COLUMN).*\b(chat_conversations|chat_messages|ai_memories)\b/ {
      in_block = 1
      print
      next
    }
    in_block == 1 {
      print
      # Close on the line that ends the statement (terminating semicolon).
      if (/;$/) { in_block = 0; print "" }
    }
  ' "$TMP"
} > "$OUT"

echo "✓ Wrote chat-table DDL to $OUT" >&2
echo "" >&2
echo "Next step: open $OUT, sanity-check it captures CREATE TABLE for each of:" >&2
echo "  - chat_conversations" >&2
echo "  - chat_messages" >&2
echo "  - ai_memories" >&2
echo "Plus any indexes / RLS policies / grants on those tables." >&2
echo "Then paste the contents into supabase/migrations/<timestamp>_capture_chat_tables.sql" >&2
echo "wrapping each CREATE TABLE in IF NOT EXISTS." >&2
