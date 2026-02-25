import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import 'artwork_widget.dart';

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

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                playerService.playSong(song, playlist);
              },
              borderRadius: BorderRadius.circular(14),
              splashColor: AppTheme.accentYellow.withValues(alpha: 0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isActive 
                    ? AppTheme.accentBlue.withValues(alpha: 0.15)
                    : Colors.transparent,
                  border: isActive
                    ? Border.all(color: AppTheme.accentYellow.withValues(alpha: 0.3), width: 1)
                    : null,
                ),
                child: Row(
                  children: [
                    // Numéro ou indicateur de lecture
                    SizedBox(
                      width: 28,
                      child: isActive
                          ? const _PlayingIndicator()
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: AppTheme.grey.withValues(alpha: 0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Artwork
                    ArtworkWidget(
                      artwork: song.artwork,
                      size: 48,
                      borderRadius: 10,
                    ),
                    const SizedBox(width: 14),
                    // Infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: TextStyle(
                              color: isActive ? AppTheme.accentYellow : AppTheme.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            song.artistDisplay,
                            style: const TextStyle(
                              color: AppTheme.grey,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Durée
                    Text(
                      song.durationFormatted,
                      style: TextStyle(
                        color: AppTheme.grey.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
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
        duration: Duration(milliseconds: 400 + i * 150),
        vsync: this,
      )..repeat(reverse: true);
    });
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 4, end: 16).animate(
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
              width: 3,
              height: _animations[i].value,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }
}
