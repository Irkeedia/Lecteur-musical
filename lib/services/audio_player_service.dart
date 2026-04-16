import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import 'suno_audio_handler.dart';

export 'suno_audio_handler.dart' show SunoRepeatMode;

/// Façade [ChangeNotifier] pour l’UI ; la logique et la MediaSession sont dans [SunoAudioHandler].
class AudioPlayerService extends ChangeNotifier {
  AudioPlayerService(this._handler) {
    _playbackSub = _handler.playbackState.listen((_) => notifyListeners());
    _posSub = _handler.audioPlayer.positionStream.listen((_) => notifyListeners());
    _durSub = _handler.audioPlayer.durationStream.listen((_) => notifyListeners());
  }

  final SunoAudioHandler _handler;

  StreamSubscription<PlaybackState>? _playbackSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;

  SunoAudioHandler get handler => _handler;

  AudioPlayer get player => _handler.audioPlayer;
  List<Song> get playlist => _handler.playlist;
  int get currentIndex => _handler.currentIndex;
  Song? get currentSong => _handler.currentSong;
  bool get isPlaying => _handler.playing;
  bool get isShuffled => _handler.isShuffled;
  SunoRepeatMode get repeatMode => _handler.repeatMode;
  Duration get position => _handler.position;
  Duration get duration => _handler.duration;
  bool get hasSong => currentSong != null;

  Future<void> playSong(Song song, List<Song> playlist) => _handler.playSong(song, playlist);

  Future<void> playAtIndex(int index) => _handler.playAtIndex(index);

  Future<void> togglePlayPause() => _handler.togglePlayPause();

  Future<void> next() => _handler.userNext();

  Future<void> previous() => _handler.userPrevious();

  Future<void> seekTo(Duration position) => _handler.seek(position);

  void toggleShuffle() {
    _handler.toggleShuffle();
    notifyListeners();
  }

  void toggleRepeat() {
    _handler.toggleRepeat();
    notifyListeners();
  }

  void applyQueueReorderIfSameTracks(List<Song> newOrder) {
    _handler.applyQueueReorderIfSameTracks(newOrder);
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    super.dispose();
  }
}
