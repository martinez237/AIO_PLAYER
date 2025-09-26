import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math';
import '../models/song_model.dart';

class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  List<SongModel> _playlist = [];
  List<SongModel> _originalPlaylist = [];
  int _currentIndex = 0;
  bool _shuffleMode = false;
  bool _repeatMode = false;

  MyAudioHandler() {
    _init();
  }

  void _init() {
    // Écouter les changements d'état du lecteur
    _player.playerStateStream.listen((state) {
      _updatePlaybackState(state);
    });

    // Écouter les changements de position
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    // Écouter la fin de la chanson
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleSongCompletion();
      }
    });
  }

  // Gérer la fin d'une chanson selon le mode de répétition
  Future<void> _handleSongCompletion() async {
    if (_repeatMode) {
      // Répéter la chanson actuelle
      await seek(Duration.zero);
      await play();
    } else {
      // Passer à la chanson suivante
      await skipToNext();
    }
  }

  // Charger une playlist et commencer la lecture
  Future<void> loadPlaylist(List<SongModel> playlist, int startIndex) async {
    _originalPlaylist = List.from(playlist);
    _playlist = List.from(playlist);
    _currentIndex = startIndex;

    // Appliquer le shuffle si activé
    if (_shuffleMode) {
      _shufflePlaylist();
    }

    if (playlist.isNotEmpty && startIndex < playlist.length) {
      await _loadCurrentSong();
    }
  }

  // Mélanger la playlist
  void _shufflePlaylist() {
    if (_playlist.isEmpty) return;

    // Sauvegarder la chanson actuelle
    final currentSong = _currentIndex < _playlist.length ? _playlist[_currentIndex] : null;

    // Mélanger la playlist
    _playlist.shuffle(Random());

    // Remettre la chanson actuelle en première position si elle existe
    if (currentSong != null) {
      final newIndex = _playlist.indexWhere((song) => song.id == currentSong.id);
      if (newIndex != -1 && newIndex != 0) {
        final temp = _playlist[0];
        _playlist[0] = _playlist[newIndex];
        _playlist[newIndex] = temp;
      }
      _currentIndex = 0;
    }
  }

  // Restaurer l'ordre original de la playlist
  void _restoreOriginalOrder() {
    if (_originalPlaylist.isEmpty) return;

    // Sauvegarder la chanson actuelle
    final currentSong = _currentIndex < _playlist.length ? _playlist[_currentIndex] : null;

    // Restaurer l'ordre original
    _playlist = List.from(_originalPlaylist);

    // Trouver l'index de la chanson actuelle dans l'ordre original
    if (currentSong != null) {
      _currentIndex = _playlist.indexWhere((song) => song.id == currentSong.id);
      if (_currentIndex == -1) _currentIndex = 0;
    }
  }

  // Charger la chanson actuelle
  Future<void> _loadCurrentSong() async {
    if (_playlist.isEmpty || _currentIndex >= _playlist.length) return;

    final song = _playlist[_currentIndex];

    try {
      // Charger le fichier audio
      await _player.setFilePath(song.filePath);

      // Mettre à jour les métadonnées pour la notification
      mediaItem.add(MediaItem(
        id: song.id,
        album: song.album,
        title: song.title,
        artist: song.artist,
        duration: song.duration,
        artUri: Uri.parse('https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300&h=300&fit=crop'), // Image par défaut
        extras: {
          'filePath': song.filePath,
        },
      ));

      print("Chanson chargée dans la notification: ${song.title}");
    } catch (e) {
      print("Erreur lors du chargement de la chanson: $e");
    }
  }

  // Mettre à jour l'état de lecture pour la notification
  void _updatePlaybackState(PlayerState state) {
    final isPlaying = state.playing;
    final processingState = state.processingState;

    AudioProcessingState audioProcessingState;
    switch (processingState) {
      case ProcessingState.idle:
        audioProcessingState = AudioProcessingState.idle;
        break;
      case ProcessingState.loading:
        audioProcessingState = AudioProcessingState.loading;
        break;
      case ProcessingState.buffering:
        audioProcessingState = AudioProcessingState.buffering;
        break;
      case ProcessingState.ready:
        audioProcessingState = AudioProcessingState.ready;
        break;
      case ProcessingState.completed:
        audioProcessingState = AudioProcessingState.completed;
        break;
    }

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (isPlaying) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: audioProcessingState,
      playing: isPlaying,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
      shuffleMode: _shuffleMode ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      repeatMode: _repeatMode ? AudioServiceRepeatMode.one : AudioServiceRepeatMode.none,
    ));
  }

  // Commandes de la notification

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      print("Erreur lors de la lecture: $e");
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      print("Erreur lors de la pause: $e");
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
      playbackState.add(PlaybackState(
        processingState: AudioProcessingState.idle,
        playing: false,
      ));
    } catch (e) {
      print("Erreur lors de l'arrêt: $e");
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print("Erreur lors du seek: $e");
    }
  }

  @override
  Future<void> skipToNext() async {
    if (_playlist.isEmpty) return;

    if (_playlist.length == 1) {
      // Une seule chanson dans la playlist
      if (_repeatMode) {
        await seek(Duration.zero);
        await play();
      }
      return;
    }

    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await _loadCurrentSong();
    if (playbackState.value.playing) {
      await play();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;

    // Si on est à plus de 3 secondes, revenir au début
    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_playlist.length == 1) {
      // Une seule chanson dans la playlist
      await seek(Duration.zero);
      if (playbackState.value.playing) {
        await play();
      }
      return;
    }

    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await _loadCurrentSong();
    if (playbackState.value.playing) {
      await play();
    }
  }

  // Gestion des modes shuffle et repeat
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _shuffleMode = shuffleMode == AudioServiceShuffleMode.all;

    if (_shuffleMode) {
      _shufflePlaylist();
    } else {
      _restoreOriginalOrder();
    }

    // Recharger la chanson actuelle après le changement d'ordre
    await _loadCurrentSong();

    // Mettre à jour l'état
    _updatePlaybackState(_player.playerState);

    print("Mode aléatoire ${_shuffleMode ? 'activé' : 'désactivé'}");
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _repeatMode = repeatMode == AudioServiceRepeatMode.one;

    // Mettre à jour l'état
    _updatePlaybackState(_player.playerState);

    print("Mode répétition ${_repeatMode ? 'activé' : 'désactivé'}");
  }

  // Getters
  AudioPlayer get player => _player;
  List<SongModel> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get shuffleMode => _shuffleMode;
  bool get repeatMode => _repeatMode;

  SongModel? get currentSong =>
      _playlist.isNotEmpty && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;

  @override
  Future<void> onTaskRemoved() async {
    // Arrêter la lecture quand l'app est fermée
    await stop();
  }
}