import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import 'lazy_song_artwork.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song> playlist;
  final AudioPlayerService playerService;
  final int index;

  const SongTile({
    super.key,
    required this.song,
    required this.playlist,
    required this.playerService,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playerService,
      builder: (context, _) {
        final isActive = playerService.currentSong?.id == song.id;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => playerService.playSong(song, playlist),
              borderRadius: BorderRadius.circular(16),
              splashColor: AppTheme.accentBlue.withValues(alpha: 0.1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  // Pill active style comme le mockup
                  gradient: isActive ? AppTheme.pillGradient : null,
                  color: isActive ? null : Colors.transparent,
                ),
                child: Row(
                  children: [
                    // Index
                    SizedBox(
                      width: 22,
                      child: isActive
                          ? const _PlayingIndicator()
                          : Text(
                              '${index + 1}'.padLeft(2, '0'),
                              style: TextStyle(
                                color: AppTheme.greyMuted.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Artwork circulaire
                    LazySongArtwork(
                      song: song,
                      size: 44,
                      circular: true,
                    ),
                    const SizedBox(width: 12),
                    // Titre & artiste
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 14,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artistDisplay,
                            style: TextStyle(
                              color: isActive
                                  ? AppTheme.softWhite.withValues(alpha: 0.7)
                                  : AppTheme.greyMuted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Trois points menu
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                        icon: Icon(
                          Icons.more_horiz,
                          color: isActive
                              ? AppTheme.softWhite.withValues(alpha: 0.7)
                              : AppTheme.greyMuted,
                          size: 20,
                        ),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayingIndicator extends StatefulWidget {
  const _PlayingIndicator();

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        duration: Duration(milliseconds: 350 + i * 120),
        vsync: this,
      )..repeat(reverse: true);
    });
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 3, end: 13).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, _) {
            return Container(
              width: 2.5,
              height: _animations[i].value,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}
