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

    final List<Song> result = [];
    for (final song in songs) {
      if (song.isMusic == true || song.fileExtension == 'mp3' || song.fileExtension == 'wav' || song.fileExtension == 'flac' || song.fileExtension == 'm4a' || song.fileExtension == 'ogg' || song.fileExtension == 'aac') {
        Uint8List? artwork;
        try {
          artwork = await _audioQuery.queryArtwork(
            song.id,
            ArtworkType.AUDIO,
            size: 400,
          );
        } catch (_) {}
        
        result.add(Song(
          id: song.id,
          title: song.title,
          artist: song.artist ?? 'Suno',
          album: song.album,
          duration: Duration(milliseconds: song.duration ?? 0),
          uri: song.uri ?? song.data,
          artwork: (artwork != null && artwork.isNotEmpty) ? artwork : null,
        ));
      }
    }
    return result;
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
