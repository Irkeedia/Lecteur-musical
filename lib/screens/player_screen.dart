import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/song_sort.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/lazy_song_artwork.dart';

class PlayerScreen extends StatefulWidget {
  final AudioPlayerService playerService;

  const PlayerScreen({super.key, required this.playerService});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    if (widget.playerService.isPlaying) {
      _rotationController.repeat();
    }
    widget.playerService.addListener(_onPlayerStateChanged);
  }

  void _onPlayerStateChanged() {
    if (widget.playerService.isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    widget.playerService.removeListener(_onPlayerStateChanged);
    _rotationController.dispose();
    _glowController.dispose();
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
          backgroundColor: AppTheme.deepNavy,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.deepNavy.withValues(alpha: 0.55),
                          AppTheme.deepNavy.withValues(alpha: 0.75),
                          AppTheme.deepNavy.withValues(alpha: 0.92),
                          AppTheme.deepNavy,
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Contenu principal ───────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    _buildDismissHandle(context),
                    _buildTopBar(context, song),
                    const Spacer(flex: 1),
                    _buildDiscArtwork(song),
                    const Spacer(flex: 1),
                    _buildSongInfo(song),
                    const SizedBox(height: 32),
                    _buildProgressBar(),
                    const SizedBox(height: 24),
                    _buildControls(),
                    const SizedBox(height: 16),
                    _buildBottomNav(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Glisser vers le bas pour fermer (comme Spotify).
  Widget _buildDismissHandle(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v > 240) {
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: Center(
          child: Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.greyMuted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Top Bar ────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 24),
            color: AppTheme.white,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Column(
            children: [
              Text(
                song.title,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                song.artistDisplay,
                style: TextStyle(
                  color: AppTheme.accentPurple.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 22),
            color: AppTheme.white,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ─── Disc Artwork avec anneaux de glow concentriques ────────
  Widget _buildDiscArtwork(Song song) {
    final screenWidth = MediaQuery.of(context).size.width;
    final discSize = screenWidth * 0.72;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -300) {
            widget.playerService.next();
          } else if (details.primaryVelocity! > 300) {
            widget.playerService.previous();
          }
        }
      },
      child: Hero(
      tag: 'artwork_${song.id}',
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _glowController]),
        builder: (context, child) {
          final glowOpacity = 0.3 + (_glowController.value * 0.4);
          return SizedBox(
            width: discSize + 60,
            height: discSize + 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Anneau extérieur glow violet/rose
                Container(
                  width: discSize + 52,
                  height: discSize + 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      transform: GradientRotation(_rotationController.value * 2 * math.pi),
                      colors: [
                        AppTheme.glowPurple.withValues(alpha: glowOpacity * 0.5),
                        AppTheme.glowPink.withValues(alpha: glowOpacity * 0.8),
                        AppTheme.glowBlue.withValues(alpha: glowOpacity * 0.3),
                        AppTheme.glowPurple.withValues(alpha: glowOpacity * 0.6),
                        AppTheme.glowPink.withValues(alpha: glowOpacity * 0.5),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.glowPurple.withValues(alpha: glowOpacity * 0.6),
                        blurRadius: 50,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: AppTheme.glowPink.withValues(alpha: glowOpacity * 0.4),
                        blurRadius: 80,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
                // Anneau intérieur (ring sombre)
                Container(
                  width: discSize + 28,
                  height: discSize + 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.deepNavy.withValues(alpha: 0.8),
                  ),
                ),
                // Anneau lumineux 2
                Container(
                  width: discSize + 18,
                  height: discSize + 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.glowPurple.withValues(alpha: glowOpacity * 0.6),
                      width: 1.5,
                    ),
                  ),
                ),
                // Disque d'artwork circulaire
                Container(
                  width: discSize,
                  height: discSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: LazySongArtwork(
                      song: song,
                      size: discSize,
                      circular: true,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
    );
  }

  // ─── Song Info ──────────────────────────────────────────────
  Widget _buildSongInfo(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          Text(
            song.title,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            song.artistDisplay,
            style: TextStyle(
              color: AppTheme.accentPurple.withValues(alpha: 0.8),
              fontSize: 15,
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

  // ─── Progress Bar ───────────────────────────────────────────
  Widget _buildProgressBar() {
    final position = widget.playerService.position;
    final duration = widget.playerService.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          SizedBox(
            height: 28,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                activeTrackColor: AppTheme.accentPurple,
                inactiveTrackColor: AppTheme.surfaceLight.withValues(alpha: 0.6),
                thumbColor: AppTheme.white,
                overlayColor: AppTheme.accentPurple.withValues(alpha: 0.12),
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
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: const TextStyle(
                    color: AppTheme.greyMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '-${_formatDuration(duration - position)}',
                  style: const TextStyle(
                    color: AppTheme.greyMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Contrôles principaux ───────────────────────────────────
  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shuffle
          _buildToggleButton(
            icon: Icons.shuffle,
            isActive: widget.playerService.isShuffled,
            onPressed: widget.playerService.toggleShuffle,
            size: 22,
          ),
          // Previous
          IconButton(
            icon: const Icon(Icons.skip_previous, size: 36),
            color: AppTheme.white,
            onPressed: widget.playerService.previous,
            padding: EdgeInsets.zero,
          ),
          // Play / Pause — bouton gradient
          GestureDetector(
            onTap: widget.playerService.togglePlayPause,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.glowShadow(AppTheme.accentBlue, blur: 24),
              ),
              child: Icon(
                widget.playerService.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: AppTheme.white,
                size: 34,
              ),
            ),
          ),
          // Next
          IconButton(
            icon: const Icon(Icons.skip_next, size: 36),
            color: AppTheme.white,
            onPressed: widget.playerService.next,
            padding: EdgeInsets.zero,
          ),
          // Repeat
          _buildToggleButton(
            icon: widget.playerService.repeatMode == SunoRepeatMode.one
                ? Icons.repeat_one
                : Icons.repeat,
            isActive: widget.playerService.repeatMode != SunoRepeatMode.off,
            onPressed: widget.playerService.toggleRepeat,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    double size = 22,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: isActive
          ? ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.accentGradient.createShader(bounds),
              child: Icon(icon, color: Colors.white, size: size),
            )
          : Icon(icon, color: AppTheme.greyMuted, size: size),
    );
  }

  // ─── Bottom Nav (Home / Queue / Favoris) ────────────────────
  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.home, color: AppTheme.greyMuted, size: 24),
                const SizedBox(height: 4),
                Text('Home', style: TextStyle(color: AppTheme.greyMuted, fontSize: 10)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showQueueSheet(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.accentGradient.createShader(bounds),
                  child: const Icon(Icons.queue_music, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.accentGradient.createShader(bounds),
                  child: const Text('Queue', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                const Icon(Icons.favorite_border, color: AppTheme.greyMuted, size: 24),
              const SizedBox(height: 4),
              Text('Favoris', style: TextStyle(color: AppTheme.greyMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Queue Sheet ────────────────────────────────────────────
  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.3,
                maxChildSize: 0.85,
                expand: false,
                builder: (context, scrollController) {
                  var queueMenuMode = SongSortMode.titleAsc;
                  return StatefulBuilder(
                    builder: (context, setModalState) {
                      return ListenableBuilder(
                        listenable: widget.playerService,
                        builder: (context, _) {
                          return Column(
                            children: [
                              const SizedBox(height: 12),
                              Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppTheme.greyDark,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    AppTheme.accentGradient.createShader(bounds),
                                child: const Text(
                                  'File d\'attente',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.playerService.playlist.length} titres',
                                style: const TextStyle(color: AppTheme.greyMuted, fontSize: 13),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Ordre de lecture : haut → bas',
                                        style: TextStyle(color: AppTheme.greyMuted, fontSize: 12),
                                      ),
                                    ),
                                    SongSortMenuButton(
                                      value: queueMenuMode,
                                      onChanged: (m) {
                                        queueMenuMode = m;
                                        setModalState(() {});
                                        final sorted = sortSongs(
                                          List<Song>.from(widget.playerService.playlist),
                                          m,
                                        );
                                        widget.playerService.applyQueueReorderIfSameTracks(sorted);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.only(bottom: 16),
                                  itemCount: widget.playerService.playlist.length,
                                  itemBuilder: (context, index) {
                                    final song = widget.playerService.playlist[index];
                                    final isActive = index == widget.playerService.currentIndex;
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          widget.playerService.playAtIndex(index);
                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
                                          ),
                                          decoration: isActive
                                              ? BoxDecoration(
                                                  gradient: AppTheme.pillGradient,
                                                  borderRadius: BorderRadius.circular(12),
                                                )
                                              : null,
                                          margin: isActive
                                              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 2)
                                              : EdgeInsets.zero,
                                          child: Row(
                                            children: [
                                              LazySongArtwork(
                                                song: song,
                                                size: 44,
                                                circular: true,
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      song.title,
                                                      style: TextStyle(
                                                        color: AppTheme.white,
                                                        fontWeight: isActive
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                        fontSize: 14,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      song.artistDisplay,
                                                      style: const TextStyle(
                                                        color: AppTheme.greyMuted,
                                                        fontSize: 12,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isActive)
                                                ShaderMask(
                                                  shaderCallback: (bounds) =>
                                                      AppTheme.accentGradient.createShader(bounds),
                                                  child: const Icon(
                                                    Icons.equalizer,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
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
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
