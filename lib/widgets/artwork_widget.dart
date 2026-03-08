import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ArtworkWidget extends StatelessWidget {
  final Uint8List? artwork;
  final double size;
  final double borderRadius;
  final bool showShadow;
  final bool showGlow;
  final bool circular;

  const ArtworkWidget({
    super.key,
    this.artwork,
    this.size = 56,
    this.borderRadius = 12,
    this.showShadow = false,
    this.showGlow = false,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    final shape = circular
        ? BoxShape.circle
        : BoxShape.rectangle;
    final br = circular ? null : BorderRadius.circular(borderRadius);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: br,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                if (showGlow) ...[
                  BoxShadow(
                    color: AppTheme.glowPurple.withValues(alpha: 0.35),
                    blurRadius: 50,
                    spreadRadius: -5,
                  ),
                  BoxShadow(
                    color: AppTheme.glowPink.withValues(alpha: 0.2),
                    blurRadius: 80,
                    spreadRadius: -10,
                  ),
                ],
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: circular
            ? BorderRadius.circular(size / 2)
            : BorderRadius.circular(borderRadius),
        child: artwork != null
            ? Image.memory(
                artwork!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                gaplessPlayback: true,
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1C2A50),
                      Color(0xFF162040),
                      Color(0xFF111B33),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow subtil derrière l'icône
                    Container(
                      width: size * 0.45,
                      height: size * 0.45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.accentPurple.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Icon(
                      Icons.music_note,
                      size: size * 0.35,
                      color: AppTheme.accentPurple.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
