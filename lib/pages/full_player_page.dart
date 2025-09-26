import 'package:flutter/material.dart';
import '../service/global_audio_service.dart';
import '../widgets/mini_player.dart';

class FullPlayerPage extends StatefulWidget {
  const FullPlayerPage({super.key});

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

class _FullPlayerPageState extends State<FullPlayerPage>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Démarrer la rotation si la musique joue
    final audioService = GlobalAudioService();
    if (audioService.isPlaying) {
      _rotationController.repeat();
    }

    audioService.addListener(_onAudioStateChanged);
  }

  void _onAudioStateChanged() {
    final audioService = GlobalAudioService();
    if (audioService.isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!audioService.isPlaying) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    GlobalAudioService().removeListener(_onAudioStateChanged);
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              final screenHeight = constraints.maxHeight;
              final screenWidth = constraints.maxWidth;
              final isSmallScreen = screenHeight < 700;
              final albumSize = (screenWidth * 0.65).clamp(220.0, 300.0);

              return Consumer<GlobalAudioService>(
                builder: (context, audioService, child) {
                  final currentSong = audioService.currentSong;

                  if (currentSong == null) {
                    return const Center(
                      child: Text(
                        'Aucune musique en cours',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Header
                            _buildHeader(isSmallScreen),

                            // Contenu principal
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 20,
                                  vertical: isSmallScreen ? 10 : 20,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Image d'album
                                    Flexible(
                                      flex: 3,
                                      child: _buildAlbumArt(currentSong, albumSize, isSmallScreen),
                                    ),

                                    // Informations de la chanson
                                    Flexible(
                                      flex: 1,
                                      child: _buildSongInfo(currentSong, isSmallScreen),
                                    ),

                                    // Slider de progression
                                    Flexible(
                                      flex: 1,
                                      child: _buildProgressSlider(audioService, isSmallScreen),
                                    ),

                                    // Contrôles principaux
                                    Flexible(
                                      flex: 1,
                                      child: _buildMainControls(audioService, isSmallScreen),
                                    ),

                                    // Contrôles secondaires
                                    Flexible(
                                      flex: 1,
                                      child: _buildSecondaryControls(audioService, isSmallScreen),
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'En cours de lecture',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.more_vert,
              color: Colors.white,
              size: isSmallScreen ? 18 : 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(currentSong, double albumSize, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
      child: RotationTransition(
        turns: _rotationController,
        child: Container(
          width: albumSize,
          height: albumSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.3),
                Colors.blue.withOpacity(0.3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.4),
                blurRadius: isSmallScreen ? 30 : 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C5CE7),
                  const Color(0xFF74B9FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: isSmallScreen ? 20 : 30,
                  offset: Offset(0, isSmallScreen ? 10 : 15),
                ),
              ],
            ),
            child: Icon(
              Icons.music_note,
              size: albumSize * 0.4,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(currentSong, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            currentSong.title,
            style: TextStyle(
              fontSize: isSmallScreen ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            currentSong.artist,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isSmallScreen) ...[
            const SizedBox(height: 0),
            Text(
              currentSong.album,
              style: TextStyle(
                fontSize: 0,
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressSlider(GlobalAudioService audioService, bool isSmallScreen) {
    return StreamBuilder<Duration>(
      stream: audioService.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = audioService.player.duration ?? const Duration(seconds: 1);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.2),
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: isSmallScreen ? 5 : 6,
                  ),
                  trackHeight: isSmallScreen ? 2 : 3,
                ),
                child: Slider(
                  value: total.inSeconds > 0
                      ? (position.inSeconds.toDouble() / total.inSeconds.toDouble()).clamp(0.0, 1.0)
                      : 0.0,
                  onChanged: (value) {
                    final newPosition = Duration(seconds: (total.inSeconds * value).round());
                    audioService.seek(newPosition);
                  },
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatDuration(total),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainControls(GlobalAudioService audioService, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Précédent
          GestureDetector(
            onTap: audioService.previousSong,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.skip_previous,
                color: Colors.white,
                size: isSmallScreen ? 28 : 35,
              ),
            ),
          ),

          // Play/Pause
          ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: () {
                _scaleController.forward().then((_) => _scaleController.reverse());
                audioService.togglePlayPause();
              },
              child: Container(
                width: isSmallScreen ? 75 : 85,
                height: isSmallScreen ? 75 : 85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: audioService.isLoading
                      ? SizedBox(
                    width: isSmallScreen ? 25 : 30,
                    height: isSmallScreen ? 25 : 30,
                    child: const CircularProgressIndicator(
                      color: Color(0xFF6C5CE7),
                      strokeWidth: 3,
                    ),
                  )
                      : Icon(
                    audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: const Color(0xFF6C5CE7),
                    size: isSmallScreen ? 35 : 40,
                  ),
                ),
              ),
            ),
          ),

          // Suivant
          GestureDetector(
            onTap: audioService.nextSong,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.skip_next,
                color: Colors.white,
                size: isSmallScreen ? 28 : 35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryControls(GlobalAudioService audioService, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: audioService.toggleShuffle,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: audioService.isShuffled
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shuffle,
                color: audioService.isShuffled
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
                size: isSmallScreen ? 20 : 24,
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            child: Icon(
              Icons.favorite_border,
              color: Colors.white.withOpacity(0.6),
              size: isSmallScreen ? 20 : 24,
            ),
          ),

          GestureDetector(
            onTap: audioService.toggleRepeat,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: audioService.isRepeated
                    ? Colors.white.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.repeat,
                color: audioService.isRepeated
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
                size: isSmallScreen ? 20 : 24,
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            child: Icon(
              Icons.queue_music,
              color: Colors.white.withOpacity(0.6),
              size: isSmallScreen ? 20 : 24,
            ),
          ),
        ],
      ),
    );
  }
}