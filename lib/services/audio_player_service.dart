import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
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

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  
  List<Song> _playlist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isShuffled = false;
  SunoRepeatMode _repeatMode = SunoRepeatMode.off;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<int> _shuffleOrder = [];

  // Getters
  AudioPlayer get player => _player;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _playlist.length 
      ? _playlist[_currentIndex] 
      : null;
  bool get isPlaying => _isPlaying;
  bool get isShuffled => _isShuffled;
  SunoRepeatMode get repeatMode => _repeatMode;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get hasSong => currentSong != null;

  AudioPlayerService() {
    AudioSession.instance.then((session) {
      session.interruptionEventStream.listen((event) {
        if (event.begin && event.type == AudioInterruptionType.pause) {
          _player.pause();
        }
      });
    });
    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
      notifyListeners();
    });
  }

  Future<void> playSong(Song song, List<Song> playlist) async {
    _playlist = playlist;
    _currentIndex = playlist.indexOf(song);
    if (_currentIndex == -1) {
      _currentIndex = 0;
      _playlist = [song, ...playlist];
    }
    await _loadAndPlay();
  }

  Future<void> playAtIndex(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      await _loadAndPlay();
    }
  }

  Future<void> _loadAndPlay() async {
    if (currentSong == null) return;
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
      await _player.setAudioSource(AudioSource.uri(Uri.parse(currentSong!.uri)));
      await _player.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      final session = await AudioSession.instance;
      await session.setActive(true);
      await _player.play();
    }
  }

  Future<void> next() async {
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

  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    
    // Si on est à plus de 3s, revenir au début
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
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

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    if (_isShuffled) {
      _shuffleOrder = List.generate(_playlist.length, (i) => i)..shuffle();
    }
    notifyListeners();
  }

  /// Réordonne la file si [newOrder] contient exactement les mêmes pistes que la file actuelle
  /// (comme un tri Spotify : l’ordre à l’écran = ordre de lecture suivant).
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
    notifyListeners();
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
    notifyListeners();
  }

  void _onSongCompleted() {
    switch (_repeatMode) {
      case SunoRepeatMode.one:
        _loadAndPlay();
        break;
      case SunoRepeatMode.all:
        next();
        break;
      case SunoRepeatMode.off:
        if (_currentIndex < _playlist.length - 1) {
          next();
        }
        break;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
