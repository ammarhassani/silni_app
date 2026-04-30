import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/errors/app_errors.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/relationship_specification_dialog.dart';
import '../../../shared/models/relative_model.dart';
import '../../../core/providers/cache_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../family_tree/models/family_graph.dart';
import '../../family_tree/providers/family_graph_providers.dart';
import '../../family_tree/services/family_graph_service.dart';
import '../../home/providers/home_providers.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/directional_icon.dart';

class ContactImportScreen extends ConsumerStatefulWidget {
  /// When true, the screen acts as a single-contact picker:
  /// - No multi-select checkboxes
  /// - Tapping a contact returns it immediately via Navigator.pop
  /// - No "import all" / "select all" buttons
  /// - Search still works
  final bool singleSelect;

  const ContactImportScreen({super.key, this.singleSelect = false});

  @override
  ConsumerState<ContactImportScreen> createState() =>
      _ContactImportScreenState();
}

class _ContactImportScreenState extends ConsumerState<ContactImportScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  Set<String> _selectedContactIds = {};
  bool _isLoading = true;
  bool _permissionDenied = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      // Request permission
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );

        // Filter contacts that have at least a name
        final validContacts = contacts
            .where((c) => c.displayName.isNotEmpty)
            .toList();

        // Sort alphabetically
        validContacts.sort((a, b) => a.displayName.compareTo(b.displayName));

        setState(() {
          _allContacts = validContacts;
          _filteredContacts = validContacts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'خطأ في تحميل جهات الاتصال: $e',
          isError: true,
        );
      }
    }
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        _filteredContacts = _allContacts
            .where(
              (contact) => contact.displayName.toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  void _toggleContact(String contactId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedContactIds.contains(contactId)) {
        _selectedContactIds.remove(contactId);
      } else {
        _selectedContactIds.add(contactId);
      }
    });
  }

  void _selectAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_selectedContactIds.length == _filteredContacts.length) {
        _selectedContactIds.clear();
      } else {
        _selectedContactIds = _filteredContacts.map((c) => c.id).toSet();
      }
    });
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'أدخل الاسم',
          style: AppTypography.titleLarge.copyWith(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'اسم القريب',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: Colors.white54,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx); // close dialog
                final manualContact = Contact(displayName: name);
                Navigator.pop(context, manualContact); // return to caller
              }
            },
            child: Text(
              'إضافة',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.islamicGreenPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importSelected() async {
    if (_selectedContactIds.isEmpty) {
      UIHelpers.showSnackBar(
        context,
        'الرجاء اختيار جهة اتصال واحدة على الأقل',
        isError: true,
      );
      return;
    }

    // Get selected contacts
    final selectedContacts = _allContacts
        .where((contact) => _selectedContactIds.contains(contact.id))
        .toList();

    // Show relationship specification dialog
    final result = await showDialog<List<ContactWithRelationship>>(
      context: context,
      builder: (context) => RelationshipSpecificationDialog(
        contacts: selectedContacts,
        onConfirmed: (contactsWithRelationship) => contactsWithRelationship,
      ),
    );

    if (result == null) return; // User cancelled

    setState(() => _isImporting = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw const AuthError(
          type: AuthErrorType.sessionExpired,
          message: 'User not authenticated',
          arabicMessage: 'يرجى تسجيل الدخول أولاً',
        );
      }

      int successCount = 0;
      int errorCount = 0;
      final List<String> errors = [];
      String? lastCreatedRelativeId;

      final repository = ref.read(relativesRepositoryProvider);

      // Snapshot existing edges and relatives for graph inference.
      // We keep mutable copies so each iteration sees previously-created data.
      final existingEdges = List<FamilyEdge>.of(
        ref.read(familyEdgesStreamProvider(user.id)).valueOrNull ??
            <FamilyEdge>[],
      );
      final existingRelatives = List<Relative>.of(
        ref.read(relativesStreamProvider(user.id)).valueOrNull ??
            <Relative>[],
      );

      for (final contactWithRel in result) {
        try {
          final contact = contactWithRel.contact;

          // Get first phone number if available
          final phoneNumber = contact.phones.isNotEmpty
              ? contact.phones.first.number
              : null;

          // Determine avatar type based on relationship and gender
          final avatarType = AvatarType.suggestFromRelationship(
            contactWithRel.relationshipType,
            contactWithRel.gender,
          );

          // Create relative from contact with specified relationship
          final relative = Relative(
            id: '', // Will be generated by repository
            userId: user.id,
            fullName: contact.displayName,
            relationshipType: contactWithRel.relationshipType,
            gender: contactWithRel.gender,
            phoneNumber: phoneNumber,
            avatarType: avatarType,
            familySide: contactWithRel.familySide,
            relativeCategory: contactWithRel.relativeCategory,
            notes: contactWithRel
                .customRelationship, // Store custom relationship in notes
            createdAt: DateTime.now(),
          );

          lastCreatedRelativeId = await repository.createRelative(relative);
          successCount++;

          // Infer and persist family graph edges
          final inferredEdges = FamilyGraphService.inferEdges(
            userId: user.id,
            newRelativeId: lastCreatedRelativeId,
            relationshipType: contactWithRel.relationshipType,
            side: contactWithRel.familySide,
            existingEdges: existingEdges,
            existingRelatives: existingRelatives,
          );

          if (inferredEdges.isNotEmpty) {
            await SupabaseConfig.client.from('family_edges').upsert(
              inferredEdges.map((e) => e.toJson()).toList(),
              onConflict: 'user_id,from_id,to_id,edge_type',
            );
            existingEdges.addAll(inferredEdges);
          }

          // Add the created relative to the local list so subsequent
          // iterations can reference it for edge inference.
          existingRelatives.add(relative.copyWith(id: lastCreatedRelativeId));
        } catch (e) {
          errorCount++;
          errors.add('${contactWithRel.contact.displayName}: $e');
          debugPrint('Import error for ${contactWithRel.contact.displayName}: $e');
        }
      }

      setState(() => _isImporting = false);

      // Invalidate the relatives provider to refresh data
      ref.invalidate(relativesStreamProvider(user.id));

      if (successCount > 0) {
        _confettiController.play();
        HapticFeedback.heavyImpact();

        if (mounted) {
          UIHelpers.showSnackBar(
            context,
            'تم استيراد $successCount جهة اتصال بنجاح! 🎉',
            backgroundColor: AppColors.islamicGreenPrimary,
          );
        }

        // Navigate after a short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          if (successCount == 1 && lastCreatedRelativeId != null) {
            // Single import - go to home first, then push relative detail
            // This ensures proper back navigation
            context.go(AppRoutes.home);
            context.push('${AppRoutes.relativeDetail}/$lastCreatedRelativeId');
          } else {
            // Multiple imports - navigate to home
            context.go(AppRoutes.home);
          }
        }
      }

      if (errorCount > 0 && mounted) {
        UIHelpers.showSnackBar(
          context,
          'فشل استيراد $errorCount جهة اتصال',
          isError: true,
        );
        // Log errors for debugging
        for (final error in errors) {
          debugPrint('Import failure: $error');
        }
      }
    } catch (e) {
      setState(() => _isImporting = false);
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'خطأ في الاستيراد: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            animated: true,
            child: SafeArea(
              child: Semantics(
                label: 'شاشة استيراد جهات الاتصال',
                child: Column(
                children: [
                  _buildHeader(themeColors),
                  if (_isLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  else if (_permissionDenied)
                    _buildPermissionDenied()
                  else
                    Expanded(
                      child: Column(
                        children: [
                          _buildSearchBar(themeColors),
                          _buildStats(themeColors),
                          Expanded(child: _buildContactsList(themeColors)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            ),
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                AppColors.islamicGreenPrimary,
                AppColors.premiumGold,
                AppColors.emotionalPurple,
                AppColors.joyfulOrange,
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: !widget.singleSelect && _selectedContactIds.isNotEmpty
          ? GlassCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              gradient: themeColors.primaryGradient,
              onTap: _isImporting ? null : _importSelected,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isImporting)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(Icons.download_rounded, color: Colors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _isImporting
                        ? 'جاري الاستيراد...'
                        : 'استيراد (${_selectedContactIds.length})',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(ThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Semantics(
            label: 'رجوع',
            button: true,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: DirectionalIcon(Icons.arrow_forward_rounded, color: themeColors.textOnGradient),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.singleSelect
                      ? 'اختر جهة اتصال'
                      : 'استيراد جهات الاتصال',
                  style: AppTypography.headlineMedium.copyWith(
                    color: themeColors.textOnGradient,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.singleSelect
                      ? 'اختر الشخص من جهات اتصالك'
                      : 'اختر جهات الاتصال لإضافتهم كأقارب',
                  style: AppTypography.bodySmall.copyWith(
                    color: themeColors.textOnGradient.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildSearchBar(ThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: _searchController,
        onChanged: _filterContacts,
        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'ابحث عن جهة اتصال...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(Icons.search_rounded, color: themeColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.white60),
                  onPressed: () {
                    _searchController.clear();
                    _filterContacts('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildStats(ThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contacts_rounded,
                    color: themeColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${_filteredContacts.length} جهة اتصال',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!widget.singleSelect) ...[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GestureDetector(
                onTap: _selectAll,
                child: GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  gradient: _selectedContactIds.isNotEmpty
                      ? themeColors.primaryGradient
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedContactIds.length == _filteredContacts.length
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'تحديد الكل',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildContactsList(ThemeColors themeColors) {
    if (_filteredContacts.isEmpty) {
      return Center(
        child: GlassCard(
          margin: const EdgeInsets.all(AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 64)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'لا توجد جهات اتصال',
                style: AppTypography.titleLarge.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'جرب البحث بكلمة أخرى',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasManualEntry = widget.singleSelect;
    final totalItemCount =
        _filteredContacts.length + (hasManualEntry ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: totalItemCount,
      itemBuilder: (context, index) {
        // Manual entry item at index 0 in singleSelect mode
        if (hasManualEntry && index == 0) {
          return GestureDetector(
            onTap: _showManualEntryDialog,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    themeColors.primary.withValues(alpha: 0.25),
                    AppColors.emotionalPurple.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: themeColors.primary.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeColors.primary.withValues(alpha: 0.6),
                          AppColors.emotionalPurple.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إدخال يدوي',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'اكتب الاسم يدوياً',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideX(begin: -0.1, end: 0);
        }

        final contactIndex = hasManualEntry ? index - 1 : index;
        final contact = _filteredContacts[contactIndex];
        final isSelected = _selectedContactIds.contains(contact.id);

        return GestureDetector(
              onTap: () {
                if (widget.singleSelect) {
                  Navigator.pop(context, contact);
                } else {
                  _toggleContact(contact.id);
                }
              },
              child: GlassCard(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                gradient: isSelected ? themeColors.primaryGradient : null,
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isSelected
                            ? themeColors.goldenGradient
                            : LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.2),
                                  Colors.white.withValues(alpha: 0.1),
                                ],
                              ),
                      ),
                      child: Center(
                        child: Text(
                          contact.displayName.isNotEmpty
                              ? contact.displayName[0].toUpperCase()
                              : '؟',
                          style: AppTypography.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    // Contact info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.displayName,
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (contact.phones.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              contact.phones.first.number,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Checkbox (hidden in singleSelect mode)
                    if (!widget.singleSelect)
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                  ],
                ),
              ),
            )
            .animate(delay: Duration(milliseconds: 50 * (hasManualEntry ? index - 1 : index)))
            .fadeIn()
            .slideX(begin: -0.1, end: 0);
      },
    );
  }

  Widget _buildPermissionDenied() {
    return Expanded(
      child: Center(
        child: GlassCard(
          margin: const EdgeInsets.all(AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.contacts_rounded,
                size: 64,
                color: Colors.white70,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'إذن مطلوب',
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'نحتاج إلى إذن للوصول إلى جهات الاتصال لاستيرادها',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              GradientButton(
                text: 'طلب الإذن',
                icon: Icons.lock_open_rounded,
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _permissionDenied = false;
                  });
                  _loadContacts();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
