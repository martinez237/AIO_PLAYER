import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/song_model.dart';
import '../service/global_audio_service.dart';
import '../widgets/mini_player.dart';

class MusicListPage extends StatefulWidget {
  final String title;
  final List<SongModel> songs;

  const MusicListPage({
    super.key,
    required this.title,
    required this.songs,
  });

  @override
  State<MusicListPage> createState() => _MusicListPageState();
}

class _MusicListPageState extends State<MusicListPage> {
  List<SongModel> filteredSongs = [];
  TextEditingController searchController = TextEditingController();
  final GlobalAudioService _audioService = GlobalAudioService();

  @override
  void initState() {
    super.initState();
    filteredSongs = widget.songs;
    searchController.addListener(_filterSongs);
  }

  void _filterSongs() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredSongs = widget.songs.where((song) {
        return song.title.toLowerCase().contains(query) ||
            song.artist.toLowerCase().contains(query) ||
            song.album.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Search Bar
              _buildSearchBar(),

              // Song List
              Expanded(
                child: _buildSongList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.songs.length} chansons',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Bouton Play All
          GestureDetector(
            onTap: () => _playAll(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF74B9FF), Color(0xFF0984e3)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF74B9FF).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Tout lire',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Rechercher une chanson...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSongList() {
    if (filteredSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 80,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              searchController.text.isNotEmpty
                  ? 'Aucune chanson trouvée'
                  : 'Aucune chanson disponible',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
        itemCount: filteredSongs.length,
        itemBuilder: (context, index) {
          final song = filteredSongs[index];

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildSongTile(song, index),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSongTile(SongModel song, int index) {
    return Consumer<GlobalAudioService>(
      builder: (context, audioService, child) {
        final isCurrentSong = audioService.currentSong?.id == song.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isCurrentSong
                ? const Color(0xFF6C5CE7).withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isCurrentSong
                  ? const Color(0xFF6C5CE7).withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: isCurrentSong
                      ? [const Color(0xFF6C5CE7), const Color(0xFF74B9FF)]
                      : [
                    Color(0xFF6C5CE7).withOpacity(0.7),
                    Color(0xFF74B9FF).withOpacity(0.7),
                  ],
                ),
              ),
              child: Center(
                child: isCurrentSong && audioService.isPlaying
                    ? const Icon(
                  Icons.graphic_eq,
                  color: Colors.white,
                  size: 24,
                )
                    : const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            title: Text(
              song.title,
              style: TextStyle(
                color: isCurrentSong
                    ? const Color(0xFF6C5CE7)
                    : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(
                  song.artist,
                  style: TextStyle(
                    color: isCurrentSong
                        ? const Color(0xFF6C5CE7).withOpacity(0.8)
                        : Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  song.displayDuration,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              onPressed: () => _playSong(song),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCurrentSong
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFF6C5CE7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCurrentSong && audioService.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: isCurrentSong
                      ? Colors.white
                      : const Color(0xFF6C5CE7),
                  size: 20,
                ),
              ),
            ),
            onTap: () => _playSong(song),
          ),
        );
      },
    );
  }

  Future<void> _playSong(SongModel song) async {
    print("Lecture de: ${song.title} - ${song.filePath}");

    // Jouer la chanson avec la playlist actuelle
    final success = await _audioService.playSong(song, playlist: filteredSongs);

    if (success) {
      // Afficher un feedback de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lecture: ${song.title}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF6C5CE7),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 10),
              const Text(
                'Impossible de lire cette chanson',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _playAll() async {
    if (filteredSongs.isEmpty) return;

    final success = await _audioService.playSong(filteredSongs.first, playlist: filteredSongs);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.playlist_play, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Lecture de toute la playlist',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF6C5CE7),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}