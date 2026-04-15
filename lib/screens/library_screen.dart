import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/song.dart';
import '../models/song_sort.dart';
import '../services/audio_player_service.dart';
import '../services/music_library_service.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import 'playlist_tracks_screen.dart';

class LibraryScreen extends StatefulWidget {
  final AudioPlayerService playerService;
  final List<Song> allSongs;
  final Map<String, List<Song>> albums;
  final VoidCallback onRefresh;
  final SongSortMode sortMode;
  final ValueChanged<SongSortMode> onSortChanged;

  const LibraryScreen({
    super.key,
    required this.playerService,
    required this.allSongs,
    required this.albums,
    required this.onRefresh,
    required this.sortMode,
    required this.onSortChanged,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedTab = 0; // 0 Titres, 1 Albums, 2 Artistes, 3 Listes
  String? _expandedAlbum;
  String? _expandedArtist;

  final MusicLibraryService _musicLib = MusicLibraryService();
  late Future<List<PlaylistModel>> _playlistsFuture;

  /// Tri local des pistes dans un album / artiste (sinon ordre global).
  final Map<String, SongSortMode> _albumTrackSort = {};
  final Map<String, SongSortMode> _artistTrackSort = {};

  @override
  void initState() {
    super.initState();
    _playlistsFuture = _musicLib.querySystemPlaylists();
  }

  void _reloadPlaylists() {
    setState(() {
      _playlistsFuture = _musicLib.querySystemPlaylists();
    });
  }

  void _onHeaderRefresh() {
    _reloadPlaylists();
    widget.onRefresh();
  }

  SongSortMode _modeForAlbum(String albumName) =>
      _albumTrackSort[albumName] ?? widget.sortMode;

  SongSortMode _modeForArtist(String artistName) =>
      _artistTrackSort[artistName] ?? widget.sortMode;

  // Groupé par artiste
  Map<String, List<Song>> get _artists {
    final Map<String, List<Song>> map = {};
    for (final song in widget.allSongs) {
      map.putIfAbsent(song.artistDisplay, () => []);
      map[song.artistDisplay]!.add(song);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── Header ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Bibliothèque',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Shuffle all
              GestureDetector(
                onTap: () {
                  if (widget.allSongs.isNotEmpty) {
                    final shuffled = List<Song>.from(widget.allSongs)..shuffle();
                    widget.playerService.playSong(shuffled.first, shuffled);
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shuffle, color: AppTheme.softWhite, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _onHeaderRefresh,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh, color: AppTheme.softWhite, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ─── Tab bar (Titres / Albums / Artistes) ─────────────
        _buildTabBar(),
        const SizedBox(height: 8),
        // ─── Stats rapide ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildStatChip(Icons.music_note, '${widget.allSongs.length} titres'),
              const SizedBox(width: 10),
              _buildStatChip(Icons.album, '${widget.albums.length} albums'),
              const SizedBox(width: 10),
              _buildStatChip(Icons.person, '${_artists.length} artistes'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ─── Content ──────────────────────────────────────────
        Expanded(
          child: _selectedTab == 0
              ? _buildTitresList()
              : _selectedTab == 1
                  ? _buildAlbumsList()
                  : _selectedTab == 2
                      ? _buildArtistsList()
                      : _buildPlaylistsTab(),
        ),
      ],
    );
  }

  // ─── Tab Bar ────────────────────────────────────────────────
  Widget _buildTabBar() {
    final tabs = ['Titres', 'Albums', 'Artistes', 'Listes'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final isActive = _selectedTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: isActive ? AppTheme.accentGradient : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      color: isActive ? AppTheme.white : AppTheme.greyMuted,
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─── Stat Chip ──────────────────────────────────────────────
  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.accentPurple),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: AppTheme.grey, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─── Onglet Titres ──────────────────────────────────────────
  Widget _buildTitresList() {
    if (widget.allSongs.isEmpty) {
      return _buildEmpty('Aucun titre');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ordre de lecture',
                      style: TextStyle(color: AppTheme.greyMuted, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Du haut vers le bas, comme Spotify',
                      style: TextStyle(color: AppTheme.softWhite, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              SongSortMenuButton(
                value: widget.sortMode,
                onChanged: widget.onSortChanged,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: widget.allSongs.length,
            itemBuilder: (context, index) {
              return SongTile(
                song: widget.allSongs[index],
                playlist: widget.allSongs,
                playerService: widget.playerService,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Onglet Listes (playlists système + dossier Download) ───
  Widget _buildPlaylistsTab() {
    return FutureBuilder<List<PlaylistModel>>(
      future: _playlistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accentPurple),
          );
        }
        final systemLists = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          physics: const BouncingScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                'Ouvre une liste : le tri s’applique à l’affichage et à la lecture.',
                style: TextStyle(color: AppTheme.greyMuted.withValues(alpha: 0.9), fontSize: 12),
              ),
            ),
            _buildFolderListTile(
              title: 'Dossier Téléchargements',
              subtitle: 'Musique dans le dossier Download',
              icon: Icons.download_rounded,
              onTap: () => _openDownloadFolder(context),
            ),
            ...systemLists.map((pl) => _buildSystemPlaylistTile(context, pl)),
          ],
        );
      },
    );
  }

  Widget _buildFolderListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.accentPurple, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: AppTheme.greyMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.greyMuted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDownloadFolder(BuildContext context) async {
    final path = await _musicLib.resolveDownloadFolderPath();
    if (path == null) return;
    final songs = await _musicLib.getSongsFromFolder(path);
    if (!context.mounted) return;
    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun fichier audio dans Téléchargements')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => PlaylistTracksScreen(
          title: 'Téléchargements',
          songs: songs,
          playerService: widget.playerService,
          initialSortMode: widget.sortMode,
        ),
      ),
    );
  }

  Widget _buildSystemPlaylistTile(BuildContext context, PlaylistModel pl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openSystemPlaylist(context, pl),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.queue_music, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pl.playlist,
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pl.numOfSongs} titre${pl.numOfSongs > 1 ? 's' : ''}',
                        style: TextStyle(color: AppTheme.greyMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.greyMuted, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSystemPlaylist(BuildContext context, PlaylistModel pl) async {
    final songs = await _musicLib.getSongsFromPlaylist(pl.id);
    if (!context.mounted) return;
    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La playlist « ${pl.playlist} » est vide')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => PlaylistTracksScreen(
          title: pl.playlist,
          songs: songs,
          playerService: widget.playerService,
          initialSortMode: widget.sortMode,
        ),
      ),
    );
  }

