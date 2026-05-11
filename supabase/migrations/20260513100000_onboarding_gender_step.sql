-- 20260513100000_onboarding_gender_step.sql
-- Insert a mandatory "pick gender" step into the onboarding wizard.
-- Placed at screen_order = 2, so it runs right after confirm_name.
--
-- The shift is idempotent: it only runs when the confirm_gender row is
-- absent. To avoid colliding with UNIQUE(screen_order) AND the
-- CHECK(screen_order > 0) constraint, we park rows above the current max
-- (high offset) before re-numbering to their +1 shifted slots.

DO $$
DECLARE
  v_offset INTEGER;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM admin_onboarding_screens
    WHERE action_type = 'confirm_gender'
  ) THEN
    -- Pick a parking offset that's safely above any existing screen_order
    -- to keep both UNIQUE and CHECK (>0) happy during the two-phase shift.
    SELECT COALESCE(MAX(screen_order), 0) + 1000
      INTO v_offset
      FROM admin_onboarding_screens;

    -- Phase 1: park all rows with screen_order >= 2 at offset+order.
    UPDATE admin_onboarding_screens
       SET screen_order = screen_order + v_offset
     WHERE screen_order >= 2;

    -- Phase 2: re-number each parked row to its new (+1 shifted) slot.
    UPDATE admin_onboarding_screens
       SET screen_order = (screen_order - v_offset) + 1
     WHERE screen_order > v_offset;

    -- Phase 3: insert the new mandatory gender step at slot 2.
    INSERT INTO admin_onboarding_screens (
      screen_order, action_type, title_ar, title_en, subtitle_ar, subtitle_en,
      animation_name, background_color, text_color, button_text_ar, skip_enabled
    ) VALUES (
      2,
      'confirm_gender',
      'كيف نناديك؟',
      'How should we address you?',
      'اختر الجنس لنُخصِّص لك التذكيرات والروابط بشكل صحيح',
      'Pick gender so reminders and relations are correctly tailored',
      'onboarding_gender',
      '#FFFFFF', '#1F2937',
      'التالي',
      false  -- mandatory, no skip
    );
  END IF;
END $$;
