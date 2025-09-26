import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/song_model.dart';

class MusicService {
  static List<SongModel> _cachedSongs = [];
  static List<PlaylistModel> _cachedPlaylists = [];
  static const String _cacheKey = 'cached_songs';

  // PERMISSIONS CORRIGÉES pour Android 13+
  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33+)
      if (await Permission.audio.status.isDenied) {
        var audioStatus = await Permission.audio.request();
        if (audioStatus.isGranted) return true;
      }

      // Android 12 et inférieur
      if (await Permission.storage.status.isDenied) {
        var storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) return true;
      }

      // Vérifier les permissions de lecture de fichiers média
      if (await Permission.audio.status.isGranted ||
          await Permission.storage.status.isGranted) {
        return true;
      }

      // Dernière tentative avec manageExternalStorage pour Android 11+
      if (await Permission.manageExternalStorage.status.isDenied) {
        await Permission.manageExternalStorage.request();
      }

      return await Permission.audio.status.isGranted ||
          await Permission.storage.status.isGranted ||
          await Permission.manageExternalStorage.status.isGranted;
    }
    return true;
  }

  // CACHE PERSISTANT
  static Future<void> _saveCacheToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsJson = _cachedSongs.map((song) => {
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'filePath': song.filePath,
        'duration': song.duration.inSeconds,
        'album': song.album,
      }).toList();

      await prefs.setString(_cacheKey, jsonEncode(songsJson));
      print("Cache sauvegardé: ${_cachedSongs.length} chansons");
    } catch (e) {
      print("Erreur lors de la sauvegarde du cache: $e");
    }
  }

  static Future<void> _loadCacheFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_cacheKey);

      if (cacheString != null) {
        final List<dynamic> songsJson = jsonDecode(cacheString);
        _cachedSongs = songsJson.map((json) {
          return SongModel(
            id: json['id'],
            title: json['title'],
            artist: json['artist'],
            filePath: json['filePath'],
            duration: Duration(seconds: json['duration']),
            album: json['album'],
            file: File(json['filePath']),
          );
        }).where((song) => File(song.filePath).existsSync()).toList(); // Vérifier que le fichier existe encore

        print("Cache chargé: ${_cachedSongs.length} chansons");
      }
    } catch (e) {
      print("Erreur lors du chargement du cache: $e");
      _cachedSongs = [];
    }
  }

  // Méthode 1: Sélection manuelle de fichiers
  static Future<List<SongModel>> pickAudioFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        List<SongModel> songs = [];

        for (var file in result.files) {
          if (file.path != null) {
            final audioFile = File(file.path!);
            final song = await _createSongFromFile(audioFile);
            if (song != null) {
              songs.add(song);
            }
          }
        }

        _cachedSongs = songs;
        await _saveCacheToPrefs();
        return songs;
      }
    } catch (e) {
      print("Erreur lors de la sélection des fichiers: $e");
    }
    return [];
  }

  // SCAN OPTIMISÉ avec limitation et cache
  static Future<List<SongModel>> scanMusicFolders({bool useCache = true}) async {
    // Charger le cache d'abord
    if (useCache) {
      await _loadCacheFromPrefs();
      if (_cachedSongs.isNotEmpty) {
        print("Utilisation du cache existant");
        return _cachedSongs;
      }
    }

    bool hasPermission = await requestPermission();
    if (!hasPermission) {
      print("Permissions refusées");
      return [];
    }

    List<SongModel> allSongs = [];

    try {
      // DOSSIERS OPTIMISÉS
      List<String> musicPaths = await _getMusicDirectories();

      int totalFiles = 0;
      const maxFiles = 1000; // Limitation pour éviter la lenteur

      for (String path in musicPaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          print("Scan du dossier: $path");
          int filesInDir = await _scanDirectory(dir, allSongs, maxFiles - totalFiles);
          totalFiles += filesInDir;

          if (totalFiles >= maxFiles) {
            print("Limite de $maxFiles fichiers atteinte");
            break;
          }
        }
      }

      print("Scan terminé: ${allSongs.length} chansons trouvées");
      _cachedSongs = allSongs;
      await _saveCacheToPrefs();
      return allSongs;
    } catch (e) {
      print("Erreur lors du scan des dossiers: $e");
      return [];
    }
  }

  static Future<List<String>> _getMusicDirectories() async {
    List<String> paths = [];

    try {
      // Dossiers standard Android
      if (Platform.isAndroid) {
        paths.addAll([
          '/storage/emulated/0/Music',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/sdcard/Music',
          '/sdcard/Download',
        ]);

        // Dossier Music de l'application
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final musicDir = Directory('${directory.parent.parent.parent.parent.path}/Music');
          if (await musicDir.exists()) {
            paths.add(musicDir.path);
          }
        }
      }
    } catch (e) {
      print("Erreur lors de la récupération des dossiers: $e");
    }

    return paths;
  }

  static Future<int> _scanDirectory(Directory dir, List<SongModel> songs, int maxFiles) async {
    int filesScanned = 0;

    try {
      await for (var entity in dir.list(recursive: false)) { // Pas récursif pour la performance
        if (filesScanned >= maxFiles) break;

        if (entity is File) {
          String extension = entity.path.toLowerCase().split('.').last;
          if (['mp3', 'wav', 'flac', 'm4a', 'aac', 'ogg', 'wma'].contains(extension)) {
            final song = await _createSongFromFile(entity);
            if (song != null) {
              songs.add(song);
              filesScanned++;
            }
          }
        } else if (entity is Directory && entity.path.split('/').last != '.' && entity.path.split('/').last != '..') {
          // Scanner récursivement les sous-dossiers avec limitation
          int subFiles = await _scanDirectory(entity, songs, maxFiles - filesScanned);
          filesScanned += subFiles;
        }
      }
    } catch (e) {
      print("Erreur lors du scan du dossier ${dir.path}: $e");
    }

    return filesScanned;
  }

  // CRÉATION DE SONG AMÉLIORÉE
  static Future<SongModel?> _createSongFromFile(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final nameWithoutExtension = fileName.split('.').first;

      // Essayer d'extraire le titre et l'artiste du nom de fichier
      String title = nameWithoutExtension;
      String artist = "Artiste inconnu";
      String album = "Album inconnu";

      // Formats communs de nommage
      if (nameWithoutExtension.contains(' - ')) {
        final parts = nameWithoutExtension.split(' - ');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts.sublist(1).join(' - ').trim();
        }
      } else if (nameWithoutExtension.contains('_')) {
        final parts = nameWithoutExtension.split('_');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts.sublist(1).join(' ').trim();
        }
      }

      // DURÉE APPROXIMATIVE AMÉLIORÉE (basée sur le bitrate moyen)
      final fileSize = await file.length();
      final estimatedBitrate = 128000; // 128 kbps en moyenne
      final duration = Duration(seconds: (fileSize * 8 / estimatedBitrate).round());

      return SongModel(
        id: "${file.path.hashCode}_${file.lastModifiedSync().millisecondsSinceEpoch}",
        title: title,
        artist: artist,
        filePath: file.path,
        duration: duration,
        album: album,
        file: file,
      );
    } catch (e) {
      print("Erreur lors de la création du modèle de chanson: $e");
      return null;
    }
  }

  // PLAYLISTS AMÉLIORÉES
  static Future<List<PlaylistModel>> createBasicPlaylists() async {
    if (_cachedSongs.isEmpty) {
      await scanMusicFolders();
    }

    List<PlaylistModel> playlists = [];

    // Toutes les chansons
    if (_cachedSongs.isNotEmpty) {
      playlists.add(PlaylistModel(
        id: 'all_songs',
        name: 'Toutes les chansons (${_cachedSongs.length})',
        songs: _cachedSongs,
      ));
    }

    // Playlists par artiste
    Map<String, List<SongModel>> artistGroups = {};
    for (var song in _cachedSongs) {
      if (!artistGroups.containsKey(song.artist)) {
        artistGroups[song.artist] = [];
      }
      artistGroups[song.artist]!.add(song);
    }

    artistGroups.forEach((artist, songs) {
      if (songs.length > 1 && artist != "Artiste inconnu") {
        playlists.add(PlaylistModel(
          id: "artist_${artist.hashCode}",
          name: "$artist (${songs.length})",
          songs: songs,
        ));
      }
    });

    // Récemment ajoutées (basé sur la date de modification)
    var recentSongs = List<SongModel>.from(_cachedSongs);
    recentSongs.sort((a, b) => b.file.lastModifiedSync().compareTo(a.file.lastModifiedSync()));
    if (recentSongs.length > 10) {
      playlists.add(PlaylistModel(
        id: 'recent',
        name: 'Récemment ajoutées',
        songs: recentSongs.take(20).toList(),
      ));
    }

    _cachedPlaylists = playlists;
    return playlists;
  }

  // Rafraîchir le cache
  static Future<List<SongModel>> refreshCache() async {
    _cachedSongs.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    return await scanMusicFolders(useCache: false);
  }

  static List<SongModel> getCachedSongs() => _cachedSongs;
  static List<PlaylistModel> getCachedPlaylists() => _cachedPlaylists;
}