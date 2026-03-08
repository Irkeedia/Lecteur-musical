import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';

class LibraryScreen extends StatefulWidget {
  final AudioPlayerService playerService;
  final List<Song> allSongs;
  final Map<String, List<Song>> albums;
  final VoidCallback onRefresh;

  const LibraryScreen({
    super.key,
    required this.playerService,
    required this.allSongs,
    required this.albums,
    required this.onRefresh,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedTab = 0; // 0 = Titres, 1 = Albums, 2 = Artistes
  String? _expandedAlbum;
  String? _expandedArtist;

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
                onTap: widget.onRefresh,
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
                  : _buildArtistsList(),
        ),
      ],
    );
  }

  // ─── Tab Bar ────────────────────────────────────────────────
  Widget _buildTabBar() {
    final tabs = ['Titres', 'Albums', 'Artistes'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
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
    return ListView.builder(
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
                      // Play all
                      GestureDetector(
                        onTap: () {
                          widget.playerService.playSong(songs.first, songs);
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
              // Songs expandées
              if (isExpanded)
                ...songs.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: SongTile(
                      song: e.value,
                      playlist: songs,
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
                          widget.playerService.playSong(songs.first, songs);
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
                ...songs.asMap().entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: SongTile(
                      song: e.value,
                      playlist: songs,
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
