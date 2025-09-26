import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  List<SongModel> _currentPlaylist = [];
  int _currentIndex = 0;
  SongModel? _currentSong;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isShuffled = false;
  bool _isRepeated = false;

  // Getters
  AudioPlayer get player => _player;
  SongModel? get currentSong => _currentSong;
  List<SongModel> get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isShuffled => _isShuffled;
  bool get isRepeated => _isRepeated;

  AudioPlayerService() {
    _initializePlayer();
  }

  void _initializePlayer() {
    // Écouter les changements d'état
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      notifyListeners();

      // Auto-next quand la chanson se termine
      if (state.processingState == ProcessingState.completed) {
        if (_isRepeated) {
          _player.seek(Duration.zero);
          _player.play();
        } else {
          nextSong();
        }
      }
    });
  }

  // Charger une chanson spécifique
  Future<bool> loadSong(SongModel song) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _player.setFilePath(song.filePath);
      _currentSong = song;

      _isLoading = false;
      notifyListeners();

      print("Chanson chargée: ${song.title} - ${song.filePath}");
      return true;
    } catch (e) {
      print("Erreur lors du chargement de la chanson : $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Charger une playlist et jouer une chanson spécifique
  Future<bool> loadPlaylist(List<SongModel> playlist, int startIndex) async {
    try {
      if (playlist.isEmpty || startIndex < 0 || startIndex >= playlist.length) {
        return false;
      }

      _currentPlaylist = playlist;
      _currentIndex = startIndex;

      final success = await loadSong(playlist[startIndex]);
      return success;
    } catch (e) {
      print("Erreur lors du chargement de la playlist : $e");
      return false;
    }
  }

  // Jouer la chanson courante
  Future<void> play() async {
    try {
      if (_currentSong == null) {
        print("Aucune chanson chargée");
        return;
      }
      await _player.play();
    } catch (e) {
      print("Erreur lors de la lecture : $e");
    }
  }

  // Mettre en pause
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      print("Erreur lors de la pause : $e");
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  // Chanson suivante (CORRIGÉ)
  Future<bool> nextSong() async {
    if (_currentPlaylist.isEmpty) return false;

    int nextIndex;
    if (_isShuffled) {
      // Génération aléatoire excluant l'index actuel
      List<int> availableIndices = List.generate(_currentPlaylist.length, (i) => i);
      availableIndices.remove(_currentIndex);
      if (availableIndices.isEmpty) return false;
      availableIndices.shuffle();
      nextIndex = availableIndices.first;
    } else {
      nextIndex = (_currentIndex + 1) % _currentPlaylist.length;
    }

    _currentIndex = nextIndex;
    final success = await loadSong(_currentPlaylist[nextIndex]);
    if (success && _isPlaying) {
      await play();
    }
    return success;
  }

  // Chanson précédente (CORRIGÉ)
  Future<bool> previousSong() async {
    if (_currentPlaylist.isEmpty) return false;

    // Si on est à plus de 3 secondes, revenir au début
    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
      return true;
    }

    int prevIndex = (_currentIndex - 1 + _currentPlaylist.length) % _currentPlaylist.length;
    _currentIndex = prevIndex;
    final success = await loadSong(_currentPlaylist[prevIndex]);
    if (success && _isPlaying) {
      await play();
    }
    return success;
  }

  // Se positionner dans la chanson
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print("Erreur lors du seek : $e");
    }
  }

  // Toggle shuffle
  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    notifyListeners();
  }

  // Toggle repeat
  void toggleRepeat() {
    _isRepeated = !_isRepeated;
    _player.setLoopMode(_isRepeated ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  // Streams pour écouter les changements
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // Libérer les ressources
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}