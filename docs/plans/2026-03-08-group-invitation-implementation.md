# Family Group & Phone-Based Invitation Redesign — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the silent, link-based group creation and invitation system with an explicit group creation flow and phone-number-verified invitation system.

**Architecture:** Phone OTP becomes the identity anchor for invitations. Admins invite specific nodes (which must have phone numbers). Invitees verify via OTP, see invitations in the notification center with a glowing bell. Public links remain as a fallback with phone auto-matching. Domain migrates from `silni-31811.web.app` to `silniapp.com`.

**Tech Stack:** Flutter (Riverpod), Supabase (Auth phone OTP, SECURITY DEFINER RPCs, RLS), Next.js (landing page on silniapp.com)

**Design Doc:** `docs/plans/2026-03-08-group-invitation-redesign.md`

---

## Phase 1: Database Foundation

### Task 1: Create `node_invitations` table migration

**Files:**
- Create: `supabase/migrations/20260308100000_node_invitations.sql`

**Step 1: Write the migration**

```sql
-- ============================================================
-- Node Invitations: Phone-number-based invitation system
-- ============================================================

-- Table
CREATE TABLE node_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  relative_id UUID NOT NULL REFERENCES relatives(id) ON DELETE CASCADE,
  phone_number TEXT NOT NULL,
  invited_by UUID NOT NULL REFERENCES auth.users(id),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'cancelled')),
  accepted_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  accepted_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ
);

-- Enable RLS
ALTER TABLE node_invitations ENABLE ROW LEVEL SECURITY;

-- Indexes
-- Fast lookup on login: "any pending invitations for this phone?"
CREATE INDEX idx_node_invitations_phone_status
  ON node_invitations(phone_number, status) WHERE status = 'pending';

-- One pending invite per node at a time
CREATE UNIQUE INDEX idx_node_invitations_unique_pending
  ON node_invitations(group_id, relative_id) WHERE status = 'pending';

-- Admin's invitation list per group
CREATE INDEX idx_node_invitations_group
  ON node_invitations(group_id, status);

-- Lookup by accepted user
CREATE INDEX idx_node_invitations_accepted_by
  ON node_invitations(accepted_by) WHERE accepted_by IS NOT NULL;

-- ============================================================
-- Helper: get inviter's group IDs (reuse existing)
-- ============================================================

-- RLS Policies
-- Admins can view all invitations for their groups
CREATE POLICY "node_invitations_select_admin"
  ON node_invitations FOR SELECT
  USING (group_id IN (SELECT auth_user_group_ids()));

-- Invitees can view their own pending invitations (matched by phone)
CREATE POLICY "node_invitations_select_invitee"
  ON node_invitations FOR SELECT
  USING (
    status = 'pending'
    AND phone_number = (
      SELECT phone FROM auth.users WHERE id = auth.uid()
    )
  );

-- Only admins can insert (enforced via RPC, but belt-and-suspenders)
CREATE POLICY "node_invitations_insert_admin"
  ON node_invitations FOR INSERT
  WITH CHECK (
    group_id IN (SELECT auth_user_admin_group_ids())
    AND invited_by = auth.uid()
  );

-- Updates only via RPCs (no direct client updates)
CREATE POLICY "node_invitations_update_deny"
  ON node_invitations FOR UPDATE
  USING (false);

-- Admins can delete cancelled invitations
CREATE POLICY "node_invitations_delete_admin"
  ON node_invitations FOR DELETE
  USING (
    group_id IN (SELECT auth_user_admin_group_ids())
    AND status = 'cancelled'
  );
```

**Step 2: Verify migration syntax**

Run: `cd /Users/engammar/Apps/silni_app && supabase db diff --local` (if local Supabase is running)
Or review manually for syntax errors.

**Step 3: Commit**

```bash
git add supabase/migrations/20260308100000_node_invitations.sql
git commit -m "feat: add node_invitations table for phone-based invitations"
```

---

### Task 2: Create invitation RPCs

**Files:**
- Create: `supabase/migrations/20260308100001_invitation_rpcs.sql`

**Step 1: Write the RPCs**

