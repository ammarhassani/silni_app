import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A widget for displaying message illustrations from CDN
class MessageIllustration extends StatelessWidget {
  final String? illustrationUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool animate;

  const MessageIllustration({
    super.key,
    required this.illustrationUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (illustrationUrl == null || illustrationUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    Widget image = CachedNetworkImage(
      imageUrl: illustrationUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildLoadingIndicator(context),
      errorWidget: (context, url, error) => _buildErrorWidget(context),
    );

    if (animate) {
      image = image
          .animate()
          .fadeIn(duration: const Duration(milliseconds: 400))
          .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1.0, 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
    }

    return image;
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return SizedBox(
      width: width ?? 200,
      height: height ?? 200,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width ?? 200,
      height: height ?? 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width ?? 200,
      height: height ?? 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

/// Full-screen background illustration with overlay
class MessageBackgroundIllustration extends StatelessWidget {
  final String? illustrationUrl;
  final Color? overlayColor;
  final double overlayOpacity;

  const MessageBackgroundIllustration({
    super.key,
    required this.illustrationUrl,
    this.overlayColor,
    this.overlayOpacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    if (illustrationUrl == null || illustrationUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        CachedNetworkImage(
          imageUrl: illustrationUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox.shrink(),
          errorWidget: (context, url, error) => const SizedBox.shrink(),
        ),

        // Overlay for text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (overlayColor ?? Colors.black).withValues(alpha: overlayOpacity),
                (overlayColor ?? Colors.black).withValues(alpha: overlayOpacity * 0.5),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}

/// Hero illustration for full-screen messages
class MessageHeroIllustration extends StatelessWidget {
  final String? illustrationUrl;
  final double maxHeight;
  final bool animate;

  const MessageHeroIllustration({
    super.key,
    required this.illustrationUrl,
    this.maxHeight = 300,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget illustration = MessageIllustration(
      illustrationUrl: illustrationUrl,
      height: maxHeight,
      fit: BoxFit.contain,
      animate: false,
    );

    if (animate) {
      illustration = illustration
          .animate()
          .fadeIn(duration: const Duration(milliseconds: 600))
          .slideY(
            begin: -0.1,
            end: 0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
          );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: illustration,
    );
  }
}
