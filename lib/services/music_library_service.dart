import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';

class MusicLibraryService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  
  Future<bool> requestPermissions() async {
    // Android 13+ (API 33)
    if (await Permission.audio.status.isDenied) {
      final status = await Permission.audio.request();
      if (status.isGranted) return true;
    }
    
    // Android < 13
    if (await Permission.storage.status.isDenied) {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;
    }

    return await Permission.audio.isGranted || await Permission.storage.isGranted;
  }

  Future<List<Song>> getAllSongs() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return [];

    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    return _collectSongsFromModels(songs);
  }

  bool _isPlayable(SongModel song) {
    return song.isMusic == true ||
        song.fileExtension == 'mp3' ||
        song.fileExtension == 'wav' ||
        song.fileExtension == 'flac' ||
        song.fileExtension == 'm4a' ||
        song.fileExtension == 'ogg' ||
        song.fileExtension == 'aac';
  }

  /// Scan rapide : pas de [queryArtwork] ici (c’était le goulot : 1 appel synchrone par titre).
  /// Les pochettes se chargent à la demande via [queryArtworkBytes].
  Future<List<Song>> _collectSongsFromModels(List<SongModel> songs) async {
    final List<Song> result = [];
    for (final song in songs) {
      if (!_isPlayable(song)) continue;

      result.add(Song(
        id: song.id,
        title: song.title,
        artist: song.artist ?? 'Suno',
        album: song.album,
        duration: Duration(milliseconds: song.duration ?? 0),
        uri: song.uri ?? song.data,
        artwork: null,
        dateAdded: song.dateAdded,
      ));
    }
    return result;
  }

  static final Map<int, Uint8List?> _artworkCache = {};

  /// Pochette pour un id (cache mémoire). Appel léger pour l’UI, pas pour le scan massif.
  Future<Uint8List?> queryArtworkBytes(int songId, {int size = 200}) async {
    if (_artworkCache.containsKey(songId)) return _artworkCache[songId];
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      _artworkCache[songId] = null;
      return null;
    }
    Uint8List? artwork;
    try {
      artwork = await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        size: size,
      );
    } catch (_) {}
    final v = (artwork != null && artwork.isNotEmpty) ? artwork : null;
    _artworkCache[songId] = v;
    return v;
  }

  void clearArtworkCache() {
    _artworkCache.clear();
  }

  Future<List<PlaylistModel>> querySystemPlaylists() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return [];
    return _audioQuery.queryPlaylists(
      sortType: PlaylistSortType.PLAYLIST,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
  }

  Future<List<Song>> getSongsFromPlaylist(int playlistId) async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return [];
    final songs = await _audioQuery.queryAudiosFrom(
      AudiosFromType.PLAYLIST,
      playlistId,
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      ignoreCase: true,
    );
    return _collectSongsFromModels(songs);
  }

  /// Chemins usuels du dossier Téléchargements (Android).
  Future<String?> resolveDownloadFolderPath() async {
    const candidates = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
    ];
    for (final p in candidates) {
      try {
        if (await Directory(p).exists()) return p;
      } catch (_) {}
    }
    return candidates.first;
  }

  Future<List<Song>> getSongsFromFolder(String folderPath) async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return [];
    final songs = await _audioQuery.queryFromFolder(
      folderPath,
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    return _collectSongsFromModels(songs);
  }

  Future<List<Song>> searchSongs(String query, List<Song> allSongs) async {
    final lower = query.toLowerCase();
    return allSongs.where((song) {
      return song.title.toLowerCase().contains(lower) ||
          song.artistDisplay.toLowerCase().contains(lower) ||
          song.albumDisplay.toLowerCase().contains(lower);
    }).toList();
  }
}
