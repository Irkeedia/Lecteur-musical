import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_library_service.dart';
import 'artwork_widget.dart';

/// Charge la pochette à la demande (après le scan rapide sans images).
class LazySongArtwork extends StatefulWidget {
  final Song song;
  final double size;
  final double borderRadius;
  final bool circular;
  final bool showShadow;
  final bool showGlow;

  const LazySongArtwork({
    super.key,
    required this.song,
    this.size = 56,
    this.borderRadius = 12,
    this.circular = false,
    this.showShadow = false,
    this.showGlow = false,
  });

  @override
  State<LazySongArtwork> createState() => _LazySongArtworkState();
}

class _LazySongArtworkState extends State<LazySongArtwork> {
  Uint8List? _bytes;
  final MusicLibraryService _lib = MusicLibraryService();

  @override
  void initState() {
    super.initState();
    _bytes = widget.song.artwork;
    if (_bytes == null) {
      _load();
    }
  }

  @override
  void didUpdateWidget(LazySongArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _bytes = widget.song.artwork;
      if (_bytes == null) {
        _load();
      }
    }
  }

  Future<void> _load() async {
    final b = await _lib.queryArtworkBytes(
      widget.song.id,
      size: widget.size.clamp(48, 400).round(),
    );
    if (mounted) setState(() => _bytes = b);
  }

  @override
  Widget build(BuildContext context) {
    return ArtworkWidget(
      artwork: _bytes,
      size: widget.size,
      borderRadius: widget.borderRadius,
      circular: widget.circular,
      showShadow: widget.showShadow,
      showGlow: widget.showGlow,
    );
  }
}