```sql
-- ============================================================
-- RPC: Create a node invitation (admin only)
-- ============================================================
CREATE OR REPLACE FUNCTION create_node_invitation(
  p_group_id UUID,
  p_relative_id UUID,
  p_phone TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role TEXT;
  v_relative RECORD;
  v_normalized_phone TEXT;
  v_invitation RECORD;
BEGIN
  -- 1. Validate caller is admin
  SELECT role INTO v_caller_role
  FROM family_group_members
  WHERE group_id = p_group_id AND user_id = auth.uid()
  FOR UPDATE;

  IF v_caller_role IS NULL THEN
    RAISE EXCEPTION 'Not a member of this group';
  END IF;

  IF v_caller_role != 'admin' THEN
    RAISE EXCEPTION 'Only admins can send invitations';
  END IF;

  -- 2. Validate relative belongs to group and has no pending invite
  SELECT id, family_group_id, full_name, phone_number
  INTO v_relative
  FROM relatives
  WHERE id = p_relative_id AND family_group_id = p_group_id
  FOR UPDATE;

  IF v_relative.id IS NULL THEN
    RAISE EXCEPTION 'Relative not found in this group';
  END IF;

  -- 3. Normalize phone number (strip spaces, ensure + prefix)
  v_normalized_phone := regexp_replace(trim(p_phone), '\s+', '', 'g');
  IF LEFT(v_normalized_phone, 1) != '+' THEN
    v_normalized_phone := '+' || v_normalized_phone;
  END IF;

  IF length(v_normalized_phone) < 8 OR length(v_normalized_phone) > 16 THEN
    RAISE EXCEPTION 'Invalid phone number format';
  END IF;

  -- 4. Check for existing pending invitation on this node
  IF EXISTS (
    SELECT 1 FROM node_invitations
    WHERE group_id = p_group_id
      AND relative_id = p_relative_id
      AND status = 'pending'
  ) THEN
    RAISE EXCEPTION 'This relative already has a pending invitation';
  END IF;

  -- 5. Check node isn't already claimed
  IF EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = p_group_id
      AND relative_id_in_tree = p_relative_id
  ) THEN
    RAISE EXCEPTION 'This relative is already claimed by a member';
  END IF;

  -- 6. Insert invitation
  INSERT INTO node_invitations (group_id, relative_id, phone_number, invited_by)
  VALUES (p_group_id, p_relative_id, v_normalized_phone, auth.uid())
  RETURNING * INTO v_invitation;

  RETURN jsonb_build_object(
    'id', v_invitation.id,
    'group_id', v_invitation.group_id,
    'relative_id', v_invitation.relative_id,
    'phone_number', v_invitation.phone_number,
    'status', v_invitation.status,
    'created_at', v_invitation.created_at
  );
END;
$$;

-- ============================================================
-- RPC: Accept a node invitation (invitee, phone-verified)
-- ============================================================
CREATE OR REPLACE FUNCTION accept_node_invitation(p_invitation_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invitation RECORD;
  v_caller_phone TEXT;
  v_group RECORD;
  v_membership_id UUID;
BEGIN
  -- 1. Get caller's verified phone
  SELECT phone INTO v_caller_phone
  FROM auth.users WHERE id = auth.uid();

  IF v_caller_phone IS NULL OR v_caller_phone = '' THEN
    RAISE EXCEPTION 'Phone number not verified. Please verify your phone first.';
  END IF;

  -- 2. Get invitation with lock
  SELECT * INTO v_invitation
  FROM node_invitations
  WHERE id = p_invitation_id
  FOR UPDATE;

  IF v_invitation.id IS NULL THEN
    RAISE EXCEPTION 'Invitation not found';
  END IF;

  IF v_invitation.status != 'pending' THEN
    RAISE EXCEPTION 'Invitation is no longer pending';
  END IF;

  -- 3. Validate phone match (normalize caller phone same way)
  IF regexp_replace(trim(v_caller_phone), '\s+', '', 'g')
     != regexp_replace(trim(v_invitation.phone_number), '\s+', '', 'g') THEN
    RAISE EXCEPTION 'Phone number does not match invitation';
  END IF;

  -- 4. Check node isn't already claimed (race condition guard)
  IF EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = v_invitation.group_id
      AND relative_id_in_tree = v_invitation.relative_id
  ) THEN
    RAISE EXCEPTION 'This node has already been claimed';
  END IF;

  -- 5. Add user to group if not already a member
  IF NOT EXISTS (
    SELECT 1 FROM family_group_members
    WHERE group_id = v_invitation.group_id AND user_id = auth.uid()
  ) THEN
    INSERT INTO family_group_members (group_id, user_id, role, relative_id_in_tree)
    VALUES (v_invitation.group_id, auth.uid(), 'member', v_invitation.relative_id);
  ELSE
    -- Already a member, just link the node
    UPDATE family_group_members
    SET relative_id_in_tree = v_invitation.relative_id
    WHERE group_id = v_invitation.group_id AND user_id = auth.uid();
  END IF;

  -- 6. Claim the node
  UPDATE relatives
  SET is_self = true, user_id = auth.uid()
  WHERE id = v_invitation.relative_id;

  -- 7. Update invitation status
  UPDATE node_invitations
  SET status = 'accepted',
      accepted_by = auth.uid(),
      accepted_at = now()
  WHERE id = p_invitation_id;

  -- 8. Return group info
  SELECT * INTO v_group
  FROM family_groups
  WHERE id = v_invitation.group_id;

  RETURN jsonb_build_object(
    'group_id', v_group.id,
    'group_name', v_group.name,
    'relative_id', v_invitation.relative_id
  );
END;
$$;

-- ============================================================
-- RPC: Cancel a node invitation (admin only)
-- ============================================================
CREATE OR REPLACE FUNCTION cancel_node_invitation(p_invitation_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invitation RECORD;
  v_caller_role TEXT;
BEGIN
  SELECT * INTO v_invitation
  FROM node_invitations WHERE id = p_invitation_id FOR UPDATE;

  IF v_invitation.id IS NULL THEN
    RAISE EXCEPTION 'Invitation not found';
  END IF;

  SELECT role INTO v_caller_role
  FROM family_group_members
  WHERE group_id = v_invitation.group_id AND user_id = auth.uid();

  IF v_caller_role != 'admin' THEN
    RAISE EXCEPTION 'Only admins can cancel invitations';
  END IF;

  UPDATE node_invitations
  SET status = 'cancelled', cancelled_at = now()
  WHERE id = p_invitation_id;
END;
$$;

-- ============================================================
-- RPC: Get pending invitations for current user's phone
-- ============================================================
CREATE OR REPLACE FUNCTION get_my_pending_invitations()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_phone TEXT;
  v_result JSONB;
BEGIN
  SELECT phone INTO v_phone FROM auth.users WHERE id = auth.uid();

  IF v_phone IS NULL OR v_phone = '' THEN
    RETURN '[]'::jsonb;
  END IF;

  SELECT COALESCE(jsonb_agg(row_to_json(inv)), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT
      ni.id,
      ni.group_id,
      ni.relative_id,
      ni.status,
      ni.created_at,
      fg.name AS group_name,
      r.full_name AS relative_name,
      r.relationship_type,
      inv_user.raw_user_meta_data->>'full_name' AS invited_by_name
    FROM node_invitations ni
    JOIN family_groups fg ON fg.id = ni.group_id
    JOIN relatives r ON r.id = ni.relative_id
    JOIN auth.users inv_user ON inv_user.id = ni.invited_by
    WHERE ni.phone_number = regexp_replace(trim(v_phone), '\s+', '', 'g')
      AND ni.status = 'pending'
    ORDER BY ni.created_at DESC
  ) inv;

  RETURN v_result;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION create_node_invitation TO authenticated;
GRANT EXECUTE ON FUNCTION accept_node_invitation TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_node_invitation TO authenticated;
GRANT EXECUTE ON FUNCTION get_my_pending_invitations TO authenticated;
```

