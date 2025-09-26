import 'package:flutter/material.dart';
import '../service/global_audio_service.dart';
import '../models/song_model.dart';
import '../pages/full_player_page.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalAudioService>(
      builder: (context, audioService, child) {
        if (audioService.currentSong == null) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isSmallScreen = screenWidth < 400;

            return Container(
              margin: const EdgeInsets.all(0), // Supprimer les marges
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                      const FullPlayerPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 1.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                },
                child: Container(
                  height: isSmallScreen ? 65 : 70,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 15,
                    vertical: isSmallScreen ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C5CE7).withOpacity(0.9),
                        const Color(0xFF74B9FF).withOpacity(0.9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Image de l'album
                      Container(
                        width: isSmallScreen ? 45 : 50,
                        height: isSmallScreen ? 45 : 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),

                      SizedBox(width: isSmallScreen ? 10 : 12),

                      // Informations de la chanson
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              audioService.currentSong!.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 13 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmallScreen ? 1 : 2),
                            Text(
                              audioService.currentSong!.artist,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: isSmallScreen ? 11 : 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Contrôles
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bouton précédent
                          if (!isSmallScreen)
                            IconButton(
                              onPressed: audioService.previousSong,
                              icon: const Icon(
                                Icons.skip_previous,
                                color: Colors.white,
                                size: 24,
                              ),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),

                          // Bouton play/pause
                          Container(
                            width: isSmallScreen ? 36 : 40,
                            height: isSmallScreen ? 36 : 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: audioService.togglePlayPause,
                              icon: audioService.isLoading
                                  ? SizedBox(
                                width: isSmallScreen ? 14 : 16,
                                height: isSmallScreen ? 14 : 16,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Icon(
                                audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: isSmallScreen ? 18 : 20,
                              ),
                              padding: const EdgeInsets.all(0),
                              constraints: BoxConstraints(
                                minWidth: isSmallScreen ? 36 : 40,
                                minHeight: isSmallScreen ? 36 : 40,
                              ),
                            ),
                          ),

                          // Bouton suivant
                          if (!isSmallScreen)
                            IconButton(
                              onPressed: audioService.nextSong,
                              icon: const Icon(
                                Icons.skip_next,
                                color: Colors.white,
                                size: 24,
                              ),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Widget Consumer
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