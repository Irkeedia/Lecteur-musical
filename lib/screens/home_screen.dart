import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';
import '../models/song_sort.dart';
import '../services/audio_player_service.dart';
import '../services/music_library_service.dart';
import '../services/sort_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import '../widgets/lazy_song_artwork.dart';
import '../widgets/mini_player.dart';
import 'player_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';

class HomeScreen extends StatefulWidget {
  final AudioPlayerService playerService;

  const HomeScreen({super.key, required this.playerService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final MusicLibraryService _libraryService = MusicLibraryService();
  List<Song> _rawSongs = [];
  List<Song> _allSongs = [];
  SongSortMode _sortMode = SongSortMode.titleAsc;
  bool _isLoading = true;
  int _currentNavIndex = 0;
  late AnimationController _shimmerController;

  // Albums groupés
  Map<String, List<Song>> _albums = {};

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Platform.isAndroid) {
        final n = await Permission.notification.status;
        if (n.isDenied || n.isLimited) {
          await Permission.notification.request();
        }
      }
      await _restoreSortAndLoad();
    });
  }

  Future<void> _restoreSortAndLoad() async {
    final saved = await loadSavedSortMode();
    if (!mounted) return;
    setState(() => _sortMode = saved);
    await _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    _shimmerController.repeat();
    _libraryService.clearArtworkCache();
    try {
      final songs = await _libraryService.getAllSongs();
      final sorted = sortSongs(songs, _sortMode);
      final albums = _groupAlbums(sorted);
      setState(() {
        _rawSongs = songs;
        _allSongs = sorted;
        _albums = albums;
        _isLoading = false;
      });
      widget.playerService.applyQueueReorderIfSameTracks(_allSongs);
    } catch (e, st) {
      debugPrint('Scan bibliothèque: $e\n$st');
      setState(() {
        _rawSongs = [];
        _allSongs = [];
        _albums = {};
        _isLoading = false;
      });
    } finally {
      _shimmerController.stop();
    }
  }

  Map<String, List<Song>> _groupAlbums(List<Song> songs) {
    final Map<String, List<Song>> albums = {};
    for (final song in songs) {
      final albumKey = song.albumDisplay;
      albums.putIfAbsent(albumKey, () => []);
      albums[albumKey]!.add(song);
    }
    return albums;
  }

  Future<void> _setSortMode(SongSortMode mode) async {
    if (mode == _sortMode) return;
    setState(() {
      _sortMode = mode;
      _allSongs = sortSongs(_rawSongs, _sortMode);
      _albums = _groupAlbums(_allSongs);
    });
    await saveSortMode(mode);
    widget.playerService.applyQueueReorderIfSameTracks(_allSongs);
  }

  void _openPlayer() {
    if (widget.playerService.currentSong == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return PlayerScreen(playerService: widget.playerService);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
            child: FadeTransition(
              opacity: curved,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _allSongs.isEmpty
                        ? _buildEmptyState()
                        : _buildTabContent(),
              ),
              MiniPlayer(
                playerService: widget.playerService,
                onTap: _openPlayer,
              ),
              _buildBottomNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tab Content Switcher ───────────────────────────────────
  Widget _buildTabContent() {
    return IndexedStack(
      index: _currentNavIndex,
      children: [
        _buildMainContent(),
        SearchScreen(
          playerService: widget.playerService,
          allSongs: _allSongs,
          albums: _albums,
        ),
        LibraryScreen(
          playerService: widget.playerService,
          allSongs: _allSongs,
          albums: _albums,
          onRefresh: _loadSongs,
          sortMode: _sortMode,
          onSortChanged: _setSortMode,
        ),
      ],
    );
  }

  // ─── Bottom Navigation Bar fixe (3 onglets) ─────────────────
  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.deepNavy,
        border: Border(
          top: BorderSide(
            color: AppTheme.surfaceLight.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: 'Accueil',
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.search,
            label: 'Recherche',
            index: 1,
          ),
          _buildNavItem(
            icon: Icons.library_music,
            label: 'Bibliothèque',
            index: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _currentNavIndex = index);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.accentPurple : AppTheme.greyMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.accentPurple : AppTheme.greyMuted,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Contenu principal (scroll complet) ─────────────────────
  Widget _buildMainContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // Header
        SliverToBoxAdapter(child: _buildTopBar()),
        // Hero Card
        SliverToBoxAdapter(child: _buildHeroCard()),
        // Albums horizontaux
        if (_albums.length > 1) ...[
          SliverToBoxAdapter(child: _buildSectionTitle('Albums', _albums.length)),
          SliverToBoxAdapter(child: _buildAlbumsRow()),
        ],
        // Tous les titres + tri
        SliverToBoxAdapter(
          child: _buildTitresSectionHeader(),
        ),
        // Liste des chansons
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return SongTile(
                song: _allSongs[index],
                playlist: _allSongs,
                playerService: widget.playerService,
                index: index,
              );
            },
            childCount: _allSongs.length,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }

  // ─── Top Bar (sans burger) ──────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Suno Player',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${_allSongs.length} titres',
            style: const TextStyle(
              color: AppTheme.greyMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Card (premier morceau avec grosse image) ──────────
  Widget _buildHeroCard() {
    // Prendre la chanson en cours ou la première
    final heroSong = widget.playerService.currentSong ?? (_allSongs.isNotEmpty ? _allSongs.first : null);
    if (heroSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        widget.playerService.playSong(heroSong, _allSongs);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        height: 200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: 480,
                    height: 480,
                    child: LazySongArtwork(
                      song: heroSong,
                      size: 480,
                      borderRadius: 0,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x553B52CC),
                      Color(0x668B5CF6),
                      Color(0x88D946EF),
                    ],
                  ),
                ),
              ),
              // Overlay gradient sombre
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xBB0D1428),
                    ],
                  ),
                ),
              ),
              // Contenu
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heroSong.title,
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 12),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      heroSong.artistDisplay.toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.accentPurple.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Play button
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.glowShadow(AppTheme.accentBlue, blur: 16),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: AppTheme.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitresSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                const Text(
                  'Tous les titres',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentPurple,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_allSongs.length}',
                  style: const TextStyle(
                    color: AppTheme.greyMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SongSortMenuButton(
            value: _sortMode,
            onChanged: _setSortMode,
          ),
        ],
      ),
    );
  }

  // ─── Section Title ──────────────────────────────────────────
  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.accentPurple,
              shape: BoxShape.circle,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right,
            color: AppTheme.greyMuted,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ─── Albums Row (scroll horizontal) ─────────────────────────
  Widget _buildAlbumsRow() {
    final albumEntries = _albums.entries.toList();
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: albumEntries.length,
        itemBuilder: (context, index) {
          final entry = albumEntries[index];
          final albumName = entry.key;
          final songs = entry.value;
          // Prendre l'artwork de la première chanson de l'album
          final artwork = songs.firstWhere(
            (s) => s.artwork != null,
            orElse: () => songs.first,
          ).artwork;

          return GestureDetector(
            onTap: () {
              widget.playerService.playSong(songs.first, songs);
            },
            child: Container(
              width: 130,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artwork de l'album
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 130,
                      height: 115,
                      child: artwork != null
                          ? Image.memory(
                              artwork,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _albumColor(index),
                                    _albumColor(index).withValues(alpha: 0.5),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.album,
                                color: AppTheme.white,
                                size: 36,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    albumName,
                    style: const TextStyle(
                      color: AppTheme.softWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _albumColor(int index) {
    const colors = [
      Color(0xFFE74C3C),
      Color(0xFF8B5CF6),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
    ];
    return colors[index % colors.length];
  }

  // ─── Loading State ──────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    transform: GradientRotation(_shimmerController.value * 6.28),
                    colors: [
                      AppTheme.accentBlue.withValues(alpha: 0.0),
                      AppTheme.accentBlue.withValues(alpha: 0.6),
                      AppTheme.accentPurple.withValues(alpha: 0.6),
                      AppTheme.accentPurple.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppTheme.darkBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.graphic_eq,
                      color: AppTheme.accentPurple,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Scan en cours...',
            style: TextStyle(color: AppTheme.grey, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceLight,
            ),
            child: const Icon(
              Icons.library_music,
              size: 40,
              color: AppTheme.accentPurple,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune musique',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez vos créations Suno\nsur votre appareil',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.greyMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadSongs,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Actualiser',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }
}