**Step 2: Commit**

```bash
git add supabase/migrations/20260308100001_invitation_rpcs.sql
git commit -m "feat: add SECURITY DEFINER RPCs for node invitation lifecycle"
```

---

## Phase 2: Phone OTP Authentication

### Task 3: Add phone OTP methods to AuthService

**Files:**
- Modify: `lib/shared/services/auth_service.dart`

**Step 1: Write unit test for phone normalization**

```dart
// test/unit/services/auth_service_phone_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/shared/services/auth_service.dart';

void main() {
  group('Phone normalization', () {
    test('adds + prefix if missing', () {
      expect(AuthService.normalizePhone('966512345678'), '+966512345678');
    });

    test('keeps + prefix if present', () {
      expect(AuthService.normalizePhone('+966512345678'), '+966512345678');
    });

    test('strips spaces', () {
      expect(AuthService.normalizePhone('+966 51 234 5678'), '+966512345678');
    });

    test('strips dashes', () {
      expect(AuthService.normalizePhone('+966-51-234-5678'), '+966512345678');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/services/auth_service_phone_test.dart`
Expected: FAIL — `normalizePhone` method not defined

**Step 3: Add phone methods to AuthService**

Add to `lib/shared/services/auth_service.dart`:

```dart
/// Normalize phone number: strip spaces/dashes, ensure + prefix
static String normalizePhone(String phone) {
  var normalized = phone.replaceAll(RegExp(r'[\s\-()]'), '');
  if (!normalized.startsWith('+')) {
    normalized = '+$normalized';
  }
  return normalized;
}

/// Send OTP to phone number for verification
Future<void> sendPhoneOtp(String phone) async {
  final normalized = normalizePhone(phone);
  await _supabase.auth.signInWithOtp(phone: normalized);
}

/// Verify phone OTP code
Future<AuthResponse> verifyPhoneOtp({
  required String phone,
  required String token,
}) async {
  final normalized = normalizePhone(phone);
  return await _supabase.auth.verifyOTP(
    phone: normalized,
    token: token,
    type: OtpType.sms,
  );
}

/// Update current user's phone (sends OTP for verification)
Future<void> updateUserPhone(String phone) async {
  final normalized = normalizePhone(phone);
  await _supabase.auth.updateUser(
    UserAttributes(phone: normalized),
  );
}

/// Verify phone update OTP
Future<UserResponse> verifyPhoneUpdate({
  required String phone,
  required String token,
}) async {
  final normalized = normalizePhone(phone);
  return await _supabase.auth.verifyOTP(
    phone: normalized,
    token: token,
    type: OtpType.phoneChange,
  );
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/services/auth_service_phone_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/shared/services/auth_service.dart test/unit/services/auth_service_phone_test.dart
git commit -m "feat: add phone OTP methods to AuthService"
```

---

### Task 4: Create phone verification screen

**Files:**
- Create: `lib/features/auth/screens/phone_verification_screen.dart`
- Modify: `lib/core/router/app_routes.dart` (add route)
- Modify: `lib/core/router/app_router.dart` (add GoRoute)

**Step 1: Add route constant**

In `lib/core/router/app_routes.dart`, add:

```dart
static const String phoneVerification = '/phone-verification';
```

**Step 2: Create the phone verification screen**

Create `lib/features/auth/screens/phone_verification_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:silni_app/core/theme/app_colors.dart';
import 'package:silni_app/core/theme/app_spacing.dart';
import 'package:silni_app/features/auth/providers/auth_provider.dart';
import 'package:silni_app/shared/services/auth_service.dart';
import 'package:silni_app/shared/utils/ui_helpers.dart';

/// Screen for verifying a phone number via OTP.
/// Used during profile setup or when accepting an invitation.
class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final String? returnRoute;

  const PhoneVerificationScreen({super.key, this.returnRoute});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateUserPhone(phone);
      setState(() => _otpSent = true);
      if (mounted) {
        UIHelpers.showSnackBar(context, 'تم إرسال رمز التحقق');
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(context, 'حدث خطأ: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneController.text.trim();
    final token = _otpController.text.trim();
    if (phone.isEmpty || token.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyPhoneUpdate(phone: phone, token: token);
      HapticFeedback.heavyImpact();
      if (mounted) {
        UIHelpers.showSnackBar(context, 'تم تأكيد رقم الجوال بنجاح');
        if (widget.returnRoute != null) {
          context.go(widget.returnRoute!);
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'رمز التحقق غير صحيح',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تأكيد رقم الجوال'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'أدخل رقم جوالك للتحقق من هويتك',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              // Phone input
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_otpSent,
                  decoration: const InputDecoration(
                    labelText: 'رقم الجوال',
                    hintText: '+966 5XX XXX XXXX',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                ),
              ),
              if (!_otpSent) ...[
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إرسال رمز التحقق'),
                ),
              ],
              if (_otpSent) ...[
                const SizedBox(height: AppSpacing.lg),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'رمز التحقق',
                      hintText: '------',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('تأكيد'),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: const Text('إعادة إرسال الرمز'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 3: Add GoRoute in app_router.dart**

In `lib/core/router/app_router.dart`, add a GoRoute for the new screen (inside the routes list, near other auth routes):

```dart
GoRoute(
  path: AppRoutes.phoneVerification,
  builder: (context, state) {
    final returnRoute = state.uri.queryParameters['return'];
    return PhoneVerificationScreen(returnRoute: returnRoute);
  },
),
```

**Step 4: Commit**

```bash
git add lib/features/auth/screens/phone_verification_screen.dart lib/core/router/app_routes.dart lib/core/router/app_router.dart
git commit -m "feat: add phone verification screen with OTP flow"
```

---

## Phase 3: Invitation Service & Model

### Task 5: Create NodeInvitation model

**Files:**
- Create: `lib/features/family_groups/models/node_invitation_model.dart`

**Step 1: Write the model**

```dart
class NodeInvitation {
  final String id;
  final String groupId;
  final String relativeId;
  final String phoneNumber;
  final String invitedBy;
  final String status; // pending, accepted, cancelled
  final String? acceptedBy;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? cancelledAt;

