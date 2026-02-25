import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ArtworkWidget extends StatelessWidget {
  final Uint8List? artwork;
  final double size;
  final double borderRadius;
  final bool showShadow;

  const ArtworkWidget({
    super.key,
    this.artwork,
    this.size = 56,
    this.borderRadius = 12,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppTheme.accentYellow.withValues(alpha: 0.1),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: artwork != null
            ? Image.memory(
                artwork!,
                fit: BoxFit.cover,
                width: size,
                height: size,
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentBlue,
                      AppTheme.primaryBlue,
                      AppTheme.surfaceBlue,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.music_note_rounded,
                  size: size * 0.4,
                  color: AppTheme.accentYellow,
                ),
              ),
      ),
    );
  }
}
