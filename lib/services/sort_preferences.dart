import 'package:shared_preferences/shared_preferences.dart';

import '../models/song_sort.dart';

const _kSortModeIndex = 'song_sort_mode_index';

Future<SongSortMode> loadSavedSortMode() async {
  final p = await SharedPreferences.getInstance();
  final i = p.getInt(_kSortModeIndex);
  if (i == null || i < 0 || i >= SongSortMode.values.length) {
    return SongSortMode.titleAsc;
  }
  return SongSortMode.values[i];
}

Future<void> saveSortMode(SongSortMode mode) async {
  final p = await SharedPreferences.getInstance();
  await p.setInt(_kSortModeIndex, mode.index);
}