  // Joined fields (from get_my_pending_invitations RPC)
  final String? groupName;
  final String? relativeName;
  final String? relationshipType;
  final String? invitedByName;

  const NodeInvitation({
    required this.id,
    required this.groupId,
    required this.relativeId,
    required this.phoneNumber,
    required this.invitedBy,
    required this.status,
    this.acceptedBy,
    required this.createdAt,
    this.acceptedAt,
    this.cancelledAt,
    this.groupName,
    this.relativeName,
    this.relationshipType,
    this.invitedByName,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCancelled => status == 'cancelled';

  /// Masked phone for display: +966 5** *** *234
  String get maskedPhone {
    if (phoneNumber.length < 8) return phoneNumber;
    final prefix = phoneNumber.substring(0, 4);
    final suffix = phoneNumber.substring(phoneNumber.length - 4);
    final middleLength = phoneNumber.length - 8;
    final masked = '*' * middleLength;
    return '$prefix $masked $suffix';
  }

  factory NodeInvitation.fromJson(Map<String, dynamic> json) {
    return NodeInvitation(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      relativeId: json['relative_id'] as String,
      phoneNumber: json['phone_number'] as String,
      invitedBy: json['invited_by'] as String,
      status: json['status'] as String,
      acceptedBy: json['accepted_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      groupName: json['group_name'] as String?,
      relativeName: json['relative_name'] as String?,
      relationshipType: json['relationship_type'] as String?,
      invitedByName: json['invited_by_name'] as String?,
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/family_groups/models/node_invitation_model.dart
git commit -m "feat: add NodeInvitation model"
```

---

### Task 6: Create NodeInvitationService

**Files:**
- Create: `lib/features/family_groups/services/node_invitation_service.dart`
- Create: `test/unit/services/node_invitation_service_test.dart`

**Step 1: Write test for phone masking (pure logic)**

```dart
// test/unit/models/node_invitation_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:silni_app/features/family_groups/models/node_invitation_model.dart';

void main() {
  group('NodeInvitation.maskedPhone', () {
    test('masks middle digits of a standard phone', () {
      final inv = NodeInvitation(
        id: '1', groupId: '1', relativeId: '1',
        phoneNumber: '+966512345678', invitedBy: '1',
        status: 'pending', createdAt: DateTime.now(),
      );
      expect(inv.maskedPhone, '+966 **** 5678');
    });

    test('handles short phone gracefully', () {
      final inv = NodeInvitation(
        id: '1', groupId: '1', relativeId: '1',
        phoneNumber: '+96651', invitedBy: '1',
        status: 'pending', createdAt: DateTime.now(),
      );
      // Short phone returned as-is
      expect(inv.maskedPhone, '+96651');
    });
  });
}
```

**Step 2: Run test to verify it passes** (model already written in Task 5)

Run: `flutter test test/unit/models/node_invitation_model_test.dart`

**Step 3: Write the service**

```dart
// lib/features/family_groups/services/node_invitation_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:silni_app/core/config/supabase_config.dart';
import 'package:silni_app/features/family_groups/models/node_invitation_model.dart';

final nodeInvitationServiceProvider = Provider<NodeInvitationService>(
  (ref) => NodeInvitationService(),
);

class NodeInvitationService {
  SupabaseClient get _supabase => SupabaseConfig.client;

  /// Create an invitation for a specific node (admin only)
  Future<NodeInvitation> createInvitation({
    required String groupId,
    required String relativeId,
    required String phoneNumber,
  }) async {
    final result = await _supabase.rpc('create_node_invitation', params: {
      'p_group_id': groupId,
      'p_relative_id': relativeId,
      'p_phone': phoneNumber,
    });

    return NodeInvitation.fromJson(result as Map<String, dynamic>);
  }

  /// Accept a pending invitation (invitee)
  Future<Map<String, dynamic>> acceptInvitation(String invitationId) async {
    final result = await _supabase.rpc('accept_node_invitation', params: {
      'p_invitation_id': invitationId,
    });

    return result as Map<String, dynamic>;
  }

  /// Cancel a pending invitation (admin)
  Future<void> cancelInvitation(String invitationId) async {
    await _supabase.rpc('cancel_node_invitation', params: {
      'p_invitation_id': invitationId,
    });
  }

  /// Get pending invitations for current user's verified phone
  Future<List<NodeInvitation>> getMyPendingInvitations() async {
    final result = await _supabase.rpc('get_my_pending_invitations');

    final list = result as List<dynamic>;
    return list
        .map((e) => NodeInvitation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get all invitations for a group (admin view)
  Future<List<NodeInvitation>> getGroupInvitations(String groupId) async {
    final result = await _supabase
        .from('node_invitations')
        .select('*, relatives!inner(full_name, relationship_type)')
        .eq('group_id', groupId)
        .order('created_at', ascending: false);

    return (result as List<dynamic>).map((e) {
      final json = e as Map<String, dynamic>;
      final relative = json['relatives'] as Map<String, dynamic>?;
      return NodeInvitation.fromJson({
        ...json,
        'relative_name': relative?['full_name'],
        'relationship_type': relative?['relationship_type'],
      });
    }).toList();
  }

  /// Get invitation status for a specific relative
  Future<NodeInvitation?> getInvitationForRelative({
    required String groupId,
    required String relativeId,
  }) async {
    final result = await _supabase
        .from('node_invitations')
        .select()
        .eq('group_id', groupId)
        .eq('relative_id', relativeId)
        .eq('status', 'pending')
        .maybeSingle();

    if (result == null) return null;
    return NodeInvitation.fromJson(result);
  }

  /// Stream of invitation count for badge (pending invitations for user)
  Stream<int> pendingInvitationCountStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value(0);

    final phone = _supabase.auth.currentUser?.phone;
    if (phone == null || phone.isEmpty) return Stream.value(0);

    return _supabase
        .from('node_invitations')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .map((rows) => rows
            .where((r) => r['phone_number'] == phone && r['status'] == 'pending')
            .length);
  }
}
```

**Step 4: Commit**

```bash
git add lib/features/family_groups/services/node_invitation_service.dart test/unit/models/node_invitation_model_test.dart
git commit -m "feat: add NodeInvitationService with RPC wrappers"
```

---

### Task 7: Create invitation Riverpod providers

**Files:**
- Create: `lib/features/family_groups/providers/node_invitation_providers.dart`

**Step 1: Write the providers**

```dart
// lib/features/family_groups/providers/node_invitation_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silni_app/features/family_groups/models/node_invitation_model.dart';
import 'package:silni_app/features/family_groups/services/node_invitation_service.dart';

/// Pending invitations for the current user (matched by phone)
final myPendingInvitationsProvider =
    FutureProvider<List<NodeInvitation>>((ref) async {
  final service = ref.read(nodeInvitationServiceProvider);
  return service.getMyPendingInvitations();
});

/// All invitations for a specific group (admin view)
final groupInvitationsProvider =
    FutureProvider.family<List<NodeInvitation>, String>((ref, groupId) async {
  final service = ref.read(nodeInvitationServiceProvider);
  return service.getGroupInvitations(groupId);
});

/// Invitation status for a specific relative node
final relativeInvitationProvider = FutureProvider.family<NodeInvitation?,
    ({String groupId, String relativeId})>((ref, params) async {
  final service = ref.read(nodeInvitationServiceProvider);
  return service.getInvitationForRelative(
    groupId: params.groupId,
    relativeId: params.relativeId,
  );
});

/// Count of pending invitations (for bell badge)
final pendingInvitationCountProvider = StreamProvider<int>((ref) {
  final service = ref.read(nodeInvitationServiceProvider);
  return service.pendingInvitationCountStream();
});
```

**Step 2: Commit**

```bash
git add lib/features/family_groups/providers/node_invitation_providers.dart
git commit -m "feat: add Riverpod providers for node invitations"
```

---

## Phase 4: Explicit Group Creation

### Task 8: Add "Share your tree" CTA to family tree screen

**Files:**
- Modify: `lib/features/family_tree/screens/family_tree_screen.dart`

**Step 1: Add the CTA widget**

In `family_tree_screen.dart`, find the section where the tree content is built (inside the body Column). When `groupInfoAsync` returns null (no group), add a banner card between the header and tree canvas.

Locate the build method area where `groupInfo` is checked. Add a helper method:

```dart
Widget _buildShareTreeBanner() {
  return Container(
    margin: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.calmBlue.withValues(alpha: 0.15),
          AppColors.premiumGold.withValues(alpha: 0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.calmBlue.withValues(alpha: 0.3),
      ),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.family_restroom_rounded,
          size: 32,
          color: AppColors.calmBlue,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'شارك شجرتك مع أفراد عائلتك',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'أنشئ مجموعة عائلية ليتمكن أفراد عائلتك من رؤية الشجرة والمشاركة فيها',
          style: TextStyle(fontSize: 13, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.createFamilyGroup),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إنشاء مجموعة عائلية'),
          ),
        ),
      ],
    ),
  );
}
```

Insert this widget conditionally when `groupInfo == null` and the user has at least 1 relative.

**Step 2: Remove silent group creation from relative detail screen**

In `lib/features/relatives/screens/relative_detail_screen.dart`, modify the `_inviteRelative()` method (lines 264-316):

Replace the auto-creation block:
```dart
// OLD: if (group == null) { group = await FamilySharingService.initializeSharedTree(...); }
// NEW: if (group == null) { show prompt to create group first; return; }
```

```dart
Future<void> _inviteRelative(Relative relative) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  setState(() => _isInviting = true);
  try {
    final group = await FamilySharingService.getUserGroup(user.id);

    if (group == null) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'أنشئ مجموعة عائلية أولاً من شاشة شجرة العائلة',
        );
      }
      return;
    }

