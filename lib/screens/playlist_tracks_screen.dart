import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/song_sort.dart';
import '../services/audio_player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';

/// Liste de pistes avec tri : l’ordre affiché = ordre de lecture (haut → bas).
class PlaylistTracksScreen extends StatefulWidget {
  final String title;
  final List<Song> songs;
  final AudioPlayerService playerService;
  final SongSortMode initialSortMode;

  const PlaylistTracksScreen({
    super.key,
    required this.title,
    required this.songs,
    required this.playerService,
    this.initialSortMode = SongSortMode.titleAsc,
  });

  @override
  State<PlaylistTracksScreen> createState() => _PlaylistTracksScreenState();
}

class _PlaylistTracksScreenState extends State<PlaylistTracksScreen> {
  late SongSortMode _sortMode;
  late List<Song> _ordered;

  @override
  void initState() {
    super.initState();
    _sortMode = widget.initialSortMode;
    _ordered = sortSongs(widget.songs, _sortMode);
  }

  void _applySort(SongSortMode mode) {
    setState(() {
      _sortMode = mode;
      _ordered = sortSongs(widget.songs, _sortMode);
    });
    widget.playerService.applyQueueReorderIfSameTracks(_ordered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_ordered.length} titre${_ordered.length > 1 ? 's' : ''}',
                        style: const TextStyle(color: AppTheme.greyMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Lecture : du haut vers le bas',
                        style: TextStyle(color: AppTheme.softWhite, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                SongSortMenuButton(
                  value: _sortMode,
                  onChanged: _applySort,
                ),
              ],
            ),
          ),
          Expanded(
            child: _ordered.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun titre ici',
                      style: TextStyle(color: AppTheme.greyMuted, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _ordered.length,
                    itemBuilder: (context, index) {
                      return SongTile(
                        song: _ordered[index],
                        playlist: _ordered,
                        playerService: widget.playerService,
                        index: index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
