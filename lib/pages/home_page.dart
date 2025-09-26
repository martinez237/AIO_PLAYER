import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../service/global_audio_service.dart';
import '../service/music_service.dart';
import '../widgets/music_player_widget.dart';
import '../widgets/custom_app_bar.dart';
import '../models/song_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late GlobalAudioService _audioService;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _audioService = GlobalAudioService();
    _audioService.init();

    // Initialisation des animations
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _initializeDefaultMusic();
    _setupPlayerListeners();
  }

  Future<void> _initializeDefaultMusic() async {
    try {
      if (_audioService.currentSong == null) {
        final songs = await MusicService.scanMusicFolders();
        if (songs.isNotEmpty) {
          // Charger la première chanson sans la jouer
          await _audioService.playSong(songs[0], playlist: songs);
          await _audioService.pause(); // Mettre en pause immédiatement
        } else {
          // Si aucune chanson trouvée, utiliser une URL par défaut
          await _audioService.player.setUrl(
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          );
        }
      }
    } catch (e) {
      print("Erreur lors de l'initialisation: $e");
    }
  }

  void _setupPlayerListeners() {
    _audioService.addListener(_onAudioStateChanged);
    _onAudioStateChanged();
  }

  void _onAudioStateChanged() {
    if (mounted) {
      if (_audioService.isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
      // Forcer la reconstruction pour s'assurer de la synchronisation
      if (mounted) {
        setState(() {});
      }
    }
  }

  void togglePlayback() async {
    print("HomePage: Toggle playback");
    _scaleController.forward().then((_) => _scaleController.reverse());

    // Attendre un petit délai pour la synchronisation
    await _audioService.togglePlayPause();

    // Forcer la synchronisation après un court délai
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _audioService.forceStateSync();
      }
    });
  }

  void _nextSong() async {
    print("HomePage: Chanson suivante");
    await _audioService.nextSong();
  }

  void _previousSong() async {
    print("HomePage: Chanson précédente");
    await _audioService.previousSong();
  }

  void _onSongSelected(SongModel selectedSong) async {
    try {
      print("HomePage: Chanson sélectionnée: ${selectedSong.title}");
      await _audioService.playSong(selectedSong);
    } catch (e) {
      print("Erreur lors de la sélection de chanson: $e");
      _showErrorSnackBar("Impossible de lire cette chanson");
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioStateChanged);
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6C5CE7),
              Color(0xFF2D3436),
              Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // App Bar personnalisée
                        SizedBox(
                          width: double.infinity,
                          child: const CustomAppBar(),
                        ),

                        // Contenu principal
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 16.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width,
                                      maxHeight: constraints.maxHeight * 10,
                                    ),
                                    child: Consumer<GlobalAudioService>(
                                      builder: (context, audioService, child) {
                                        return MusicPlayerWidget(
                                          player: audioService.player,
                                          isPlaying: audioService.isPlaying,
                                          isLoading: audioService.isLoading,
                                          rotationController: _rotationController,
                                          scaleAnimation: _scaleAnimation,
                                          onPlayPause: togglePlayback,
                                          onNext: _nextSong,
                                          onPrevious: _previousSong,
                                          currentSong: audioService.currentSong,
                                          onSongSelected: _onSongSelected,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
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