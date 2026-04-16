import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'services/audio_player_service.dart';
import 'services/suno_audio_handler.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  final audioHandler = await AudioService.init<SunoAudioHandler>(
    builder: () => SunoAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'fr.irkeedia.suno_player.audio',
      androidNotificationChannelName: 'Suno Player',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
    ),
  );

  final playerService = AudioPlayerService(audioHandler);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // runApp tout de suite : ne pas attendre setPreferredOrientations (sur certains
  // appareils le Future ne se termine pas et l’app reste bloquée sur le splash).
  runApp(SunoPlayerApp(playerService: playerService));
  unawaited(SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]));
}

class SunoPlayerApp extends StatefulWidget {
  final AudioPlayerService playerService;

  const SunoPlayerApp({super.key, required this.playerService});

  @override
  State<SunoPlayerApp> createState() => _SunoPlayerAppState();
}

class _SunoPlayerAppState extends State<SunoPlayerApp> {
  @override
  void dispose() {
    widget.playerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suno Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: HomeScreen(playerService: widget.playerService),
    );
  }
}
