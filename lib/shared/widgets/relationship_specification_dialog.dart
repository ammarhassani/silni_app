import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/relative_model.dart';
import '../services/contacts_import_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/app_themes.dart';
import 'glass_card.dart';
import 'gradient_button.dart';

/// Data class for contact with relationship specification
class ContactWithRelationship {
  final Contact contact;
  RelationshipType relationshipType;
  Gender? gender;
  String? customRelationship;

  ContactWithRelationship({
    required this.contact,
    required this.relationshipType,
    this.gender,
    this.customRelationship,
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
      final detectedGender = _contactsImportService.detectGender(
        contact.displayName,
      );

      return ContactWithRelationship(
        contact: contact,
        relationshipType: detectedRelationship,
        gender: detectedGender,
      );
    }).toList();
  }

  void _updateRelationship(int index, RelationshipType relationship) {
    setState(() {
      _contactsWithRelationship[index].relationshipType = relationship;
    });
  }

  void _updateGender(int index, Gender? gender) {
    setState(() {
      _contactsWithRelationship[index].gender = gender;
    });
  }

  void _updateCustomRelationship(int index, String customRelationship) {
    setState(() {
      _contactsWithRelationship[index].customRelationship = customRelationship;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = ref.watch(themeColorsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: themeColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(themeColors),

            // Content
            Expanded(child: _buildContactsList(themeColors)),

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
        color: themeColors.primary.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.8),
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
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Relationship type selector
          Text(
            'صلة القرابة:',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildRelationshipSelector(index, relationshipType, themeColors),

          const SizedBox(height: AppSpacing.md),

          // Gender selector
          Text(
            'الجنس:',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildGenderSelector(index, gender, themeColors),

          // Custom relationship field (if "other" is selected)
          if (relationshipType == RelationshipType.other) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'وصف العلاقة:',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'مثال: صديق، جار، زميل عمل...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => _updateCustomRelationship(index, value),
            ),
          ],
        ],
      ),
    ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().slideX();
  }

  Widget _buildRelationshipSelector(
    int index,
    RelationshipType currentType,
    ThemeColors themeColors,
  ) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: RelationshipType.values.map((type) {
        final isSelected = type == currentType;
        return FilterChip(
          label: Text(
            type == RelationshipType.other
                ? 'أخرى'
                : _getRelationshipArabicName(type),
            style: AppTypography.bodySmall.copyWith(
              color: isSelected ? Colors.black : Colors.white,
            ),
          ),
          selected: isSelected,
          backgroundColor: Colors.white.withOpacity(0.1),
          selectedColor: themeColors.primary,
          onSelected: (selected) {
            if (selected) _updateRelationship(index, type);
          },
        );
      }).toList(),
    );
  }

  Widget _buildGenderSelector(
    int index,
    Gender? currentGender,
    ThemeColors themeColors,
  ) {
    return Row(
      children: [
        Expanded(
          child: FilterChip(
            label: Text(
              'ذكر',
              style: AppTypography.bodySmall.copyWith(
                color: currentGender == Gender.male
                    ? Colors.black
                    : Colors.white,
              ),
            ),
            selected: currentGender == Gender.male,
            backgroundColor: Colors.white.withOpacity(0.1),
            selectedColor: themeColors.primary,
            onSelected: (selected) {
              _updateGender(index, selected ? Gender.male : null);
            },
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: FilterChip(
            label: Text(
              'أنثى',
              style: AppTypography.bodySmall.copyWith(
                color: currentGender == Gender.female
                    ? Colors.black
                    : Colors.white,
              ),
            ),
            selected: currentGender == Gender.female,
            backgroundColor: Colors.white.withOpacity(0.1),
            selectedColor: themeColors.primary,
            onSelected: (selected) {
              _updateGender(index, selected ? Gender.female : null);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusLg),
          bottomRight: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'إلغاء',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),

          // Confirm button
          GradientButton(
            text: 'تأكيد (${_contactsWithRelationship.length})',
            icon: Icons.check_rounded,
            onPressed: () {
              widget.onConfirmed(_contactsWithRelationship);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  String _getRelationshipArabicName(RelationshipType type) {
    switch (type) {
      case RelationshipType.father:
        return 'أب';
      case RelationshipType.mother:
        return 'أم';
      case RelationshipType.brother:
        return 'أخ';
      case RelationshipType.sister:
        return 'أخت';
      case RelationshipType.son:
        return 'ابن';
      case RelationshipType.daughter:
        return 'ابنة';
      case RelationshipType.husband:
        return 'زوج';
      case RelationshipType.wife:
        return 'زوجة';
      case RelationshipType.grandfather:
        return 'جد';
      case RelationshipType.grandmother:
        return 'جدة';
      case RelationshipType.uncle:
        return 'عم';
      case RelationshipType.aunt:
        return 'عمة/خالة';
      case RelationshipType.cousin:
        return 'ابن/ابنة عم/خال';
      case RelationshipType.nephew:
        return 'ابن أخ/أخت';
      case RelationshipType.niece:
        return 'ابنة أخ/أخت';
      case RelationshipType.other:
        return 'أخرى';
    }
  }
}
