-- 20260512100000_add_mirrors_relative_id.sql
-- Track personal shadows that mirror admin-owned canonical relatives.
-- When user A claims to be admin's spouse via approve_node_claim, the
-- admin's "wife" row (canonical, admin-owned, in admin's group) gets a
-- personal-scope shadow inserted on the joiner's side. The shadow lives
-- in user A's personal NULL scope, has relationship_type from A's POV
-- ('husband'), and points to the canonical via mirrors_relative_id.

ALTER TABLE public.relatives
  ADD COLUMN IF NOT EXISTS mirrors_relative_id UUID
    REFERENCES public.relatives(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_relatives_mirrors_relative_id
  ON public.relatives(mirrors_relative_id)
  WHERE mirrors_relative_id IS NOT NULL;

COMMENT ON COLUMN public.relatives.mirrors_relative_id IS
  'When set, this row is a personal-scope shadow of another relative row '
  '(the canonical, typically admin-owned in a shared group). Used for '
  'cross-group identity projection (joiner sees her husband everywhere) '
  'and address-book dedup.';
