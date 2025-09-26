import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../pages/playlist_page.dart';
import '../models/song_model.dart';

class MusicPlayerWidget extends StatefulWidget {
  final AudioPlayer player;
  final bool isPlaying;
  final bool isLoading;
  final AnimationController rotationController;
  final Animation<double> scaleAnimation;
  final VoidCallback onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final SongModel? currentSong;
  final Function(SongModel)? onSongSelected;

  const MusicPlayerWidget({
    super.key,
    required this.player,
    required this.isPlaying,
    required this.isLoading,
    required this.rotationController,
    required this.scaleAnimation,
    required this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.currentSong,
    this.onSongSelected,
  });

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  bool isShuffled = false;
  bool isRepeated = false;
  bool isFavorite = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _toggleShuffle() {
    setState(() {
      isShuffled = !isShuffled;
    });
    _showSnackBar(
      isShuffled ? 'Mode aléatoire activé' : 'Mode aléatoire désactivé',
      Colors.blue,
    );
  }

  void _toggleRepeat() {
    setState(() {
      isRepeated = !isRepeated;
    });
    widget.player.setLoopMode(isRepeated ? LoopMode.one : LoopMode.off);
    _showSnackBar(
      isRepeated ? 'Répétition activée' : 'Répétition désactivée',
      Colors.green,
    );
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    _showSnackBar(
      isFavorite ? 'Ajouté aux favoris ❤️' : 'Retiré des favoris',
      isFavorite ? Colors.red : Colors.grey,
    );
  }

  void _openPlaylist() async {
    final selectedSong = await Navigator.push<SongModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const PlaylistPage(),
      ),
    );

    if (selectedSong != null && widget.onSongSelected != null) {
      widget.onSongSelected!(selectedSong);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image d'album avec animation
          Container(
            padding: const EdgeInsets.all(20),
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
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: RotationTransition(
              turns: widget.rotationController,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6C5CE7).withOpacity(0.8),
                          const Color(0xFF74B9FF).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Informations de la chanson
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  widget.currentSong?.title ?? 'SoundHelix Song',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.currentSong?.artist ?? 'Artiste Inconnu',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.currentSong != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    widget.currentSong!.album,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Slider de progression avec temps
          StreamBuilder<Duration>(
            stream: widget.player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final total = widget.player.duration ?? const Duration(seconds: 1);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatDuration(total),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF6C5CE7),
                        inactiveTrackColor: Colors.white.withOpacity(0.2),
                        thumbColor: const Color(0xFF6C5CE7),
                        overlayColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: total.inSeconds > 0
                            ? (position.inSeconds.toDouble() / total.inSeconds.toDouble()).clamp(0.0, 1.0)
                            : 0.0,
                        onChanged: (value) {
                          final newPosition = Duration(seconds: (total.inSeconds * value).round());
                          widget.player.seek(newPosition);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 40),

          // Contrôles de lecture
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Précédent
                GestureDetector(
                  onTap: widget.onPrevious,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.skip_previous,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),

                // Play/Pause principal
                ScaleTransition(
                  scale: widget.scaleAnimation,
                  child: GestureDetector(
                    onTap: widget.onPlayPause,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: widget.isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Icon(
                          widget.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),

                // Suivant
                GestureDetector(
                  onTap: widget.onNext,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.skip_next,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Contrôles secondaires
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: _toggleShuffle,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isShuffled
                          ? const Color(0xFF6C5CE7).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.shuffle,
                      color: isShuffled
                          ? const Color(0xFF6C5CE7)
                          : Colors.white.withOpacity(0.6),
                      size: 22,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isFavorite
                          ? Colors.red.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? Colors.red
                          : Colors.white.withOpacity(0.6),
                      size: 24,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleRepeat,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isRepeated
                          ? const Color(0xFF6C5CE7).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.repeat,
                      color: isRepeated
                          ? const Color(0xFF6C5CE7)
                          : Colors.white.withOpacity(0.6),
                      size: 22,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _openPlaylist,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.playlist_play,
                      color: Colors.white.withOpacity(0.6),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}