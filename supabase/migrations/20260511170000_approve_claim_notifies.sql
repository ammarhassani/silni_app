-- 20260511170000_approve_claim_notifies.sql
-- Trigger a push to the joiner when their claim is approved/rejected,
-- and notify admins when a claim is created.
--
-- DEGRADATION: As of this migration's authoring, the project has pg_net
-- installed but `app.settings.supabase_url` and `app.settings.service_role_key`
-- are NOT configured. The helper below is therefore a NO-OP that only logs
-- via RAISE NOTICE. In-app realtime via `claimByIdRealtimeProvider` already
-- covers the joiner's UX (status pending → approved/rejected). When push is
-- required, flip the body of `_notify_claim_status` to actually call
-- `net.http_post` against the `send-push-notification` edge function.

CREATE OR REPLACE FUNCTION public._notify_claim_status(
  p_claimant_user_id UUID,
  p_group_id UUID,
  p_template_key TEXT,
  p_extra JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- TODO: pg_net + app.settings (supabase_url, service_role_key) not configured.
  -- In-app realtime via claimByIdRealtimeProvider covers the joiner's UX.
  -- When push is required, replace this body with:
  --
  --   DECLARE v_template RECORD; v_group_name TEXT; v_title TEXT; v_body TEXT;
  --   SELECT title_ar, body_ar INTO v_template FROM admin_notification_templates
  --    WHERE template_key = p_template_key AND is_active;
  --   IF NOT FOUND THEN RETURN; END IF;
  --   SELECT name INTO v_group_name FROM family_groups WHERE id = p_group_id;
  --   v_title := REPLACE(v_template.title_ar, '{group_name}', COALESCE(v_group_name, ''));
  --   v_body  := REPLACE(v_template.body_ar,  '{group_name}', COALESCE(v_group_name, ''));
  --   PERFORM net.http_post(
  --     url := current_setting('app.settings.supabase_url', true) || '/functions/v1/send-push-notification',
  --     headers := jsonb_build_object(
  --       'Content-Type', 'application/json',
  --       'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
  --     ),
  --     body := jsonb_build_object(
  --       'userId', p_claimant_user_id,
  --       'notificationType', 'system',
  --       'title', v_title,
  --       'body', v_body,
  --       'data', jsonb_build_object('type', p_template_key, 'group_id', p_group_id) || p_extra
  --     )
  --   );
  RAISE NOTICE '[_notify_claim_status no-op] user=% group=% template=% extra=%',
    p_claimant_user_id, p_group_id, p_template_key, p_extra;
END;
$$;

-- ---------------------------------------------------------------------------
-- approve_node_claim: add notification dispatch right before final RETURN.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.approve_node_claim(p_claim_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_caller_id UUID := auth.uid();
  v_claim RECORD;
  v_target_relative_id UUID;
  v_relationship_type TEXT;
  v_admin_member RECORD;
  v_anchor_id UUID;
BEGIN
  SELECT * INTO v_claim FROM node_claims WHERE id = p_claim_id FOR UPDATE;
  IF v_claim IS NULL THEN
    RAISE EXCEPTION 'الطلب غير موجود';
  END IF;
  IF v_claim.status != 'pending' THEN
    RAISE EXCEPTION 'لا يمكن تأكيد طلب غير معلق';
  END IF;
  SELECT id, role INTO v_admin_member
  FROM family_group_members
  WHERE group_id = v_claim.group_id AND user_id = v_caller_id;
  IF v_admin_member IS NULL OR v_admin_member.role != 'admin' THEN
    RAISE EXCEPTION 'فقط مسؤول المجموعة يمكنه تأكيد الطلبات';
  END IF;

  v_anchor_id := v_claim.declared_anchor_relative_id;

  IF v_claim.claimed_relative_id IS NOT NULL THEN
    v_target_relative_id := v_claim.claimed_relative_id;
    IF EXISTS (SELECT 1 FROM relatives WHERE id = v_target_relative_id AND is_self = true) THEN
      RAISE EXCEPTION 'هذه العقدة مطالب بها من قبل';
    END IF;
    IF EXISTS (
      SELECT 1 FROM family_group_members
      WHERE group_id = v_claim.group_id AND relative_id_in_tree = v_target_relative_id
        AND user_id != v_claim.claimant_user_id
    ) THEN
      RAISE EXCEPTION 'هذه العقدة مرتبطة بعضو آخر';
    END IF;
  ELSE
    v_relationship_type := CASE
      WHEN v_claim.declared_edge_path = 'parent' AND v_claim.declared_gender = 'male'   THEN 'father'
      WHEN v_claim.declared_edge_path = 'parent' AND v_claim.declared_gender = 'female' THEN 'mother'
      WHEN v_claim.declared_edge_path = 'child'  AND v_claim.declared_gender = 'male'   THEN 'son'
      WHEN v_claim.declared_edge_path = 'child'  AND v_claim.declared_gender = 'female' THEN 'daughter'
      WHEN v_claim.declared_edge_path = 'spouse' AND v_claim.declared_gender = 'male'   THEN 'husband'
      WHEN v_claim.declared_edge_path = 'spouse' AND v_claim.declared_gender = 'female' THEN 'wife'
      WHEN v_claim.declared_edge_path = 'sibling' AND v_claim.declared_gender = 'male'  THEN 'brother'
      WHEN v_claim.declared_edge_path = 'sibling' AND v_claim.declared_gender = 'female' THEN 'sister'
      ELSE NULL
    END;
    IF v_relationship_type IS NULL THEN
      RAISE EXCEPTION 'لا يمكن إنشاء عقدة جديدة لهذه القرابة (يجب اختيار شخص موجود في الشجرة)';
    END IF;

    INSERT INTO relatives (
      user_id, full_name, relationship_type, gender,
      family_group_id, family_side, added_by, relative_category,
      date_of_birth, city, photo_url
    )
    VALUES (
      v_claim.claimant_user_id,
      v_claim.proposed_full_name,
      v_relationship_type,
      COALESCE(v_claim.proposed_gender, v_claim.declared_gender),
      v_claim.group_id,
      v_claim.declared_parent_side,
      v_caller_id,
      'extended',
      CASE WHEN v_claim.proposed_birth_year IS NOT NULL
           THEN make_timestamptz(v_claim.proposed_birth_year, 1, 1, 0, 0, 0, 'UTC')
           ELSE NULL END,
      v_claim.proposed_city,
      v_claim.proposed_photo_url
    )
    RETURNING id INTO v_target_relative_id;
  END IF;

  UPDATE relatives
  SET is_self = true, user_id = v_claim.claimant_user_id
  WHERE id = v_target_relative_id;

  INSERT INTO family_group_members (group_id, user_id, role, relative_id_in_tree)
  VALUES (v_claim.group_id, v_claim.claimant_user_id, 'member', v_target_relative_id)
  ON CONFLICT (group_id, user_id)
  DO UPDATE SET relative_id_in_tree = EXCLUDED.relative_id_in_tree;

  IF v_claim.claimed_relative_id IS NULL THEN
    IF v_claim.declared_edge_path = 'spouse' THEN
      INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
      VALUES (v_caller_id, v_anchor_id::text, v_target_relative_id::text,
              'spouse_of', v_claim.group_id)
      ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
    ELSIF v_claim.declared_edge_path = 'parent' THEN
      INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
      VALUES (v_caller_id, v_target_relative_id::text, v_anchor_id::text,
              'parent_of', v_claim.group_id)
      ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
    ELSIF v_claim.declared_edge_path = 'child' THEN
      INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
      VALUES (v_caller_id, v_anchor_id::text, v_target_relative_id::text,
              'parent_of', v_claim.group_id)
      ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
    ELSIF v_claim.declared_edge_path = 'sibling' THEN
      INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
      VALUES (v_caller_id, v_anchor_id::text, v_target_relative_id::text,
              'sibling_of', v_claim.group_id)
      ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
      INSERT INTO family_edges (user_id, from_id, to_id, edge_type, family_group_id)
      SELECT v_caller_id, e.from_id, v_target_relative_id::text,
             'parent_of', v_claim.group_id
      FROM family_edges e
      WHERE e.to_id = v_anchor_id::text
        AND e.edge_type = 'parent_of'
        AND e.family_group_id = v_claim.group_id
      ON CONFLICT (user_id, from_id, to_id, edge_type) DO NOTHING;
    END IF;
  END IF;

  UPDATE node_claims
  SET status = 'approved', decided_by = v_caller_id, decided_at = now()
  WHERE id = p_claim_id;

  -- Notify the claimant that their request was approved.
  PERFORM public._notify_claim_status(
    v_claim.claimant_user_id, v_claim.group_id, 'claim_approved'
  );

  RETURN jsonb_build_object(
    'claim_id', p_claim_id,
    'group_id', v_claim.group_id,
    'claimant_user_id', v_claim.claimant_user_id,
    'relative_id', v_target_relative_id,
    'created_new_node', (v_claim.claimed_relative_id IS NULL)
  );
END;
$function$;

-- ---------------------------------------------------------------------------
-- reject_node_claim: add notification dispatch right before function end.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.reject_node_claim(p_claim_id uuid, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_caller_id UUID := auth.uid();
  v_claim RECORD;
BEGIN
  SELECT * INTO v_claim FROM node_claims WHERE id = p_claim_id FOR UPDATE;
  IF v_claim IS NULL THEN RAISE EXCEPTION 'الطلب غير موجود'; END IF;
  IF v_claim.status != 'pending' THEN RAISE EXCEPTION 'لا يمكن رفض طلب غير معلق'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = v_claim.group_id AND user_id = v_caller_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'فقط مسؤول المجموعة يمكنه رفض الطلبات';
  END IF;
  UPDATE node_claims
  SET status = 'rejected', rejection_reason = NULLIF(trim(p_reason), ''),
      decided_by = v_caller_id, decided_at = now()
  WHERE id = p_claim_id;

  -- Notify the claimant that their request was rejected.
  PERFORM public._notify_claim_status(
    v_claim.claimant_user_id, v_claim.group_id, 'claim_rejected',
    jsonb_build_object('reason_text', COALESCE(p_reason, ''))
  );
END;
$function$;

-- ---------------------------------------------------------------------------
-- create_node_claim: notify every admin of the group when a claim is created.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_node_claim(
  p_group_id uuid,
  p_claimed_relative_id uuid,
  p_anchor_relative_id uuid,
  p_edge_path text,
  p_parent_side text,
  p_gender text,
  p_proposed_full_name text DEFAULT NULL::text,
  p_proposed_gender text DEFAULT NULL::text,
  p_proposed_birth_year integer DEFAULT NULL::integer,
  p_proposed_city text DEFAULT NULL::text,
  p_proposed_photo_url text DEFAULT NULL::text,
  p_proposed_phone_number text DEFAULT NULL::text,
  p_invite_code text DEFAULT NULL::text
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_caller_id UUID := auth.uid();
  v_is_member BOOLEAN;
  v_code_valid BOOLEAN;
  v_normalized_phone TEXT;
  v_claim_id UUID;
  v_claim JSONB;
  v_admin RECORD;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- AUTH: caller is a member OR presented a valid invite code for this group.
  SELECT EXISTS(
    SELECT 1 FROM family_group_members
    WHERE group_id = p_group_id AND user_id = v_caller_id
  ) INTO v_is_member;

  IF NOT v_is_member THEN
    IF p_invite_code IS NULL THEN
      RAISE EXCEPTION 'يجب أن تكون عضواً في المجموعة أو تقدم رمز دعوة صالح';
    END IF;
    SELECT EXISTS(
      SELECT 1 FROM family_groups
      WHERE id = p_group_id AND invite_code = p_invite_code
    ) INTO v_code_valid;
    IF NOT v_code_valid THEN
      RAISE EXCEPTION 'رمز الدعوة غير صالح';
    END IF;
  END IF;

  IF EXISTS (
    SELECT 1 FROM node_claims
    WHERE group_id = p_group_id
      AND claimant_user_id = v_caller_id
      AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'لديك طلب معلق بالفعل في هذه المجموعة';
  END IF;

  IF (p_claimed_relative_id IS NULL) = (p_proposed_full_name IS NULL) THEN
    RAISE EXCEPTION 'يجب تقديم relative موجود أو اسم لإضافة جديدة، وليس كلاهما';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM relatives
    WHERE id = p_anchor_relative_id AND family_group_id = p_group_id
  ) THEN
    RAISE EXCEPTION 'Anchor relative not in group';
  END IF;

  IF p_edge_path NOT IN (
    'parent','child','spouse','sibling',
    'uncle_aunt','grandparent','grandchild','cousin','nephew_niece'
  ) THEN
    RAISE EXCEPTION 'Invalid edge_path: %', p_edge_path;
  END IF;

  IF p_proposed_phone_number IS NOT NULL AND trim(p_proposed_phone_number) != '' THEN
    v_normalized_phone := regexp_replace(trim(p_proposed_phone_number), '\s+', '', 'g');
    IF left(v_normalized_phone, 1) != '+' THEN
      v_normalized_phone := '+' || v_normalized_phone;
    END IF;
    IF length(v_normalized_phone) < 8 OR length(v_normalized_phone) > 16 THEN
      RAISE EXCEPTION 'رقم الهاتف غير صالح';
    END IF;
  END IF;

  INSERT INTO node_claims (
    group_id, claimant_user_id, claimed_relative_id, declared_anchor_relative_id,
    declared_edge_path, declared_parent_side, declared_gender,
    proposed_full_name, proposed_gender, proposed_birth_year, proposed_city,
    proposed_photo_url, proposed_phone_number, invite_code, status
  ) VALUES (
    p_group_id, v_caller_id, p_claimed_relative_id, p_anchor_relative_id,
    p_edge_path, p_parent_side, p_gender,
    NULLIF(trim(p_proposed_full_name), ''), p_proposed_gender, p_proposed_birth_year,
    NULLIF(trim(p_proposed_city), ''), NULLIF(trim(p_proposed_photo_url), ''),
    v_normalized_phone, p_invite_code, 'pending'
  )
  RETURNING id INTO v_claim_id;

  SELECT to_jsonb(nc.*) INTO v_claim FROM node_claims nc WHERE id = v_claim_id;

  -- Notify each admin of the group that a new claim is pending.
  FOR v_admin IN
    SELECT user_id FROM family_group_members
     WHERE group_id = p_group_id AND role = 'admin'
  LOOP
    PERFORM public._notify_claim_status(
      v_admin.user_id, p_group_id, 'claim_pending'
    );
  END LOOP;

  RETURN v_claim;
END;
$function$;
