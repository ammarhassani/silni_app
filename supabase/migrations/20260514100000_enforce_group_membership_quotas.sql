-- 20260514100000_enforce_group_membership_quotas.sql
-- Enforce per-user membership quotas:
--   - 1 admin role across all groups (creating a "your family" group)
--   - 2 member roles across all groups (joining family lineages)
-- Personal scope is not a membership; always available.
--
-- These caps prevent group sprawl while allowing the canonical Saudi
-- family pattern (1 paternal + 1 spousal lineage as member; optionally
-- 1 own admin group).

CREATE OR REPLACE FUNCTION public.enforce_group_membership_quotas()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_count INT;
  v_member_count INT;
BEGIN
  IF NEW.role = 'admin' THEN
    SELECT COUNT(*) INTO v_admin_count
    FROM family_group_members
    WHERE user_id = NEW.user_id
      AND role = 'admin'
      AND id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);

    IF v_admin_count >= 1 THEN
      RAISE EXCEPTION 'لديك بالفعل عائلة. احذفها قبل إنشاء أخرى.'
        USING ERRCODE = 'P0001';
    END IF;
  ELSIF NEW.role = 'member' THEN
    SELECT COUNT(*) INTO v_member_count
    FROM family_group_members
    WHERE user_id = NEW.user_id
      AND role = 'member'
      AND id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid);

    IF v_member_count >= 2 THEN
      RAISE EXCEPTION 'أنت بالفعل في عائلتَين. غادر إحداهما قبل الانضمام لهذه.'
        USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_membership_quotas ON family_group_members;
CREATE TRIGGER trg_enforce_membership_quotas
  BEFORE INSERT ON family_group_members
  FOR EACH ROW
  EXECUTE FUNCTION enforce_group_membership_quotas();

-- Helper RPC for the UI to query quota state.
-- Returns:
--   admin            : single FamilyGroup row or null
--   members          : array of FamilyGroup rows (0..2)
--   admin_slot_full  : boolean
--   member_slot_full : boolean
CREATE OR REPLACE FUNCTION public.get_my_membership_slots()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_admin JSONB;
  v_members JSONB;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT to_jsonb(fg.*) INTO v_admin
  FROM family_group_members m
  JOIN family_groups fg ON fg.id = m.group_id
  WHERE m.user_id = v_caller AND m.role = 'admin'
  LIMIT 1;

  SELECT COALESCE(jsonb_agg(to_jsonb(fg.*)), '[]'::jsonb) INTO v_members
  FROM family_group_members m
  JOIN family_groups fg ON fg.id = m.group_id
  WHERE m.user_id = v_caller AND m.role = 'member';

  RETURN jsonb_build_object(
    'admin', v_admin,
    'members', v_members,
    'admin_slot_full', v_admin IS NOT NULL,
    'member_slot_full', (SELECT COUNT(*) FROM family_group_members
                          WHERE user_id = v_caller AND role = 'member') >= 2
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_membership_slots() TO authenticated;
