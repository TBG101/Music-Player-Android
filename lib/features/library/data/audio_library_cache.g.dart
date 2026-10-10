// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_library_cache.dart';

// ignore_for_file: type=lint
class $AudioSongsTable extends AudioSongs
    with TableInfo<$AudioSongsTable, AudioSong> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioSongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
      'artist', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
      'album', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
      'uri', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _albumIdMeta =
      const VerificationMeta('albumId');
  @override
  late final GeneratedColumn<int> albumId = GeneratedColumn<int>(
      'album_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _albumArtMeta =
      const VerificationMeta('albumArt');
  @override
  late final GeneratedColumn<String> albumArt = GeneratedColumn<String>(
      'album_art', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cachedArtPathMeta =
      const VerificationMeta('cachedArtPath');
  @override
  late final GeneratedColumn<String> cachedArtPath = GeneratedColumn<String>(
      'cached_art_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        artist,
        album,
        duration,
        uri,
        albumId,
        albumArt,
        cachedArtPath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_songs';
  @override
  VerificationContext validateIntegrity(Insertable<AudioSong> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('artist')) {
      context.handle(_artistMeta,
          artist.isAcceptableOrUnknown(data['artist']!, _artistMeta));
    }
    if (data.containsKey('album')) {
      context.handle(
          _albumMeta, album.isAcceptableOrUnknown(data['album']!, _albumMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('uri')) {
      context.handle(
          _uriMeta, uri.isAcceptableOrUnknown(data['uri']!, _uriMeta));
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    }
    if (data.containsKey('album_art')) {
      context.handle(_albumArtMeta,
          albumArt.isAcceptableOrUnknown(data['album_art']!, _albumArtMeta));
    }
    if (data.containsKey('cached_art_path')) {
      context.handle(
          _cachedArtPathMeta,
          cachedArtPath.isAcceptableOrUnknown(
              data['cached_art_path']!, _cachedArtPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uri};
  @override
  AudioSong map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioSong(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist']),
      album: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album']),
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      uri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uri'])!,
      albumId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}album_id']),
      albumArt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_art']),
      cachedArtPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cached_art_path']),
    );
  }

  @override
  $AudioSongsTable createAlias(String alias) {
    return $AudioSongsTable(attachedDatabase, alias);
  }
}

class AudioSong extends DataClass implements Insertable<AudioSong> {
  final int id;
  final String? title;
  final String? artist;
  final String? album;
  final int duration;
  final String uri;
  final int? albumId;
  final String? albumArt;
  final String? cachedArtPath;
  const AudioSong(
      {required this.id,
      this.title,
      this.artist,
      this.album,
      required this.duration,
      required this.uri,
      this.albumId,
      this.albumArt,
      this.cachedArtPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    map['duration'] = Variable<int>(duration);
    map['uri'] = Variable<String>(uri);
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<int>(albumId);
    }
    if (!nullToAbsent || albumArt != null) {
      map['album_art'] = Variable<String>(albumArt);
    }
    if (!nullToAbsent || cachedArtPath != null) {
      map['cached_art_path'] = Variable<String>(cachedArtPath);
    }
    return map;
  }

  AudioSongsCompanion toCompanion(bool nullToAbsent) {
    return AudioSongsCompanion(
      id: Value(id),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      artist:
          artist == null && nullToAbsent ? const Value.absent() : Value(artist),
      album:
          album == null && nullToAbsent ? const Value.absent() : Value(album),
      duration: Value(duration),
      uri: Value(uri),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      albumArt: albumArt == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArt),
      cachedArtPath: cachedArtPath == null && nullToAbsent
          ? const Value.absent()
          : Value(cachedArtPath),
    );
  }

  factory AudioSong.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioSong(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      artist: serializer.fromJson<String?>(json['artist']),
      album: serializer.fromJson<String?>(json['album']),
      duration: serializer.fromJson<int>(json['duration']),
      uri: serializer.fromJson<String>(json['uri']),
      albumId: serializer.fromJson<int?>(json['albumId']),
      albumArt: serializer.fromJson<String?>(json['albumArt']),
      cachedArtPath: serializer.fromJson<String?>(json['cachedArtPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String?>(title),
      'artist': serializer.toJson<String?>(artist),
      'album': serializer.toJson<String?>(album),
      'duration': serializer.toJson<int>(duration),
      'uri': serializer.toJson<String>(uri),
      'albumId': serializer.toJson<int?>(albumId),
      'albumArt': serializer.toJson<String?>(albumArt),
      'cachedArtPath': serializer.toJson<String?>(cachedArtPath),
    };
  }

  AudioSong copyWith(
          {int? id,
          Value<String?> title = const Value.absent(),
          Value<String?> artist = const Value.absent(),
          Value<String?> album = const Value.absent(),
          int? duration,
          String? uri,
          Value<int?> albumId = const Value.absent(),
          Value<String?> albumArt = const Value.absent(),
          Value<String?> cachedArtPath = const Value.absent()}) =>
      AudioSong(
        id: id ?? this.id,
        title: title.present ? title.value : this.title,
        artist: artist.present ? artist.value : this.artist,
        album: album.present ? album.value : this.album,
        duration: duration ?? this.duration,
        uri: uri ?? this.uri,
        albumId: albumId.present ? albumId.value : this.albumId,
        albumArt: albumArt.present ? albumArt.value : this.albumArt,
        cachedArtPath:
            cachedArtPath.present ? cachedArtPath.value : this.cachedArtPath,
      );
  AudioSong copyWithCompanion(AudioSongsCompanion data) {
    return AudioSong(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      duration: data.duration.present ? data.duration.value : this.duration,
      uri: data.uri.present ? data.uri.value : this.uri,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      albumArt: data.albumArt.present ? data.albumArt.value : this.albumArt,
      cachedArtPath: data.cachedArtPath.present
          ? data.cachedArtPath.value
          : this.cachedArtPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioSong(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('duration: $duration, ')
          ..write('uri: $uri, ')
          ..write('albumId: $albumId, ')
          ..write('albumArt: $albumArt, ')
          ..write('cachedArtPath: $cachedArtPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, artist, album, duration, uri,
      albumId, albumArt, cachedArtPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioSong &&
          other.id == this.id &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.duration == this.duration &&
          other.uri == this.uri &&
          other.albumId == this.albumId &&
          other.albumArt == this.albumArt &&
          other.cachedArtPath == this.cachedArtPath);
}

class AudioSongsCompanion extends UpdateCompanion<AudioSong> {
  final Value<int> id;
  final Value<String?> title;
  final Value<String?> artist;
  final Value<String?> album;
  final Value<int> duration;
  final Value<String> uri;
  final Value<int?> albumId;
  final Value<String?> albumArt;
  final Value<String?> cachedArtPath;
  final Value<int> rowid;
  const AudioSongsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.duration = const Value.absent(),
    this.uri = const Value.absent(),
    this.albumId = const Value.absent(),
    this.albumArt = const Value.absent(),
    this.cachedArtPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudioSongsCompanion.insert({
    required int id,
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    required int duration,
    required String uri,
    this.albumId = const Value.absent(),
    this.albumArt = const Value.absent(),
    this.cachedArtPath = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        duration = Value(duration),
        uri = Value(uri);
  static Insertable<AudioSong> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<int>? duration,
    Expression<String>? uri,
    Expression<int>? albumId,
    Expression<String>? albumArt,
    Expression<String>? cachedArtPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (duration != null) 'duration': duration,
      if (uri != null) 'uri': uri,
      if (albumId != null) 'album_id': albumId,
      if (albumArt != null) 'album_art': albumArt,
      if (cachedArtPath != null) 'cached_art_path': cachedArtPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudioSongsCompanion copyWith(
      {Value<int>? id,
      Value<String?>? title,
      Value<String?>? artist,
      Value<String?>? album,
      Value<int>? duration,
      Value<String>? uri,
      Value<int?>? albumId,
      Value<String?>? albumArt,
      Value<String?>? cachedArtPath,
      Value<int>? rowid}) {
    return AudioSongsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      uri: uri ?? this.uri,
      albumId: albumId ?? this.albumId,
      albumArt: albumArt ?? this.albumArt,
      cachedArtPath: cachedArtPath ?? this.cachedArtPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<int>(albumId.value);
    }
    if (albumArt.present) {
      map['album_art'] = Variable<String>(albumArt.value);
    }
    if (cachedArtPath.present) {
      map['cached_art_path'] = Variable<String>(cachedArtPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioSongsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('duration: $duration, ')
          ..write('uri: $uri, ')
          ..write('albumId: $albumId, ')
          ..write('albumArt: $albumArt, ')
          ..write('cachedArtPath: $cachedArtPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AudioLibraryCache extends GeneratedDatabase {
  _$AudioLibraryCache(QueryExecutor e) : super(e);
  $AudioLibraryCacheManager get managers => $AudioLibraryCacheManager(this);
  late final $AudioSongsTable audioSongs = $AudioSongsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [audioSongs];
}

typedef $$AudioSongsTableCreateCompanionBuilder = AudioSongsCompanion Function({
  required int id,
  Value<String?> title,
  Value<String?> artist,
  Value<String?> album,
  required int duration,
  required String uri,
  Value<int?> albumId,
  Value<String?> albumArt,
  Value<String?> cachedArtPath,
  Value<int> rowid,
});
typedef $$AudioSongsTableUpdateCompanionBuilder = AudioSongsCompanion Function({
  Value<int> id,
  Value<String?> title,
  Value<String?> artist,
  Value<String?> album,
  Value<int> duration,
  Value<String> uri,
  Value<int?> albumId,
  Value<String?> albumArt,
  Value<String?> cachedArtPath,
  Value<int> rowid,
});

class $$AudioSongsTableFilterComposer
    extends Composer<_$AudioLibraryCache, $AudioSongsTable> {
  $$AudioSongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uri => $composableBuilder(
      column: $table.uri, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get albumId => $composableBuilder(
      column: $table.albumId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get albumArt => $composableBuilder(
      column: $table.albumArt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cachedArtPath => $composableBuilder(
      column: $table.cachedArtPath, builder: (column) => ColumnFilters(column));
}

class $$AudioSongsTableOrderingComposer
    extends Composer<_$AudioLibraryCache, $AudioSongsTable> {
  $$AudioSongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get album => $composableBuilder(
      column: $table.album, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uri => $composableBuilder(
      column: $table.uri, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get albumId => $composableBuilder(
      column: $table.albumId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get albumArt => $composableBuilder(
      column: $table.albumArt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cachedArtPath => $composableBuilder(
      column: $table.cachedArtPath,
      builder: (column) => ColumnOrderings(column));
}

class $$AudioSongsTableAnnotationComposer
    extends Composer<_$AudioLibraryCache, $AudioSongsTable> {
  $$AudioSongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<int> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<String> get albumArt =>
      $composableBuilder(column: $table.albumArt, builder: (column) => column);

  GeneratedColumn<String> get cachedArtPath => $composableBuilder(
      column: $table.cachedArtPath, builder: (column) => column);
}

class $$AudioSongsTableTableManager extends RootTableManager<
    _$AudioLibraryCache,
    $AudioSongsTable,
    AudioSong,
    $$AudioSongsTableFilterComposer,
    $$AudioSongsTableOrderingComposer,
    $$AudioSongsTableAnnotationComposer,
    $$AudioSongsTableCreateCompanionBuilder,
    $$AudioSongsTableUpdateCompanionBuilder,
    (
      AudioSong,
      BaseReferences<_$AudioLibraryCache, $AudioSongsTable, AudioSong>
    ),
    AudioSong,
    PrefetchHooks Function()> {
  $$AudioSongsTableTableManager(_$AudioLibraryCache db, $AudioSongsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioSongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioSongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioSongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> artist = const Value.absent(),
            Value<String?> album = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<String> uri = const Value.absent(),
            Value<int?> albumId = const Value.absent(),
            Value<String?> albumArt = const Value.absent(),
            Value<String?> cachedArtPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AudioSongsCompanion(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            uri: uri,
            albumId: albumId,
            albumArt: albumArt,
            cachedArtPath: cachedArtPath,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int id,
            Value<String?> title = const Value.absent(),
            Value<String?> artist = const Value.absent(),
            Value<String?> album = const Value.absent(),
            required int duration,
            required String uri,
            Value<int?> albumId = const Value.absent(),
            Value<String?> albumArt = const Value.absent(),
            Value<String?> cachedArtPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AudioSongsCompanion.insert(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            uri: uri,
            albumId: albumId,
            albumArt: albumArt,
            cachedArtPath: cachedArtPath,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AudioSongsTableProcessedTableManager = ProcessedTableManager<
    _$AudioLibraryCache,
    $AudioSongsTable,
    AudioSong,
    $$AudioSongsTableFilterComposer,
    $$AudioSongsTableOrderingComposer,
    $$AudioSongsTableAnnotationComposer,
    $$AudioSongsTableCreateCompanionBuilder,
    $$AudioSongsTableUpdateCompanionBuilder,
    (
      AudioSong,
      BaseReferences<_$AudioLibraryCache, $AudioSongsTable, AudioSong>
    ),
    AudioSong,
    PrefetchHooks Function()>;

class $AudioLibraryCacheManager {
  final _$AudioLibraryCache _db;
  $AudioLibraryCacheManager(this._db);
  $$AudioSongsTableTableManager get audioSongs =>
      $$AudioSongsTableTableManager(_db, _db.audioSongs);
}