    // Check if relative has a phone number (phone gate)
    if (relative.phoneNumber == null || relative.phoneNumber!.isEmpty) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'أضف رقم جوال ${relative.fullName} أولاً لإرسال الدعوة',
          isError: true,
        );
      }
      return;
    }

    // Create invitation via service
    final invitationService = ref.read(nodeInvitationServiceProvider);
    await invitationService.createInvitation(
      groupId: group.id,
      relativeId: relative.id,
      phoneNumber: relative.phoneNumber!,
    );

    // Share nudge link
    final box = context.findRenderObject() as RenderBox?;
    final shareOrigin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;

    await Share.share(
      'أضفتك في شجرة عائلتنا على صِلني 🌳\nحمّل التطبيق: https://silniapp.com/download',
      sharePositionOrigin: shareOrigin,
    );

    // Invalidate invitation providers
    ref.invalidate(groupInvitationsProvider);
  } catch (e) {
    if (mounted) {
      UIHelpers.showSnackBar(
        context,
        'حدث خطأ أثناء إنشاء الدعوة: $e',
        isError: true,
      );
    }
  } finally {
    if (mounted) setState(() => _isInviting = false);
  }
}
```

**Step 3: Commit**

```bash
git add lib/features/family_tree/screens/family_tree_screen.dart lib/features/relatives/screens/relative_detail_screen.dart
git commit -m "feat: add explicit group creation CTA, remove silent group creation, add phone gate for invites"
```

---

### Task 9: Update CreateGroupScreen with 3-step flow

**Files:**
- Modify: `lib/features/family_groups/screens/create_group_screen.dart`

**Step 1: Rewrite the screen with the 3-step flow**

The screen should have 3 states:
1. **Name step**: Text field for group name
2. **Review step**: Show all relatives that will be migrated, with count and names
3. **Done step**: Success + "Invite family members" CTA

Key changes from current implementation:
- Step 2 fetches relatives via `relativesStreamProvider` and displays them
- Step 3 calls `FamilySharingService.initializeSharedTree()` (same as before, but now user confirmed)
- Done state navigates to group management instead of showing InviteLinkCard

This is a full rewrite of the screen. The implementation engineer should:
1. Read the current screen fully (`lib/features/family_groups/screens/create_group_screen.dart`, 287 lines)
2. Keep the same `initializeSharedTree()` call from the current `_createGroup()` method
3. Replace the single-form UI with a `PageView` or stepper with 3 steps
4. Use existing `GlassCard` and `GradientButton` patterns

**Step 2: Commit**

```bash
git add lib/features/family_groups/screens/create_group_screen.dart
git commit -m "feat: rewrite CreateGroupScreen with 3-step explicit flow"
```

---

## Phase 5: Notification Center Enhancements

### Task 10: Add invitation notification type and glowing bell

**Files:**
- Modify: `lib/shared/models/notification_history_model.dart` (add 'invitation' type)
- Modify: `lib/features/home/widgets/home_header_widget.dart` (glowing bell)
- Modify: `lib/features/notifications/screens/notification_history_screen.dart` (invitation cards)

**Step 1: Add invitation type to notification model**

In `lib/shared/models/notification_history_model.dart`, add to the type mapping:

```dart
// Add to typeLabel getter:
case 'invitation':
  return 'دعوة عائلية';

