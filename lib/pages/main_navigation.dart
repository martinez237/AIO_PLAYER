import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/playlist_page.dart';
import '../widgets/mini_player.dart';
import '../service/global_audio_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const PlaylistPage(),
  ];

  final List<String> _pageNames = [
    'Home',
    'Playlist',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Contenu principal des pages
          Column(
            children: [

              // Contenu des pages
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // MiniPlayer au-dessus de la navigation bar
          Consumer<GlobalAudioService>(
            builder: (context, audioService, child) {
              // Afficher uniquement sur la page playlist (index 1)
              if (_currentIndex != 1 || audioService.currentSong == null) {
                return const SizedBox.shrink();
              }

              return const MiniPlayer();
            },
          ),

          // Navigation Bar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2D3436).withOpacity(0.95),
                  const Color(0xFF0D0D0D),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF6C5CE7),
              unselectedItemColor: Colors.white.withOpacity(0.6),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 11,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  activeIcon: Icon(Icons.home),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music_outlined),
                  activeIcon: Icon(Icons.library_music),
                  label: 'Playlist',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Paramètres',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget Consumer pour écouter les changements du GlobalAudioService
class Consumer<T extends ChangeNotifier> extends StatefulWidget {
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  const Consumer({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  State<Consumer<T>> createState() => _ConsumerState<T>();
}

class _ConsumerState<T extends ChangeNotifier> extends State<Consumer<T>> {
  late T _service;

  @override
  void initState() {
    super.initState();
    _service = GlobalAudioService() as T;
    _service.addListener(_listener);
  }

  @override
  void dispose() {
    _service.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _service, widget.child);
  }
}