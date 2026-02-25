<p align="center">
  <img src="https://img.icons8.com/fluency/96/music.png" alt="Suno Player Logo" width="96"/>
</p>

<h1 align="center">🎵 Suno Player</h1>

<p align="center">
  <strong>Un lecteur musical Android élégant, pensé pour écouter tes créations Suno.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" alt="Android"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow?logo=opensourceinitiative&logoColor=white" alt="MIT"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Design-Dark_Theme-0D1541" alt="Dark"/>
  <img src="https://img.shields.io/badge/Accent-Gold_%E2%9C%A8-FFD54F" alt="Gold"/>
  <img src="https://img.shields.io/badge/Made_with-%E2%9D%A4-red" alt="Love"/>
</p>

---

## ✨ Présentation

**Suno Player** est un lecteur musical natif Android au design sombre et moderne, conçu pour rassembler et écouter tes musiques générées par [Suno AI](https://suno.com) dans une interface fluide et agréable.

Pas de compte, pas de streaming, pas de pub — juste tes fichiers audio et un beau player.

---

## 🎨 Design

<table>
  <tr>
    <td align="center"><strong>Palette</strong></td>
    <td align="center"><strong>Philosophie</strong></td>
  </tr>
  <tr>
    <td>
      <code>🔵 #1A237E</code> Bleu nuit profond<br/>
      <code>🟡 #FFD54F</code> Or lumineux<br/>
      <code>⚪ #F5F5F7</code> Blanc doux<br/>
      <code>🌑 #080E2B</code> Fond sombre
    </td>
    <td>
      • Dark theme exclusif<br/>
      • Typographie Poppins<br/>
      • Coins arrondis partout<br/>
      • Animations subtiles<br/>
      • UX minimaliste
    </td>
  </tr>
</table>

---

## 🚀 Fonctionnalités

| Fonctionnalité | Description |
|---|---|
| 🎧 **Lecture complète** | Play, pause, suivant, précédent, barre de progression |
| 🔀 **Shuffle & Repeat** | Mode aléatoire + répétition (off / all / one) |
| 🔍 **Recherche** | Filtrage instantané par titre, artiste ou album |
| 🖼️ **Artwork** | Affichage des pochettes intégrées aux fichiers audio |
| 📱 **Mini Player** | Barre de lecture persistante en bas de l'écran |
| 🎵 **Player plein écran** | Vue immersive avec grands artwork et contrôles |
| 📋 **File d'attente** | Voir et naviguer la playlist en cours |
| 🔄 **Scan automatique** | Détecte tous les fichiers audio sur l'appareil |
| 📂 **Multi-formats** | MP3, WAV, FLAC, M4A, OGG, AAC |

---

## 📁 Architecture

```
lib/
├── main.dart                          # Point d'entrée
├── theme/
│   └── app_theme.dart                 # Thème & couleurs
├── models/
│   └── song.dart                      # Modèle Song
├── services/
│   ├── audio_player_service.dart      # Moteur de lecture
│   └── music_library_service.dart     # Scan & recherche
├── screens/
│   ├── home_screen.dart               # Écran principal
│   └── player_screen.dart             # Lecteur plein écran
└── widgets/
    ├── artwork_widget.dart            # Widget artwork
    ├── mini_player.dart               # Mini lecteur
    └── song_tile.dart                 # Tuile de chanson
```

---

## 🛠️ Stack technique

- **Framework** : [Flutter](https://flutter.dev) — app native Android
- **Audio** : [just_audio](https://pub.dev/packages/just_audio) — lecture performante
- **Scan fichiers** : [on_audio_query](https://pub.dev/packages/on_audio_query) — accès à la bibliothèque musicale
- **Permissions** : [permission_handler](https://pub.dev/packages/permission_handler)
- **Typographie** : [Google Fonts (Poppins)](https://pub.dev/packages/google_fonts)

---

## 📦 Installation

### Prérequis

- Flutter SDK 3.x+
- Android SDK (API 21+)
- Un appareil Android ou émulateur

### Build & Install

```bash
# Cloner le repo
git clone https://github.com/Irkeedia/Lecteur-musical.git
cd Lecteur-musical

# Installer les dépendances
flutter pub get

# Compiler l'APK debug
flutter build apk --debug

# Installer sur un appareil connecté en USB
flutter install --debug
```

### Utilisation

1. Copie tes fichiers audio Suno sur ton téléphone (dossier `Music/` ou `Download/`)
2. Ouvre **Suno Player**
3. Accepte la permission d'accès aux fichiers audio
4. Profite 🎶

---

## 📋 Permissions requises

| Permission | Raison |
|---|---|
| `READ_MEDIA_AUDIO` | Accéder aux fichiers audio (Android 13+) |
| `READ_EXTERNAL_STORAGE` | Accéder aux fichiers audio (Android < 13) |
| `FOREGROUND_SERVICE` | Lecture audio en arrière-plan |
| `WAKE_LOCK` | Empêcher la mise en veille pendant la lecture |

---

## 🗺️ Roadmap

- [ ] Playlists personnalisées
- [ ] Favoris
- [ ] Égaliseur audio intégré
- [ ] Notification de lecture avec contrôles
- [ ] Import direct depuis l'URL Suno
- [ ] Widget écran d'accueil
- [ ] Support tablette

---

## 👤 Auteur

**Mathieu** — [@Irkeedia](https://github.com/Irkeedia)

Projet personnel pour centraliser mes créations musicales Suno AI.

---

<p align="center">
  <sub>Fait avec ❤️ et beaucoup de <code>flutter build</code></sub>
</p>