// Add to typeIcon getter:
case 'invitation':
  return '🌳';
```

**Step 2: Add glowing bell animation to home header**

In `lib/features/home/widgets/home_header_widget.dart`, modify the bell icon section:

1. Watch `pendingInvitationCountProvider` alongside `unreadNotificationCountProvider`
2. When there are pending invitations, wrap the bell icon in an animated glow:

```dart
// Add this as a method in the widget
Widget _buildGlowingBell({required bool hasInvitation, required Widget child}) {
  if (!hasInvitation) return child;

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: const Duration(milliseconds: 1500),
    builder: (context, value, child) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.premiumGold.withValues(
                alpha: 0.4 + (0.3 * (0.5 + 0.5 * sin(value * 2 * pi))),
              ),
              blurRadius: 12 + (6 * sin(value * 2 * pi)),
              spreadRadius: 2 + (2 * sin(value * 2 * pi)),
            ),
          ],
        ),
        child: child,
      );
    },
    child: child,
  );
}
```

Note: Use `dart:math` for `sin` and `pi`. The animation should repeat, so use a custom `AnimationController` with `repeat()` instead of `TweenAnimationBuilder` for continuous animation.

**Step 3: Add invitation card handling in notification history**

In `lib/features/notifications/screens/notification_history_screen.dart`, add navigation for invitation type:

```dart
// In the onTap handler for notification cards:
case 'invitation':
  // Navigate to invitation detail screen
  final invitationId = notification.data?['invitation_id'] as String?;
  if (invitationId != null) {
    context.push('${AppRoutes.invitationDetail}/$invitationId');
  }
  break;
