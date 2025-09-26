import 'dart:io';

class SongModel {
  final String id;
  final String title;
  final String artist;
  final String? albumArtPath;
  final String filePath;
  final Duration duration;
  final String album;
  final File file;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.albumArtPath,
    required this.filePath,
    required this.duration,
    required this.album,
    required this.file,
  });

  String get displayDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class PlaylistModel {
  final String id;
  final String name;
  final List<SongModel> songs;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.songs,
  });

  int get numOfSongs => songs.length;
}