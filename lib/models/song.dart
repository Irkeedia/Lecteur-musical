import 'dart:typed_data';

class Song {
  final int id;
  final String title;
  final String artist;
  final String? album;
  final Duration duration;
  final String uri;
  final Uint8List? artwork;

  /// Secondes depuis epoch (MediaStore `date_added`), si disponible.
  final int? dateAdded;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.duration,
    required this.uri,
    this.artwork,
    this.dateAdded,
  });

  String get durationFormatted {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get artistDisplay => artist.isEmpty || artist == '<unknown>' ? 'Suno' : artist;
  String get albumDisplay => (album == null || album!.isEmpty || album == '<unknown>') ? 'Suno Music' : album!;
}
