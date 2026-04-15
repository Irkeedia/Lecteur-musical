import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'song.dart';

enum SongSortMode {
  titleAsc,
  titleDesc,
  dateAddedAsc,
  dateAddedDesc,
}

extension SongSortModeX on SongSortMode {
  String get label {
    switch (this) {
      case SongSortMode.titleAsc:
        return 'Titre (A → Z)';
      case SongSortMode.titleDesc:
        return 'Titre (Z → A)';
      case SongSortMode.dateAddedAsc:
        return 'Date d\'ajout (plus anciennes)';
      case SongSortMode.dateAddedDesc:
        return 'Date d\'ajout (plus récentes)';
    }
  }

  /// Libellé court pour la barre d’état
  String get shortLabel {
    switch (this) {
      case SongSortMode.titleAsc:
        return 'A → Z';
      case SongSortMode.titleDesc:
        return 'Z → A';
      case SongSortMode.dateAddedAsc:
        return 'Ajout ↑';
      case SongSortMode.dateAddedDesc:
        return 'Ajout ↓';
    }
  }
}

List<Song> sortSongs(List<Song> songs, SongSortMode mode) {
  final copy = List<Song>.from(songs);
  int dateKey(Song s) => s.dateAdded ?? 0;
  switch (mode) {
    case SongSortMode.titleAsc:
      copy.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
    case SongSortMode.titleDesc:
      copy.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      break;
    case SongSortMode.dateAddedAsc:
      copy.sort((a, b) {
        final c = dateKey(a).compareTo(dateKey(b));
        if (c != 0) return c;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      break;
    case SongSortMode.dateAddedDesc:
      copy.sort((a, b) {
        final c = dateKey(b).compareTo(dateKey(a));
        if (c != 0) return c;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      break;
  }
  return copy;
}

/// Bouton menu tri (réutilisable : accueil, bibliothèque, playlist, file d’attente).
class SongSortMenuButton extends StatelessWidget {
  final SongSortMode value;
  final ValueChanged<SongSortMode> onChanged;
  final String? tooltip;

  const SongSortMenuButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SongSortMode>(
      tooltip: tooltip ?? 'Trier la liste',
      initialValue: value,
      onSelected: onChanged,
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, color: AppTheme.accentPurple, size: 22),
            const SizedBox(width: 4),
            Text(
              value.shortLabel,
              style: const TextStyle(
                color: AppTheme.greyMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => SongSortMode.values.map((mode) {
        final selected = mode == value;
        return PopupMenuItem<SongSortMode>(
          value: mode,
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: selected
                    ? const Icon(Icons.check, size: 18, color: AppTheme.accentPurple)
                    : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  mode.label,
                  style: TextStyle(
                    color: AppTheme.softWhite,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
