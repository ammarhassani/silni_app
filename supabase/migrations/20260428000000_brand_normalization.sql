-- Phase 6.1 — Task 1: brand-name normalization on prod admin rows.
--
-- Decision (CTO + founder, 2026-04-27): canonical brand form is `صِلْني`
-- (fully vowelized — kasra on ص, sukun on ل). All user-facing surfaces
-- standardize on this single form. See BRAND.md.
--
-- MCP introspection found one prod row carrying the bare `صلني` form:
--   admin_in_app_messages id cf02f758-... — the founder's launch greeting,
--   contains "تطبيق صلني" twice. Migrating the row to the canonical
--   diacritized form so the message renders consistent with the rest of
--   the app.
--
-- Defensive: matches by id (single-row update), idempotent on re-run,
-- guards via the constants Postgres exposes for the substring check.

UPDATE public.admin_in_app_messages
SET body_ar = REPLACE(body_ar, 'صلني', E'صِلْني')
WHERE id = 'cf02f758-398e-40c3-ad94-05936a85ed94';

-- Self-verification — the row no longer contains the bare form, and now
-- contains at least one occurrence of the canonical form.
DO $$
DECLARE
  v_body TEXT;
BEGIN
  SELECT body_ar INTO v_body
  FROM public.admin_in_app_messages
  WHERE id = 'cf02f758-398e-40c3-ad94-05936a85ed94';

  IF v_body IS NULL THEN
    -- Row may have been deleted by an admin between MCP introspection and
    -- this migration applying. That's fine — nothing left to normalize.
    RAISE NOTICE 'admin_in_app_messages row cf02f758-... not found; skipping verify';
    RETURN;
  END IF;

  IF v_body LIKE '%' || E'صلني' || '%'
     AND v_body NOT LIKE '%' || E'صِلْني' || '%' THEN
    RAISE EXCEPTION
      'admin_in_app_messages cf02f758-... still contains bare صلني form';
  END IF;
END $$;
