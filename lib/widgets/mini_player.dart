import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import 'artwork_widget.dart';

class MiniPlayer extends StatelessWidget {
  final AudioPlayerService playerService;
  final VoidCallback onTap;

  const MiniPlayer({
    super.key,
    required this.playerService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerService,
      builder: (context, _) {
        final song = playerService.currentSong;
        if (song == null) return const SizedBox.shrink();

        final progress = playerService.duration.inMilliseconds > 0
            ? playerService.position.inMilliseconds / playerService.duration.inMilliseconds
            : 0.0;

        return GestureDetector(
          onTap: onTap,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -300) {
                playerService.next();
              } else if (details.primaryVelocity! > 300) {
                playerService.previous();
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.accentPurple.withValues(alpha: 0.15),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.deepNavy.withValues(alpha: 0.6),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Artwork circulaire
                    Hero(
                      tag: 'artwork_${song.id}',
                      child: ArtworkWidget(
                        artwork: song.artwork,
                        size: 44,
                        circular: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Titre & artiste
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artistDisplay,
                            style: const TextStyle(
                              color: AppTheme.greyMuted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Contrôles
                    _buildSmallButton(
                      icon: Icons.skip_previous,
                      onPressed: playerService.previous,
                    ),
                    const SizedBox(width: 4),
                    // Play/Pause avec gradient
                    GestureDetector(
                      onTap: playerService.togglePlayPause,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.glowShadow(
                            AppTheme.accentBlue,
                            blur: 12,
                          ),
                        ),
                        child: Icon(
                          playerService.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: AppTheme.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildSmallButton(
                      icon: Icons.skip_next,
                      onPressed: playerService.next,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 3,
                    child: Stack(
                      children: [
                        Container(
                          color: AppTheme.greyDark.withValues(alpha: 0.3),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: AppTheme.glowGradientPurplePink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, color: AppTheme.softWhite, size: 22),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
