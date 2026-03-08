import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends StatefulWidget {
  final AudioPlayerService playerService;
  final List<Song> allSongs;
  final Map<String, List<Song>> albums;

  const SearchScreen({
    super.key,
    required this.playerService,
    required this.allSongs,
    required this.albums,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Song> _results = [];
  bool _hasSearched = false;

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      _hasSearched = true;
      _results = widget.allSongs.where((song) {
        return song.title.toLowerCase().contains(lower) ||
            song.artistDisplay.toLowerCase().contains(lower) ||
            song.albumDisplay.toLowerCase().contains(lower);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── Header ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            'Recherche',
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // ─── Search Bar ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearch,
              style: const TextStyle(color: AppTheme.white, fontSize: 15),
              cursorColor: AppTheme.accentPurple,
              decoration: InputDecoration(
                hintText: 'Titre, artiste, album...',
                hintStyle: TextStyle(
                  color: AppTheme.greyMuted.withValues(alpha: 0.6),
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 10),
                  child: Icon(Icons.search, color: AppTheme.greyMuted, size: 22),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.close, color: AppTheme.greyMuted, size: 20),
                        ),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ─── Content ──────────────────────────────────────────
        Expanded(
          child: _hasSearched
              ? _buildResults()
              : _buildBrowse(),
        ),
      ],
    );
  }

  // ─── Browse (avant la recherche) ────────────────────────────
  Widget _buildBrowse() {
    // Genres/catégories fictives basées sur les albums existants
    final categories = <_BrowseCategory>[
      _BrowseCategory('Tout jouer', Icons.play_circle_fill, AppTheme.accentBlue, AppTheme.accentPurple),
      _BrowseCategory('Récents', Icons.schedule, AppTheme.accentPurple, AppTheme.accentPink),
      _BrowseCategory('Par artiste', Icons.person, const Color(0xFF10B981), const Color(0xFF059669)),
      _BrowseCategory('Par album', Icons.album, const Color(0xFFF59E0B), const Color(0xFFEF4444)),
    ];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Titre section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Text(
              'Explorer',
              style: TextStyle(
                color: AppTheme.softWhite,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Grille de catégories
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.7,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cat = categories[index];
                return GestureDetector(
                  onTap: () => _onCategoryTap(index),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cat.color1, cat.color2],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -8,
                          bottom: -8,
                          child: Icon(
                            cat.icon,
                            size: 52,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            cat.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: categories.length,
            ),
          ),
        ),
        // Albums rapides
        if (widget.albums.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Albums',
                style: TextStyle(
                  color: AppTheme.softWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 165,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: widget.albums.length,
                itemBuilder: (context, index) {
                  final entry = widget.albums.entries.elementAt(index);
                  final albumSongs = entry.value;
                  final artwork = albumSongs.firstWhere(
                    (s) => s.artwork != null,
                    orElse: () => albumSongs.first,
                  ).artwork;
                  return GestureDetector(
                    onTap: () {
                      widget.playerService.playSong(albumSongs.first, albumSongs);
                    },
                    child: Container(
                      width: 125,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 125,
                              height: 120,
                              child: artwork != null
                                  ? Image.memory(artwork, fit: BoxFit.cover, gaplessPlayback: true)
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.accentPurple.withValues(alpha: 0.5),
                                            AppTheme.accentBlue.withValues(alpha: 0.3),
                                          ],
                                        ),
                                      ),
                                      child: const Icon(Icons.album, color: AppTheme.softWhite, size: 36),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.softWhite, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${albumSongs.length} titre${albumSongs.length > 1 ? 's' : ''}',
                            style: TextStyle(color: AppTheme.greyMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }

  void _onCategoryTap(int index) {
    switch (index) {
      case 0: // Tout jouer
        if (widget.allSongs.isNotEmpty) {
          final shuffled = List<Song>.from(widget.allSongs)..shuffle();
          widget.playerService.playSong(shuffled.first, shuffled);
        }
        break;
      case 1: // Récents (jouer les derniers ajoutés)
        if (widget.allSongs.isNotEmpty) {
          final reversed = List<Song>.from(widget.allSongs.reversed);
          widget.playerService.playSong(reversed.first, reversed);
        }
        break;
      case 2: // Par artiste — trigger une recherche
        _focusNode.requestFocus();
        break;
      case 3: // Par album — trigger une recherche
        _focusNode.requestFocus();
        break;
    }
  }

  // ─── Résultats de recherche ─────────────────────────────────
  Widget _buildResults() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: AppTheme.greyMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat',
              style: TextStyle(color: AppTheme.greyMuted, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              'Essayez un autre mot-clé',
              style: TextStyle(color: AppTheme.greyDark, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Regrouper par type : artistes trouvés, albums trouvés, titres
    final query = _searchController.text.toLowerCase();
    final matchedArtists = <String>{};
    final matchedAlbums = <String>{};
    for (final song in _results) {
      if (song.artistDisplay.toLowerCase().contains(query)) {
        matchedArtists.add(song.artistDisplay);
      }
      if (song.albumDisplay.toLowerCase().contains(query)) {
        matchedAlbums.add(song.albumDisplay);
      }
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Artistes trouvés
        if (matchedArtists.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: Text('Artistes', style: TextStyle(color: AppTheme.softWhite, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: matchedArtists.length,
                itemBuilder: (context, index) {
                  final artist = matchedArtists.elementAt(index);
                  final artistSongs = widget.allSongs.where((s) => s.artistDisplay == artist).toList();
                  final artwork = artistSongs.firstWhere((s) => s.artwork != null, orElse: () => artistSongs.first).artwork;
                  return GestureDetector(
                    onTap: () {
                      widget.playerService.playSong(artistSongs.first, artistSongs);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppTheme.surfaceLight,
                            backgroundImage: artwork != null ? MemoryImage(artwork) : null,
                            child: artwork == null ? const Icon(Icons.person, color: AppTheme.greyMuted, size: 24) : null,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 70,
                            child: Text(
                              artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.softWhite, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        // Titre "Titres"
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Text(
              '${_results.length} titre${_results.length > 1 ? 's' : ''}',
              style: TextStyle(color: AppTheme.softWhite, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        // Liste
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return SongTile(
                song: _results[index],
                playlist: _results,
                playerService: widget.playerService,
                index: index,
              );
            },
            childCount: _results.length,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }
}

class _BrowseCategory {
  final String label;
  final IconData icon;
  final Color color1;
  final Color color2;
  const _BrowseCategory(this.label, this.icon, this.color1, this.color2);
}