  // ─── Onglet Albums ──────────────────────────────────────────
  Widget _buildAlbumsList() {
    if (widget.albums.isEmpty) {
      return _buildEmpty('Aucun album');
    }
    final albumEntries = widget.albums.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: albumEntries.length,
      itemBuilder: (context, index) {
        final entry = albumEntries[index];
        final albumName = entry.key;
        final songs = entry.value;
        final trackSort = _modeForAlbum(albumName);
        final displaySongs = sortSongs(songs, trackSort);
        final isExpanded = _expandedAlbum == albumName;
        final artwork = songs.firstWhere(
          (s) => s.artwork != null,
          orElse: () => songs.first,
        ).artwork;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Column(
            children: [
              // Album header
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedAlbum = isExpanded ? null : albumName;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isExpanded ? AppTheme.surfaceLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      // Artwork
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: artwork != null
                              ? Image.memory(artwork, fit: BoxFit.cover, gaplessPlayback: true)
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _albumColor(index),
                                        _albumColor(index).withValues(alpha: 0.4),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(Icons.album, color: AppTheme.white, size: 24),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              albumName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isExpanded ? AppTheme.white : AppTheme.softWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${songs.length} titre${songs.length > 1 ? 's' : ''} · ${songs.first.artistDisplay}',
                              style: TextStyle(color: AppTheme.greyMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // Play all (ordre = displaySongs)
                      GestureDetector(
                        onTap: () {
                          widget.playerService.playSong(displaySongs.first, displaySongs);
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.chevron_right,
                          color: AppTheme.greyMuted,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 6),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Ordre des pistes (lecture)',
                          style: TextStyle(color: AppTheme.greyMuted, fontSize: 11),
                        ),
                      ),
                      SongSortMenuButton(
                        value: trackSort,
                        onChanged: (m) {
                          setState(() => _albumTrackSort[albumName] = m);
                          final ordered = sortSongs(songs, m);
                          widget.playerService.applyQueueReorderIfSameTracks(ordered);
                        },
                      ),
                    ],
                  ),
                ),
              // Songs expandées
              if (isExpanded)
                ...displaySongs.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: SongTile(
                      song: e.value,
                      playlist: displaySongs,
                      playerService: widget.playerService,
                      index: e.key,
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // ─── Onglet Artistes ────────────────────────────────────────
  Widget _buildArtistsList() {
    final artistEntries = _artists.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (artistEntries.isEmpty) {
      return _buildEmpty('Aucun artiste');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: artistEntries.length,
      itemBuilder: (context, index) {
        final entry = artistEntries[index];
        final artistName = entry.key;
        final songs = entry.value;
        final trackSort = _modeForArtist(artistName);
        final displaySongs = sortSongs(songs, trackSort);
        final isExpanded = _expandedArtist == artistName;
        final artwork = songs.firstWhere(
          (s) => s.artwork != null,
          orElse: () => songs.first,
        ).artwork;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedArtist = isExpanded ? null : artistName;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isExpanded ? AppTheme.surfaceLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      // Avatar circulaire
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.surfaceElevated,
                        backgroundImage: artwork != null ? MemoryImage(artwork) : null,
                        child: artwork == null ? const Icon(Icons.person, color: AppTheme.greyMuted, size: 22) : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artistName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isExpanded ? AppTheme.white : AppTheme.softWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${songs.length} titre${songs.length > 1 ? 's' : ''}',
                              style: TextStyle(color: AppTheme.greyMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          widget.playerService.playSong(displaySongs.first, displaySongs);
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.chevron_right,
                          color: AppTheme.greyMuted,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 6),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Ordre des pistes (lecture)',
                          style: TextStyle(color: AppTheme.greyMuted, fontSize: 11),
                        ),
                      ),
                      SongSortMenuButton(
                        value: trackSort,
                        onChanged: (m) {
                          setState(() => _artistTrackSort[artistName] = m);
                          final ordered = sortSongs(songs, m);
                          widget.playerService.applyQueueReorderIfSameTracks(ordered);
                        },
                      ),
                    ],
                  ),
                ),
              if (isExpanded)
                ...displaySongs.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: SongTile(
                      song: e.value,
                      playlist: displaySongs,
                      playerService: widget.playerService,
                      index: e.key,
                    ),
                  );
                }),
            ],
          ),
        );
      },
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

  Widget _buildEmpty(String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_music, size: 48, color: AppTheme.greyMuted),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: AppTheme.greyMuted, fontSize: 15)),
        ],
      ),
    );
  }
}
