-- Normalize family_groups.name storage to the bare form (no "عائلة " prefix).
--
-- The join-notification template `family_join_1` (migration 20260204130000)
-- renders 'انضم {{member_name}} إلى عائلة {{family_name}}' — the prefix is
-- already baked into the template. Earlier flows hinted users to type
-- "عائلة الأحمد", so some stored names already carry the prefix and the
-- substituted notification reads "... إلى عائلة عائلة الأحمد".
--
-- Going forward, the create-group flow normalizes input before insert
-- (normalizeFamilyGroupName) and display surfaces add the prefix with
-- formatFamilyGroupDisplayName. This migration brings existing rows in line.

UPDATE family_groups
SET name = trim(regexp_replace(name, '^(\s*عائلة\s+)+', '', 'g'))
WHERE name ~ '^\s*عائلة\s+';
