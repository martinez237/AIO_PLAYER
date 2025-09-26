import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/main_navigation.dart';
import 'service/global_audio_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configuration de la barre de statut
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Music Player Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        fontFamily: 'Roboto',
      ),
      home: const GlobalAudioProvider(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GlobalAudioProvider extends StatefulWidget {
  const GlobalAudioProvider({super.key});

  @override
  State<GlobalAudioProvider> createState() => _GlobalAudioProviderState();
}

class _GlobalAudioProviderState extends State<GlobalAudioProvider> {
  late GlobalAudioService _audioService;

  @override
  void initState() {
    super.initState();
    _audioService = GlobalAudioService();
    _audioService.init(); // Initialiser le service audio global
  }

  @override
  void dispose() {
    // Ne pas disposer le service ici car il doit rester actif
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MainNavigation();
  }
}