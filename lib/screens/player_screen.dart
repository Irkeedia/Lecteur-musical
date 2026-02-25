import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork_widget.dart';

class PlayerScreen extends StatefulWidget {
  final AudioPlayerService playerService;

  const PlayerScreen({super.key, required this.playerService});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    if (widget.playerService.isPlaying) {
      _rotationController.repeat();
    }
    widget.playerService.addListener(_onPlayerStateChanged);
  }

  void _onPlayerStateChanged() {
    if (widget.playerService.isPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    widget.playerService.removeListener(_onPlayerStateChanged);
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.playerService,
      builder: (context, _) {
        final song = widget.playerService.currentSong;
        if (song == null) return const SizedBox.shrink();

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.accentBlue.withValues(alpha: 0.4),
                  AppTheme.darkBackground,
                  AppTheme.darkBackground,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar
                  _buildTopBar(context),
                  const Spacer(flex: 1),
                  // Artwork grande taille
                  _buildArtwork(),
                  const Spacer(flex: 1),
                  // Infos chanson
                  _buildSongInfo(song),
                  const SizedBox(height: 32),
                  // Barre de progression
                  _buildProgressBar(),
                  const SizedBox(height: 24),
                  // Contrôles principaux
                  _buildControls(),
                  const SizedBox(height: 20),
                  // Contrôles secondaires
                  _buildSecondaryControls(),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            color: AppTheme.softWhite,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Column(
            children: [
              Text(
                'EN LECTURE',
                style: TextStyle(
                  color: AppTheme.accentYellow.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.playerService.currentSong?.albumDisplay ?? '',
                style: const TextStyle(
                  color: AppTheme.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 24),
            color: AppTheme.softWhite,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork() {
    final song = widget.playerService.currentSong!;
    final size = MediaQuery.of(context).size.width * 0.72;

    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Hero(
          tag: 'artwork_${song.id}',
          child: ArtworkWidget(
            artwork: song.artwork,
            size: size,
            borderRadius: 24,
            showShadow: true,
          ),
        );
      },
    );
  }

  Widget _buildSongInfo(dynamic song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            song.title,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            song.artistDisplay,
            style: TextStyle(
              color: AppTheme.accentYellow.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final position = widget.playerService.position;
    final duration = widget.playerService.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: AppTheme.accentYellow,
              inactiveTrackColor: AppTheme.accentBlue.withValues(alpha: 0.25),
              thumbColor: AppTheme.accentYellow,
              overlayColor: AppTheme.accentYellow.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (value * duration.inMilliseconds).round(),
                );
                widget.playerService.seekTo(newPosition);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shuffle
          IconButton(
            icon: Icon(
              Icons.shuffle_rounded,
              color: widget.playerService.isShuffled
                  ? AppTheme.accentYellow
                  : AppTheme.grey,
            ),
            iconSize: 26,
            onPressed: widget.playerService.toggleShuffle,
          ),
          // Précédent
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, color: AppTheme.white),
            iconSize: 40,
            onPressed: widget.playerService.previous,
          ),
          // Play/Pause
          GestureDetector(
            onTap: widget.playerService.togglePlayPause,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.brightYellow,
                    AppTheme.accentYellow,
                    AppTheme.deepYellow,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentYellow.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                widget.playerService.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: AppTheme.darkBackground,
                size: 38,
              ),
            ),
          ),
          // Suivant
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: AppTheme.white),
            iconSize: 40,
            onPressed: widget.playerService.next,
          ),
          // Repeat
          IconButton(
            icon: Icon(
              widget.playerService.repeatMode == SunoRepeatMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              color: widget.playerService.repeatMode != SunoRepeatMode.off
                  ? AppTheme.accentYellow
                  : AppTheme.grey,
            ),
            iconSize: 26,
            onPressed: widget.playerService.toggleRepeat,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.queue_music_rounded, color: AppTheme.grey, size: 24),
            onPressed: () => _showQueueSheet(context),
          ),
        ],
      ),
    );
  }

  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'File d\'attente',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: widget.playerService.playlist.length,
                    itemBuilder: (context, index) {
                      final song = widget.playerService.playlist[index];
                      final isActive = index == widget.playerService.currentIndex;
                      return ListTile(
                        leading: ArtworkWidget(
                          artwork: song.artwork,
                          size: 42,
                          borderRadius: 8,
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(
                            color: isActive ? AppTheme.accentYellow : AppTheme.white,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.artistDisplay,
                          style: const TextStyle(color: AppTheme.grey, fontSize: 12),
                        ),
                        trailing: isActive
                            ? const Icon(Icons.equalizer_rounded, color: AppTheme.accentYellow, size: 20)
                            : null,
                        onTap: () {
                          widget.playerService.playAtIndex(index);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