```

**Step 4: Commit**

```bash
git add lib/shared/models/notification_history_model.dart lib/features/home/widgets/home_header_widget.dart lib/features/notifications/screens/notification_history_screen.dart
git commit -m "feat: add invitation notification type with glowing bell animation"
```

---

## Phase 6: Invitation Detail Screen

### Task 11: Create invitation detail screen

**Files:**
- Create: `lib/features/family_groups/screens/invitation_detail_screen.dart`
- Modify: `lib/core/router/app_routes.dart` (add route)
- Modify: `lib/core/router/app_router.dart` (add GoRoute)

**Step 1: Add route**

In `app_routes.dart`:
```dart
static const String invitationDetail = '/invitation';
```

**Step 2: Create the screen**

`lib/features/family_groups/screens/invitation_detail_screen.dart`:

This screen should show:
1. Group name with family icon
2. "ستنضم كـ **[relative name] ([relationship])**"
3. A mini visual tree preview (optional — can use a simplified version of the tree renderer showing just the node and its immediate connections)
4. Inviter name: "دعاك [name]"
5. "قبول" (Accept) button — calls `acceptInvitation()` RPC
6. "رفض" (Decline) button — just dismisses (or cancels from invitee side)

After accepting:
- Invalidate relevant providers (family group, relatives, edges, invitations)
- Navigate to `/family-tree`
- Show success snackbar

The engineer should:
1. Reference `JoinGroupScreen` for patterns (provider invalidation, navigation)
2. Reference `CreateGroupScreen` for visual styling (glass cards, gradient buttons)
3. Call `FamilySharingService.verifySharedEdges()` after accepting (same as current join flow)

**Step 3: Add GoRoute**

```dart
GoRoute(
  path: '${AppRoutes.invitationDetail}/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return InvitationDetailScreen(invitationId: id);
  },
),
```

**Step 4: Commit**

```bash
git add lib/features/family_groups/screens/invitation_detail_screen.dart lib/core/router/app_routes.dart lib/core/router/app_router.dart
git commit -m "feat: add invitation detail screen with accept/decline flow"
```

---

## Phase 7: Invitation Management (Admin)

### Task 12: Add invitation status badge to relative detail screen

**Files:**
- Modify: `lib/features/relatives/screens/relative_detail_screen.dart`

**Step 1: Add status badge**

Below the invite button (or replacing it when invitation exists), show the status:

```dart
Widget _buildInvitationBadge(NodeInvitation? invitation) {
  if (invitation == null) return const SizedBox.shrink();

  final Color badgeColor;
  final String label;
  final IconData icon;

  switch (invitation.status) {
    case 'pending':
      badgeColor = AppColors.premiumGold;
      label = 'دعوة معلقة';
      icon = Icons.hourglass_top_rounded;
    case 'accepted':
      badgeColor = AppColors.calmBlue;
      label = 'انضم للمجموعة';
      icon = Icons.check_circle_rounded;
    default:
      return const SizedBox.shrink();
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: badgeColor.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: badgeColor),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: badgeColor, fontSize: 13)),
      ],
    ),
  );
}
```

Watch `relativeInvitationProvider` to get the current invitation status for the relative.

**Step 2: Modify invite button visibility**

- If invitation is pending → show badge + "resend" option, hide invite button
- If invitation is accepted → show "joined" badge, hide invite button
- If no invitation → show invite button (with phone gate)

**Step 3: Commit**

```bash
git add lib/features/relatives/screens/relative_detail_screen.dart
git commit -m "feat: add invitation status badge to relative detail screen"
```

---

### Task 13: Add "Invitations" tab to group management screen

**Files:**
- Modify: `lib/features/family_groups/screens/family_group_screen.dart`

**Step 1: Add invitations section**

Add a new section to `FamilyGroupScreen` between the members list and the leave/delete buttons. This section shows:

1. Section header: "الدعوات" (Invitations) with count badge
2. List of invitations from `groupInvitationsProvider(group.id)`
3. Each card shows:
   - Relative name + relationship type
   - Phone hint (last 4 digits): `••• •••• ${phone.substring(phone.length - 4)}`
   - Status chip (pending / accepted / cancelled)
   - Date sent
   - Actions: "إعادة إرسال" (resend nudge) and "إلغاء" (cancel) for pending invitations

The engineer should:
1. Read the current `FamilyGroupScreen` fully (811 lines)
2. Follow the existing `SliverList` pattern used for the members list
3. Use `GlassCard` for each invitation item
4. Cancel action calls `NodeInvitationService.cancelInvitation()`
5. Resend action opens the share sheet with the download nudge message

**Step 2: Commit**

```bash
git add lib/features/family_groups/screens/family_group_screen.dart
git commit -m "feat: add invitations management tab to group screen"
```

---

## Phase 8: Public Link Flow

### Task 14: Simplify JoinGroupScreen for public links

**Files:**
- Modify: `lib/features/family_groups/screens/join_group_screen.dart`

**Step 1: Remove `?rid=` handling**

The `JoinGroupScreen` should be simplified:
1. Remove all `targetRelativeId` / `rid` parameter handling
2. Remove node claiming logic from this screen
3. After joining via public link:
   - Check if user's verified phone matches any `node_invitations` → if yes, auto-trigger the invitation accept flow
   - If no match → join as unlinked member
4. Keep the existing group lookup, auth check, and already-member detection

The engineer should:
1. Read the current `JoinGroupScreen` fully
2. Remove lines related to `widget.targetRelativeId`, UUID validation, rid parameter
3. After successful `joinGroup()` call, check for phone-matched invitations
4. Navigate to family tree on success

**Step 2: Update `FamilyGroupService.joinGroup()` to not auto-claim**

In `lib/features/family_groups/services/family_group_service.dart`:
- Remove the `relativeIdInTree` parameter from `joinGroup()`
- Remove auto-match-by-name logic
- Remove `_createJoinerSelfNode()` — unlinked members stay unlinked
- Keep the RPC call to `join_group_by_invite_code()` for membership insertion
- Keep `verifySharedEdges()` call

**Step 3: Commit**

```bash
git add lib/features/family_groups/screens/join_group_screen.dart lib/features/family_groups/services/family_group_service.dart
git commit -m "feat: simplify join flow — remove rid handling, unlinked members stay unlinked"
```

---

## Phase 9: Domain Migration

### Task 15: Replace `silni-31811.web.app` with `silniapp.com`

**Files:**
- Modify: `lib/features/family_groups/services/family_group_service.dart:51`
- Modify: `lib/core/router/app_router.dart:67,76`
- Modify: `android/app/src/main/AndroidManifest.xml:47`
- Modify: `ios/Runner/Runner.entitlements:19`
- Modify: `ios/Runner/RunnerRelease.entitlements:19`
- Modify: `test/unit/services/family_sharing_service_test.dart:213`
- Modify: `test/unit/services/family_group_service_test.dart:247,252,257`

**Step 1: Update the domain constant**

In `lib/features/family_groups/services/family_group_service.dart`:
```dart
// OLD: static const webDomain = 'silni-31811.web.app';
static const webDomain = 'silniapp.com';
```

**Step 2: Update deep link parsing in router**

In `lib/core/router/app_router.dart`:
```dart
// OLD: if (fullLocation.startsWith('https://silni-31811.web.app/')) {
if (fullLocation.startsWith('https://silniapp.com/')) {
```

Update comment too:
```dart
// HTTPS link: https://silniapp.com/join/CODE → /join/CODE
```

**Step 3: Update Android manifest**

In `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- OLD: <data android:scheme="https" android:host="silni-31811.web.app" android:pathPrefix="/join/" /> -->
<data android:scheme="https" android:host="silniapp.com" android:pathPrefix="/join/" />
```

**Step 4: Update iOS entitlements**

In both `ios/Runner/Runner.entitlements` and `ios/Runner/RunnerRelease.entitlements`:
```xml
<!-- OLD: <string>applinks:silni-31811.web.app</string> -->
<string>applinks:silniapp.com</string>
```

**Step 5: Update tests**

In test files, replace all `silni-31811.web.app` with `silniapp.com`.

**Step 6: Commit**

```bash
git add lib/features/family_groups/services/family_group_service.dart lib/core/router/app_router.dart android/app/src/main/AndroidManifest.xml ios/Runner/Runner.entitlements ios/Runner/RunnerRelease.entitlements test/unit/services/family_sharing_service_test.dart test/unit/services/family_group_service_test.dart
git commit -m "feat: migrate deep link domain from silni-31811.web.app to silniapp.com"
```

---

### Task 16: Create `/join/{code}` and `/download` pages on silniapp.com

**Files:**
- Create: `silni-landing/app/join/[code]/page.tsx`
- Create: `silni-landing/app/download/page.tsx`
- Modify: `web/.well-known/apple-app-site-association` (update domain references)

**Step 1: Create join landing page**

`silni-landing/app/join/[code]/page.tsx`:

This should be a Next.js page that:
1. Extracts the invite code from the URL
2. Shows a branded landing page with:
   - Silni logo
   - "You've been invited to join a family group"
   - "Open in App" button (deep link: `com.silni.app://join/{code}`)
   - App Store / Play Store badges as fallback
3. Includes smart app banners for iOS

The engineer should:
1. Read the existing `silni-landing/app/layout.tsx` for layout patterns
2. Read the existing `web/join.html` for the current deep link logic (extract the JavaScript)
3. Port the deep link logic into the React component
4. Use the existing design tokens from the landing site

**Step 2: Create download redirect page**

`silni-landing/app/download/page.tsx`:

Simple page that:
1. Detects platform (iOS/Android/Web)
2. Redirects to appropriate store
3. Shows branded fallback with both store badges

**Step 3: Update `.well-known` files**

Ensure `apple-app-site-association` and `assetlinks.json` are served from `silniapp.com` (may need Vercel config or static file placement in `silni-landing/public/.well-known/`).

**Step 4: Commit**

```bash
git add silni-landing/app/join/ silni-landing/app/download/ web/.well-known/
git commit -m "feat: add join and download landing pages on silniapp.com"
```

---

## Phase 10: Cleanup

### Task 17: Remove deprecated code

**Files:**
- Modify: `lib/features/family_groups/services/family_sharing_service.dart` (remove `generateInviteLink()`)
- Modify: `lib/features/family_groups/services/family_group_service.dart` (remove auto-match, `_createJoinerSelfNode()`)
- Modify: `lib/features/relatives/screens/relative_detail_screen.dart` (verify old invite code is fully removed)
- Delete or modify: `test/unit/services/family_sharing_service_test.dart` (update tests for removed `generateInviteLink`)
- Delete or modify: `test/unit/services/family_group_service_test.dart` (update tests for removed auto-match)

**Step 1: Remove `generateInviteLink` from FamilySharingService**

In `lib/features/family_groups/services/family_sharing_service.dart` (lines 446-451):
```dart
// DELETE this method entirely — no more per-node invite links
// static String generateInviteLink({...})
```

**Step 2: Remove `_createJoinerSelfNode` from FamilyGroupService**

In `lib/features/family_groups/services/family_group_service.dart` (lines 229-261):
```dart
// DELETE this method — unlinked members stay unlinked
```

Also remove the auto-match-by-name logic from `joinGroup()` (the section that queries by `ilike('full_name', ...)`)

**Step 3: Update tests**

Remove or update test cases that reference removed methods.

**Step 4: Run all tests**

Run: `flutter test test/unit/`
Expected: All tests pass

**Step 5: Commit**

```bash
git add -A
git commit -m "chore: remove deprecated invite link generation and auto-match logic"
```

---

### Task 18: Check pending invitations on app startup

**Files:**
- Modify: `lib/main.dart` or `lib/core/services/session_initialization_service.dart`

**Step 1: Add invitation check on login/startup**

After user authentication is confirmed, call `get_my_pending_invitations()` and if there are results, create a notification in `notification_history` table for each one (if not already notified).

The engineer should:
1. Find where session initialization happens (likely `session_initialization_service.dart`)
2. After auth state confirms logged-in user with verified phone:
   - Call `NodeInvitationService.getMyPendingInvitations()`
   - For each pending invitation, check if notification already exists in `notification_history`
   - If not, insert a notification record with type `'invitation'` and data containing `invitation_id`
3. This triggers the glowing bell animation via the existing notification count provider

**Step 2: Commit**

```bash
git add lib/core/services/session_initialization_service.dart
git commit -m "feat: check for pending invitations on app startup"
```

---

## Phase 11: Integration Testing

### Task 19: Write integration test for full invitation flow

**Files:**
- Create: `test/unit/services/node_invitation_service_test.dart`

**Step 1: Write tests for pure logic**

Test the `NodeInvitation` model, phone masking, and status helpers. For service methods that call Supabase RPCs, write integration tests that can run against a local Supabase instance or mock the client.

Key test scenarios:
1. Model: `fromJson` parsing, `maskedPhone`, status getters
2. Service: `createInvitation` → `getGroupInvitations` → `cancelInvitation` flow
3. Service: `createInvitation` → `acceptInvitation` → node claimed
4. Service: `getMyPendingInvitations` returns matches for phone
5. Edge case: duplicate invitation on same node (should fail)
6. Edge case: accepting with wrong phone (should fail)

**Step 2: Commit**

```bash
git add test/unit/services/node_invitation_service_test.dart
git commit -m "test: add unit tests for node invitation model and service"
```

---

## Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| 1. Database | 1-2 | `node_invitations` table + RPCs |
| 2. Phone Auth | 3-4 | OTP methods + verification screen |
| 3. Invitation Service | 5-7 | Model, service, providers |
| 4. Group Creation | 8-9 | Tree CTA + 3-step creation flow |
| 5. Notifications | 10 | Invitation type + glowing bell |
| 6. Invitation Detail | 11 | Accept/decline screen |
| 7. Admin Management | 12-13 | Status badge + invitations tab |
| 8. Public Link | 14 | Simplified join screen |
| 9. Domain | 15-16 | `silniapp.com` migration + landing pages |
| 10. Cleanup | 17 | Remove deprecated code |
| 11. Startup | 18 | Check invitations on login |
| 12. Testing | 19 | Integration tests |

**Total: 19 tasks across 12 phases**

Each phase can be committed and tested independently. Phases 1-3 are foundational and must be done first. Phases 4-8 can be parallelized to some extent. Phases 9-12 are cleanup and polish.
