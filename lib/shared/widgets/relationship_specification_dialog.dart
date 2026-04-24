import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/relative_model.dart';
import '../services/contacts_import_service.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../features/family_tree/models/family_graph.dart';
import 'glass_card.dart';
import 'flat_relationship_picker.dart';
import 'relative_category_picker.dart';
import '../../features/relatives/services/relationship_inference_service.dart';

/// Data class for contact with relationship specification
class ContactWithRelationship {
  final Contact contact;
  RelationshipType relationshipType;
  Gender? gender;
  String? customRelationship;
  FamilySide? familySide;
  RelativeCategory relativeCategory;

  ContactWithRelationship({
    required this.contact,
    required this.relationshipType,
    this.gender,
    this.customRelationship,
    this.familySide,
    this.relativeCategory = RelativeCategory.extended,
  });
}

/// Dialog for specifying relationships for imported contacts
class RelationshipSpecificationDialog extends ConsumerStatefulWidget {
  final List<Contact> contacts;
  final Function(List<ContactWithRelationship>) onConfirmed;

  const RelationshipSpecificationDialog({
    super.key,
    required this.contacts,
    required this.onConfirmed,
  });

  @override
  ConsumerState<RelationshipSpecificationDialog> createState() =>
      _RelationshipSpecificationDialogState();
}

class _RelationshipSpecificationDialogState
    extends ConsumerState<RelationshipSpecificationDialog> {
  late List<ContactWithRelationship> _contactsWithRelationship;
  final ContactsImportService _contactsImportService = ContactsImportService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeContacts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeContacts() {
    _contactsWithRelationship = widget.contacts.map((contact) {
      final detectedRelationship = _contactsImportService.detectRelationship(
        contact.displayName,
      );
      // Use resolveGender to detect from relationship type + name
      final detectedGender = RelationshipInferenceService.resolveGender(
        relationshipType: detectedRelationship,
        fullName: contact.displayName,
      );

      return ContactWithRelationship(
        contact: contact,
        relationshipType: detectedRelationship,
        gender: detectedGender,
      );
    }).toList();
  }

  void _updateCustomRelationship(int index, String customRelationship) {
    setState(() {
      _contactsWithRelationship[index].customRelationship = customRelationship;
    });
  }



  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);
    final mediaQuery = MediaQuery.of(context);
    final safeHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Container(
        width: mediaQuery.size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: safeHeight * 0.85,
        ),
        decoration: BoxDecoration(
          color: themeColors.background1.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: themeColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(themeColors),

            // Content
            Flexible(child: _buildContactsList(themeColors)),

            // Actions
            _buildActions(themeColors),
          ],
        ),
      ).animate().scale().fadeIn(),
    );
  }

  Widget _buildHeader(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: themeColors.primary.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusLg),
          topRight: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Column(
        children: [
          Text(
            'تحديد صلة القرابة',
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'يرجى تحديد صلة القرابة لكل جهة اتصال تم استيرادها',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(ThemeColors themeColors) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _contactsWithRelationship.length,
      itemBuilder: (context, index) {
        final contactWithRel = _contactsWithRelationship[index];
        return _buildContactItem(contactWithRel, index, themeColors);
      },
    );
  }

  Widget _buildContactItem(
    ContactWithRelationship contactWithRel,
    int index,
    ThemeColors themeColors,
  ) {
    final contact = contactWithRel.contact;
    final relationshipType = contactWithRel.relationshipType;
    final gender = contactWithRel.gender;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact name and avatar
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: themeColors.primaryGradient,
                ),
                child: Center(
                  child: Text(
                    contact.displayName.isNotEmpty
                        ? contact.displayName[0].toUpperCase()
                        : '؟',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
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
                    if (contact.phones.isNotEmpty)
                      Text(
                        contact.phones.first.number,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Relationship type selector
          FlatRelationshipPicker(
            selectedType: relationshipType,
            selectedSide: contactWithRel.familySide,
            selectedGender: gender,
            existingRelatives: const [],
            onSelectionChanged: (type, side, pickerGender) {
              setState(() {
                _contactsWithRelationship[index].relationshipType = type;
                _contactsWithRelationship[index].familySide = side;
                _contactsWithRelationship[index].gender = pickerGender;
              });
            },
          ),

          // Category picker
          const SizedBox(height: AppSpacing.md),
          RelativeCategoryPicker(
            selected: contactWithRel.relativeCategory,
            onChanged: (category) {
              setState(() => _contactsWithRelationship[index].relativeCategory = category);
            },
          ),

          // Custom relationship field (if "other" is selected)
          if (relationshipType == RelationshipType.other) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'وصف العلاقة:',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'مثال: صديق، جار، زميل عمل...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide(color: themeColors.primary, width: 2),
                ),
              ),
              onChanged: (value) => _updateCustomRelationship(index, value),
            ),
          ],
        ],
      ),
    ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().slideX();
  }

  Widget _buildActions(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: themeColors.background1.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusLg),
          bottomRight: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Text(
                'إلغاء',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Confirm button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(_contactsWithRelationship);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text('تأكيد (${_contactsWithRelationship.length})'),
            ),
          ),
        ],
      ),
    );
  }

}
