import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

enum SunoRepeatMode { off, all, one }

bool _sameSongMultiset(List<Song> a, List<Song> b) {
  if (a.length != b.length) return false;
  final ma = <int, int>{};
  final mb = <int, int>{};
  for (final s in a) {
    ma[s.id] = (ma[s.id] ?? 0) + 1;
  }
  for (final s in b) {
    mb[s.id] = (mb[s.id] ?? 0) + 1;
  }
  if (ma.length != mb.length) return false;
  for (final e in ma.entries) {
    if (mb[e.key] != e.value) return false;
  }
  return true;
}

/// Lecteur + [BaseAudioHandler] : notification, premier plan, Bluetooth / Android Auto.
class SunoAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  List<Song> _playlist = [];
  int _currentIndex = -1;
  bool _isShuffled = false;
  SunoRepeatMode _repeatMode = SunoRepeatMode.off;
  List<int> _shuffleOrder = [];

  AudioPlayer get audioPlayer => _player;

  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Song? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _playlist.length ? _playlist[_currentIndex] : null;

  bool get isShuffled => _isShuffled;
  SunoRepeatMode get repeatMode => _repeatMode;

  bool get playing => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;

  SunoAudioHandler() {
    AudioSession.instance.then((session) {
      session.interruptionEventStream.listen((event) {
        if (event.begin && event.type == AudioInterruptionType.pause) {
          _player.pause();
        }
      });
    });

    _player.playbackEventStream.listen((_) => _emitPlaybackState());
    _player.positionStream.listen((_) => _emitPlaybackState());
    _player.durationStream.listen((_) => _emitPlaybackState());
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        unawaited(_onSongCompleted());
      }
    });
  }

  MediaItem _songToMediaItem(Song s) {
    return MediaItem(
      id: s.uri,
      title: s.title,
      artist: s.artistDisplay,
      album: s.albumDisplay,
      duration: s.duration,
      playable: true,
    );
  }

  void _syncQueueAndMedia() {
    if (_playlist.isEmpty || _currentIndex < 0) {
      queue.add([]);
      mediaItem.add(null);
      return;
    }
    queue.add(_playlist.map(_songToMediaItem).toList());
    mediaItem.add(_songToMediaItem(_playlist[_currentIndex]));
  }

  AudioProcessingState _mapProcessing(ProcessingState? s) {
    return const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[s ?? ProcessingState.idle]!;
  }

  AudioServiceRepeatMode _mapRepeat(SunoRepeatMode m) {
    switch (m) {
      case SunoRepeatMode.off:
        return AudioServiceRepeatMode.none;
      case SunoRepeatMode.all:
        return AudioServiceRepeatMode.all;
      case SunoRepeatMode.one:
        return AudioServiceRepeatMode.one;
    }
  }

  void _emitPlaybackState() {
    final playing = _player.playing;
    final idx = _currentIndex >= 0 && _currentIndex < _playlist.length ? _currentIndex : null;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.playPause,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _mapProcessing(_player.processingState),
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: idx,
      repeatMode: _mapRepeat(_repeatMode),
      shuffleMode: _isShuffled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    ));
  }

  Future<void> _loadAndPlay() async {
    if (currentSong == null) return;
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
      await _player.setAudioSource(AudioSource.uri(Uri.parse(currentSong!.uri)));
      await _player.play();
      _syncQueueAndMedia();
      _emitPlaybackState();
    } catch (e) {
      debugPrint('SunoAudioHandler play error: $e');
    }
  }

  Future<void> playSong(Song song, List<Song> playlist) async {
    _playlist = List<Song>.from(playlist);
    _currentIndex = _playlist.indexOf(song);
    if (_currentIndex == -1) {
      _currentIndex = 0;
      _playlist = [song, ..._playlist];
    }
    await _loadAndPlay();
  }

  Future<void> playAtIndex(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      await _loadAndPlay();
    }
  }

  @override
  Future<void> play() async {
    final session = await AudioSession.instance;
    await session.setActive(true);
    await _player.play();
    _emitPlaybackState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _emitPlaybackState();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    _emitPlaybackState();
  }

  @override
  Future<void> skipToNext() async {
    await userNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await userPrevious();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        _repeatMode = SunoRepeatMode.off;
        break;
      case AudioServiceRepeatMode.one:
        _repeatMode = SunoRepeatMode.one;
        break;
      case AudioServiceRepeatMode.all:
        _repeatMode = SunoRepeatMode.all;
        break;
      case AudioServiceRepeatMode.group:
        _repeatMode = SunoRepeatMode.all;
        break;
    }
    _emitPlaybackState();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _isShuffled = shuffleMode == AudioServiceShuffleMode.all;
    if (_isShuffled && _playlist.isNotEmpty) {
      _shuffleOrder = List.generate(_playlist.length, (i) => i)..shuffle();
    }
    _emitPlaybackState();
  }

  Future<void> userNext() async {
    if (_playlist.isEmpty) return;
    if (_isShuffled) {
      final currentOrderIndex = _shuffleOrder.indexOf(_currentIndex);
      final nextOrderIndex = (currentOrderIndex + 1) % _shuffleOrder.length;
      _currentIndex = _shuffleOrder[nextOrderIndex];
    } else {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    }
    await _loadAndPlay();
  }

  Future<void> userPrevious() async {
    if (_playlist.isEmpty) return;
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      _emitPlaybackState();
      return;
    }
    if (_isShuffled) {
      final currentOrderIndex = _shuffleOrder.indexOf(_currentIndex);
      final prevOrderIndex = (currentOrderIndex - 1 + _shuffleOrder.length) % _shuffleOrder.length;
      _currentIndex = _shuffleOrder[prevOrderIndex];
    } else {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    }
    await _loadAndPlay();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    if (_isShuffled) {
      _shuffleOrder = List.generate(_playlist.length, (i) => i)..shuffle();
    }
    _emitPlaybackState();
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case SunoRepeatMode.off:
        _repeatMode = SunoRepeatMode.all;
        break;
      case SunoRepeatMode.all:
        _repeatMode = SunoRepeatMode.one;
        break;
      case SunoRepeatMode.one:
        _repeatMode = SunoRepeatMode.off;
        break;
    }
    _emitPlaybackState();
  }

  void applyQueueReorderIfSameTracks(List<Song> newOrder) {
    if (_playlist.isEmpty || newOrder.isEmpty) return;
    if (!_sameSongMultiset(_playlist, newOrder)) return;
    final cur = currentSong;
    _playlist = List<Song>.from(newOrder);
    if (cur != null) {
      _currentIndex = _playlist.indexWhere((s) => s.id == cur.id);
      if (_currentIndex < 0) _currentIndex = 0;
    } else {
      _currentIndex = _currentIndex.clamp(0, _playlist.length - 1);
    }
    if (_isShuffled && _playlist.isNotEmpty) {
      _shuffleOrder = List.generate(_playlist.length, (i) => i)..shuffle();
    }
    _syncQueueAndMedia();
    _emitPlaybackState();
  }

  Future<void> _onSongCompleted() async {
    switch (_repeatMode) {
      case SunoRepeatMode.one:
        await _loadAndPlay();
        break;
      case SunoRepeatMode.all:
        await userNext();
        break;
      case SunoRepeatMode.off:
        if (_currentIndex < _playlist.length - 1) {
          await userNext();
        }
        break;
    }
  }
}
