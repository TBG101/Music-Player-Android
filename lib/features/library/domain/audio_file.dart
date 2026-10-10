class AudioFile {
  static const _sentinel = Object();

  final int id;
  final String? title;
  final String? artist;
  final String? album;
  final int duration;
  final String uri;
  final int? albumId;
  final String? albumArt;
  final String? cachedArtPath;

  AudioFile({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.uri,
    required this.albumId,
    required this.albumArt,
    this.cachedArtPath,
  });

  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      id: json['id'] as int,
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      duration: json['duration'] as int,
      uri: json['uri'] as String,
      albumId: json['albumId'] as int?,
      albumArt: json['albumArt'] as String?,
      cachedArtPath: json['cachedArtPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration,
      'uri': uri,
      'albumId': albumId,
      'albumArt': albumArt,
      'cachedArtPath': cachedArtPath,
    };
  }

  AudioFile copyWith({
    int? id,
    Object? title = _sentinel,
    Object? artist = _sentinel,
    Object? album = _sentinel,
    int? duration,
    String? uri,
    int? albumId,
    Object? albumArt = _sentinel,
    Object? cachedArtPath = _sentinel,
  }) {
    return AudioFile(
      id: id ?? this.id,
      title: title == _sentinel ? this.title : title as String?,
      artist: artist == _sentinel ? this.artist : artist as String?,
      album: album == _sentinel ? this.album : album as String?,
      duration: duration ?? this.duration,
      uri: uri ?? this.uri,
      albumId: albumId ?? this.albumId,
      albumArt: albumArt == _sentinel ? this.albumArt : albumArt as String?,
      cachedArtPath: cachedArtPath == _sentinel
          ? this.cachedArtPath
          : cachedArtPath as String?,
    );
  }
}