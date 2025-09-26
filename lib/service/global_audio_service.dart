import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';

class GlobalAudioService extends ChangeNotifier {
  static final GlobalAudioService _instance = GlobalAudioService._internal();
  factory GlobalAudioService() => _instance;
  GlobalAudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  List<SongModel> _currentPlaylist = [];
  int _currentIndex = 0;
  SongModel? _currentSong;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isShuffled = false;
  bool _isRepeated = false;
  bool _isInitialized = false;

  // Getters
  AudioPlayer get player => _player;
  SongModel? get currentSong => _currentSong;
  List<SongModel> get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isShuffled => _isShuffled;
  bool get isRepeated => _isRepeated;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    print("Initialisation du GlobalAudioService");

    // Écouter les changements d'état du lecteur
    _player.playerStateStream.listen((state) {
      print("État du lecteur changé: playing=${state.playing}, processingState=${state.processingState}");

      final wasPlaying = _isPlaying;
      final wasLoading = _isLoading;

      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      // Notifier seulement si l'état a changé
      if (wasPlaying != _isPlaying || wasLoading != _isLoading) {
        print("État notifié: isPlaying=$_isPlaying, isLoading=$_isLoading");
        notifyListeners();
      }

      // Auto-next quand la chanson se termine
      if (state.processingState == ProcessingState.completed) {
        print("Chanson terminée");
        if (_isRepeated) {
          print("Répétition activée - redémarrage");
          _player.seek(Duration.zero);
          _player.play();
        } else {
          print("Passage à la chanson suivante");
          nextSong();
        }
      }
    });

    // Écouter les erreurs
    _player.playbackEventStream.listen((event) {
      if (event.processingState == ProcessingState.idle &&
          event.updatePosition == Duration.zero) {
        print("Erreur possible détectée");
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  // Jouer une chanson spécifique
  Future<bool> playSong(SongModel song, {List<SongModel>? playlist}) async {
    try {
      print("Tentative de lecture de: ${song.title}");
      _isLoading = true;
      notifyListeners();

      // Arrêter d'abord la lecture actuelle
      await _player.stop();

      // Si une playlist est fournie, l'utiliser
      if (playlist != null) {
        _currentPlaylist = playlist;
        _currentIndex = playlist.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) {
          _currentPlaylist = [song];
          _currentIndex = 0;
        }
      } else if (_currentPlaylist.isEmpty) {
        _currentPlaylist = [song];
        _currentIndex = 0;
      } else {
        // Chercher la chanson dans la playlist actuelle
        int songIndex = _currentPlaylist.indexWhere((s) => s.id == song.id);
        if (songIndex != -1) {
          _currentIndex = songIndex;
        } else {
          _currentPlaylist.add(song);
          _currentIndex = _currentPlaylist.length - 1;
        }
      }

      _currentSong = song;
      print("Chargement du fichier: ${song.filePath}");

      // Charger le fichier audio
      await _player.setFilePath(song.filePath);

      // Démarrer la lecture
      await _player.play();

      print("Lecture démarrée avec succès");
      return true;
    } catch (e) {
      print("Erreur lors de la lecture: $e");
      _isLoading = false;
      _isPlaying = false;
      notifyListeners();
      return false;
    }
  }

  // Play/Pause avec gestion d'erreur améliorée
  Future<void> togglePlayPause() async {
    try {
      print("Toggle play/pause - État actuel: isPlaying=$_isPlaying");

      if (_currentSong == null) {
        print("Aucune chanson chargée");
        return;
      }

      if (_isPlaying) {
        print("Mise en pause...");
        await _player.pause();
      } else {
        print("Démarrage de la lecture...");
        await _player.play();
      }
    } catch (e) {
      print("Erreur toggle play/pause: $e");
      // En cas d'erreur, forcer la synchronisation
      _isPlaying = _player.playing;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Pause explicite
  Future<void> pause() async {
    try {
      print("Pause explicite");
      await _player.pause();
    } catch (e) {
      print("Erreur pause: $e");
    }
  }

  // Play explicite
  Future<void> play() async {
    try {
      print("Play explicite");
      if (_currentSong == null) {
        print("Aucune chanson à jouer");
        return;
      }
      await _player.play();
    } catch (e) {
      print("Erreur play: $e");
    }
  }

  // Stop explicite
  Future<void> stop() async {
    try {
      print("Stop explicite");
      await _player.stop();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      print("Erreur stop: $e");
    }
  }

  // Chanson suivante
  Future<void> nextSong() async {
    if (_currentPlaylist.isEmpty) return;

    print("Passage à la chanson suivante");
    int nextIndex;
    if (_isShuffled) {
      // Créer une liste mélangée sans modifier l'originale
      List<int> indices = List.generate(_currentPlaylist.length, (index) => index);
      indices.remove(_currentIndex); // Retirer l'index actuel
      indices.shuffle();
      nextIndex = indices.isNotEmpty ? indices.first : 0;
    } else {
      nextIndex = (_currentIndex + 1) % _currentPlaylist.length;
    }

    _currentIndex = nextIndex;
    await playSong(_currentPlaylist[nextIndex]);
  }

  // Chanson précédente
  Future<void> previousSong() async {
    if (_currentPlaylist.isEmpty) return;

    print("Chanson précédente");
    // Si on est à plus de 3 secondes, revenir au début
    if ((_player.position.inSeconds) > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    int prevIndex = (_currentIndex - 1 + _currentPlaylist.length) % _currentPlaylist.length;
    _currentIndex = prevIndex;
    await playSong(_currentPlaylist[prevIndex]);
  }

  // Seek
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print("Erreur seek: $e");
    }
  }

  // Toggle shuffle
  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    print("Shuffle ${_isShuffled ? 'activé' : 'désactivé'}");
    notifyListeners();
  }

  // Toggle repeat
  void toggleRepeat() {
    _isRepeated = !_isRepeated;
    print("Repeat ${_isRepeated ? 'activé' : 'désactivé'}");
    _player.setLoopMode(_isRepeated ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  // Forcer la synchronisation de l'état
  void forceStateSync() {
    print("Synchronisation forcée de l'état");
    _isPlaying = _player.playing;
    _isLoading = _player.processingState == ProcessingState.loading ||
        _player.processingState == ProcessingState.buffering;
    notifyListeners();
  }

  // Streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  void dispose() {
    print("Disposal du GlobalAudioService");
    _player.dispose();
    super.dispose();
  }
}