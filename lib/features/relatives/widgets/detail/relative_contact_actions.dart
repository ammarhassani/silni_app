import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../shared/models/relative_model.dart';

/// Contact action buttons widget (call, whatsapp, sms, details)
class RelativeContactActions extends StatelessWidget {
  const RelativeContactActions({
    super.key,
    required this.relative,
    required this.onCall,
    required this.onWhatsApp,
    required this.onSms,
    required this.onDetails,
  });

  final Relative relative;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onSms;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final hasPhone = relative.phoneNumber != null;

    return Row(
      children: [
        // Call button
        Expanded(
          child: _ContactActionButton(
            icon: Icons.phone,
            label: 'اتصال',
            color: Colors.green.shade600,
            onTap: onCall,
            isEnabled: hasPhone,
          ),
        ),
        const SizedBox(width: 8),
        // WhatsApp button
        Expanded(
          child: _ContactActionButton(
            icon: FontAwesomeIcons.whatsapp,
            label: 'واتساب',
            color: const Color(0xFF25D366),
            onTap: onWhatsApp,
            isEnabled: hasPhone,
            useFaIcon: true,
          ),
        ),
        const SizedBox(width: 8),
        // SMS button
        Expanded(
          child: _ContactActionButton(
            icon: Icons.sms,
            label: 'رسالة',
            color: Colors.blue.shade600,
            onTap: onSms,
            isEnabled: hasPhone,
          ),
        ),
        const SizedBox(width: 8),
        // Details button
        Expanded(
          child: _ContactActionButton(
            icon: Icons.info_outline,
            label: 'التفاصيل',
            color: Colors.purple.shade400,
            onTap: onDetails,
            isEnabled: true,
          ),
        ),
      ],
    );
  }
}

class _ContactActionButton extends StatelessWidget {
  const _ContactActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isEnabled,
    this.useFaIcon = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;
  final bool useFaIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  colors: [color.withValues(alpha: 0.85), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isEnabled ? null : Colors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            useFaIcon
                ? FaIcon(
                    icon,
                    color: isEnabled ? Colors.white : Colors.grey,
                    size: 20,
                  )
                : Icon(
                    icon,
                    color: isEnabled ? Colors.white : Colors.grey,
                    size: 20,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
