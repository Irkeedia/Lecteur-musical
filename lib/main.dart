import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'services/audio_player_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.darkBackground,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const SunoPlayerApp());
  });
}

class SunoPlayerApp extends StatefulWidget {
  const SunoPlayerApp({super.key});

  @override
  State<SunoPlayerApp> createState() => _SunoPlayerAppState();
}

class _SunoPlayerAppState extends State<SunoPlayerApp> {
  late final AudioPlayerService _playerService;

  @override
  void initState() {
    super.initState();
    _playerService = AudioPlayerService();
  }

  @override
  void dispose() {
    _playerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suno Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: HomeScreen(playerService: _playerService),
    );
  }
}
