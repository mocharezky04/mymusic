// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $SearchHistoryRowsTable extends SearchHistoryRows
    with TableInfo<$SearchHistoryRowsTable, SearchHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoryRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
    'term',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, term, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_history_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('term')) {
      context.handle(
        _termMeta,
        term.isAcceptableOrUnknown(data['term']!, _termMeta),
      );
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SearchHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      term: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SearchHistoryRowsTable createAlias(String alias) {
    return $SearchHistoryRowsTable(attachedDatabase, alias);
  }
}

class SearchHistoryRow extends DataClass
    implements Insertable<SearchHistoryRow> {
  final int id;
  final String term;
  final DateTime createdAt;
  const SearchHistoryRow({
    required this.id,
    required this.term,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['term'] = Variable<String>(term);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SearchHistoryRowsCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoryRowsCompanion(
      id: Value(id),
      term: Value(term),
      createdAt: Value(createdAt),
    );
  }

  factory SearchHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryRow(
      id: serializer.fromJson<int>(json['id']),
      term: serializer.fromJson<String>(json['term']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'term': serializer.toJson<String>(term),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SearchHistoryRow copyWith({int? id, String? term, DateTime? createdAt}) =>
      SearchHistoryRow(
        id: id ?? this.id,
        term: term ?? this.term,
        createdAt: createdAt ?? this.createdAt,
      );
  SearchHistoryRow copyWithCompanion(SearchHistoryRowsCompanion data) {
    return SearchHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      term: data.term.present ? data.term.value : this.term,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryRow(')
          ..write('id: $id, ')
          ..write('term: $term, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, term, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryRow &&
          other.id == this.id &&
          other.term == this.term &&
          other.createdAt == this.createdAt);
}

class SearchHistoryRowsCompanion extends UpdateCompanion<SearchHistoryRow> {
  final Value<int> id;
  final Value<String> term;
  final Value<DateTime> createdAt;
  const SearchHistoryRowsCompanion({
    this.id = const Value.absent(),
    this.term = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SearchHistoryRowsCompanion.insert({
    this.id = const Value.absent(),
    required String term,
    required DateTime createdAt,
  }) : term = Value(term),
       createdAt = Value(createdAt);
  static Insertable<SearchHistoryRow> custom({
    Expression<int>? id,
    Expression<String>? term,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (term != null) 'term': term,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SearchHistoryRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? term,
    Value<DateTime>? createdAt,
  }) {
    return SearchHistoryRowsCompanion(
      id: id ?? this.id,
      term: term ?? this.term,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryRowsCompanion(')
          ..write('id: $id, ')
          ..write('term: $term, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $QueueRowsTable extends QueueRows
    with TableInfo<$QueueRowsTable, QueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _thumbMeta = const VerificationMeta('thumb');
  @override
  late final GeneratedColumn<String> thumb = GeneratedColumn<String>(
    'thumb',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _uploaderMeta = const VerificationMeta(
    'uploader',
  );
  @override
  late final GeneratedColumn<String> uploader = GeneratedColumn<String>(
    'uploader',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    position,
    id,
    source,
    title,
    artist,
    duration,
    thumb,
    uploader,
    url,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('thumb')) {
      context.handle(
        _thumbMeta,
        thumb.isAcceptableOrUnknown(data['thumb']!, _thumbMeta),
      );
    }
    if (data.containsKey('uploader')) {
      context.handle(
        _uploaderMeta,
        uploader.isAcceptableOrUnknown(data['uploader']!, _uploaderMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  QueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueRow(
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      thumb: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb'],
      )!,
      uploader: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uploader'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
    );
  }

  @override
  $QueueRowsTable createAlias(String alias) {
    return $QueueRowsTable(attachedDatabase, alias);
  }
}

class QueueRow extends DataClass implements Insertable<QueueRow> {
  final int position;
  final String id;
  final String source;
  final String title;
  final String artist;
  final int duration;
  final String thumb;
  final String uploader;
  final String url;
  const QueueRow({
    required this.position,
    required this.id,
    required this.source,
    required this.title,
    required this.artist,
    required this.duration,
    required this.thumb,
    required this.uploader,
    required this.url,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['position'] = Variable<int>(position);
    map['id'] = Variable<String>(id);
    map['source'] = Variable<String>(source);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['duration'] = Variable<int>(duration);
    map['thumb'] = Variable<String>(thumb);
    map['uploader'] = Variable<String>(uploader);
    map['url'] = Variable<String>(url);
    return map;
  }

  QueueRowsCompanion toCompanion(bool nullToAbsent) {
    return QueueRowsCompanion(
      position: Value(position),
      id: Value(id),
      source: Value(source),
      title: Value(title),
      artist: Value(artist),
      duration: Value(duration),
      thumb: Value(thumb),
      uploader: Value(uploader),
      url: Value(url),
    );
  }

  factory QueueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueRow(
      position: serializer.fromJson<int>(json['position']),
      id: serializer.fromJson<String>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      duration: serializer.fromJson<int>(json['duration']),
      thumb: serializer.fromJson<String>(json['thumb']),
      uploader: serializer.fromJson<String>(json['uploader']),
      url: serializer.fromJson<String>(json['url']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'position': serializer.toJson<int>(position),
      'id': serializer.toJson<String>(id),
      'source': serializer.toJson<String>(source),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'duration': serializer.toJson<int>(duration),
      'thumb': serializer.toJson<String>(thumb),
      'uploader': serializer.toJson<String>(uploader),
      'url': serializer.toJson<String>(url),
    };
  }

  QueueRow copyWith({
    int? position,
    String? id,
    String? source,
    String? title,
    String? artist,
    int? duration,
    String? thumb,
    String? uploader,
    String? url,
  }) => QueueRow(
    position: position ?? this.position,
    id: id ?? this.id,
    source: source ?? this.source,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    duration: duration ?? this.duration,
    thumb: thumb ?? this.thumb,
    uploader: uploader ?? this.uploader,
    url: url ?? this.url,
  );
  QueueRow copyWithCompanion(QueueRowsCompanion data) {
    return QueueRow(
      position: data.position.present ? data.position.value : this.position,
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      duration: data.duration.present ? data.duration.value : this.duration,
      thumb: data.thumb.present ? data.thumb.value : this.thumb,
      uploader: data.uploader.present ? data.uploader.value : this.uploader,
      url: data.url.present ? data.url.value : this.url,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueRow(')
          ..write('position: $position, ')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('duration: $duration, ')
          ..write('thumb: $thumb, ')
          ..write('uploader: $uploader, ')
          ..write('url: $url')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    position,
    id,
    source,
    title,
    artist,
    duration,
    thumb,
    uploader,
    url,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueRow &&
          other.position == this.position &&
          other.id == this.id &&
          other.source == this.source &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.duration == this.duration &&
          other.thumb == this.thumb &&
          other.uploader == this.uploader &&
          other.url == this.url);
}

class QueueRowsCompanion extends UpdateCompanion<QueueRow> {
  final Value<int> position;
  final Value<String> id;
  final Value<String> source;
  final Value<String> title;
  final Value<String> artist;
  final Value<int> duration;
  final Value<String> thumb;
  final Value<String> uploader;
  final Value<String> url;
  final Value<int> rowid;
  const QueueRowsCompanion({
    this.position = const Value.absent(),
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.duration = const Value.absent(),
    this.thumb = const Value.absent(),
    this.uploader = const Value.absent(),
    this.url = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueueRowsCompanion.insert({
    required int position,
    required String id,
    required String source,
    required String title,
    this.artist = const Value.absent(),
    this.duration = const Value.absent(),
    this.thumb = const Value.absent(),
    this.uploader = const Value.absent(),
    this.url = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : position = Value(position),
       id = Value(id),
       source = Value(source),
       title = Value(title);
  static Insertable<QueueRow> custom({
    Expression<int>? position,
    Expression<String>? id,
    Expression<String>? source,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<int>? duration,
    Expression<String>? thumb,
    Expression<String>? uploader,
    Expression<String>? url,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (position != null) 'position': position,
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (duration != null) 'duration': duration,
      if (thumb != null) 'thumb': thumb,
      if (uploader != null) 'uploader': uploader,
      if (url != null) 'url': url,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueueRowsCompanion copyWith({
    Value<int>? position,
    Value<String>? id,
    Value<String>? source,
    Value<String>? title,
    Value<String>? artist,
    Value<int>? duration,
    Value<String>? thumb,
    Value<String>? uploader,
    Value<String>? url,
    Value<int>? rowid,
  }) {
    return QueueRowsCompanion(
      position: position ?? this.position,
      id: id ?? this.id,
      source: source ?? this.source,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      thumb: thumb ?? this.thumb,
      uploader: uploader ?? this.uploader,
      url: url ?? this.url,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (thumb.present) {
      map['thumb'] = Variable<String>(thumb.value);
    }
    if (uploader.present) {
      map['uploader'] = Variable<String>(uploader.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueRowsCompanion(')
          ..write('position: $position, ')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('duration: $duration, ')
          ..write('thumb: $thumb, ')
          ..write('uploader: $uploader, ')
          ..write('url: $url, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetaRowsTable extends MetaRows with TableInfo<$MetaRowsTable, MetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetaRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meta_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  MetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $MetaRowsTable createAlias(String alias) {
    return $MetaRowsTable(attachedDatabase, alias);
  }
}

class MetaRow extends DataClass implements Insertable<MetaRow> {
  final String key;
  final String value;
  const MetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MetaRowsCompanion toCompanion(bool nullToAbsent) {
    return MetaRowsCompanion(key: Value(key), value: Value(value));
  }

  factory MetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MetaRow copyWith({String? key, String? value}) =>
      MetaRow(key: key ?? this.key, value: value ?? this.value);
  MetaRow copyWithCompanion(MetaRowsCompanion data) {
    return MetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetaRow && other.key == this.key && other.value == this.value);
}

class MetaRowsCompanion extends UpdateCompanion<MetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MetaRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetaRowsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetaRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MetaRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetaRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadsRowsTable extends DownloadsRows
    with TableInfo<$DownloadsRowsTable, DownloadsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _thumbMeta = const VerificationMeta('thumb');
  @override
  late final GeneratedColumn<String> thumb = GeneratedColumn<String>(
    'thumb',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _uploaderMeta = const VerificationMeta(
    'uploader',
  );
  @override
  late final GeneratedColumn<String> uploader = GeneratedColumn<String>(
    'uploader',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    source,
    title,
    artist,
    duration,
    thumb,
    uploader,
    url,
    filePath,
    sizeBytes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('thumb')) {
      context.handle(
        _thumbMeta,
        thumb.isAcceptableOrUnknown(data['thumb']!, _thumbMeta),
      );
    }
    if (data.containsKey('uploader')) {
      context.handle(
        _uploaderMeta,
        uploader.isAcceptableOrUnknown(data['uploader']!, _uploaderMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  DownloadsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      thumb: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb'],
      )!,
      uploader: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uploader'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DownloadsRowsTable createAlias(String alias) {
    return $DownloadsRowsTable(attachedDatabase, alias);
  }
}

class DownloadsRow extends DataClass implements Insertable<DownloadsRow> {
  final String id;
  final String source;
  final String title;
  final String artist;
  final int duration;
  final String thumb;
  final String uploader;
  final String url;
  final String filePath;
  final int sizeBytes;
  final DateTime createdAt;
  const DownloadsRow({
    required this.id,
    required this.source,
    required this.title,
    required this.artist,
    required this.duration,
    required this.thumb,
    required this.uploader,
    required this.url,
    required this.filePath,
    required this.sizeBytes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source'] = Variable<String>(source);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['duration'] = Variable<int>(duration);
    map['thumb'] = Variable<String>(thumb);
    map['uploader'] = Variable<String>(uploader);
    map['url'] = Variable<String>(url);
    map['file_path'] = Variable<String>(filePath);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DownloadsRowsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsRowsCompanion(
      id: Value(id),
      source: Value(source),
      title: Value(title),
      artist: Value(artist),
      duration: Value(duration),
      thumb: Value(thumb),
      uploader: Value(uploader),
      url: Value(url),
      filePath: Value(filePath),
      sizeBytes: Value(sizeBytes),
      createdAt: Value(createdAt),
    );
  }

  factory DownloadsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadsRow(
      id: serializer.fromJson<String>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      duration: serializer.fromJson<int>(json['duration']),
      thumb: serializer.fromJson<String>(json['thumb']),
      uploader: serializer.fromJson<String>(json['uploader']),
      url: serializer.fromJson<String>(json['url']),
      filePath: serializer.fromJson<String>(json['filePath']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'source': serializer.toJson<String>(source),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'duration': serializer.toJson<int>(duration),
      'thumb': serializer.toJson<String>(thumb),
      'uploader': serializer.toJson<String>(uploader),
      'url': serializer.toJson<String>(url),
      'filePath': serializer.toJson<String>(filePath),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DownloadsRow copyWith({
    String? id,
    String? source,
    String? title,
    String? artist,
    int? duration,
    String? thumb,
    String? uploader,
    String? url,
    String? filePath,
    int? sizeBytes,
    DateTime? createdAt,
  }) => DownloadsRow(
    id: id ?? this.id,
    source: source ?? this.source,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    duration: duration ?? this.duration,
    thumb: thumb ?? this.thumb,
    uploader: uploader ?? this.uploader,
    url: url ?? this.url,
    filePath: filePath ?? this.filePath,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    createdAt: createdAt ?? this.createdAt,
  );
  DownloadsRow copyWithCompanion(DownloadsRowsCompanion data) {
    return DownloadsRow(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      duration: data.duration.present ? data.duration.value : this.duration,
      thumb: data.thumb.present ? data.thumb.value : this.thumb,
      uploader: data.uploader.present ? data.uploader.value : this.uploader,
      url: data.url.present ? data.url.value : this.url,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsRow(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('duration: $duration, ')
          ..write('thumb: $thumb, ')
          ..write('uploader: $uploader, ')
          ..write('url: $url, ')
          ..write('filePath: $filePath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    source,
    title,
    artist,
    duration,
    thumb,
    uploader,
    url,
    filePath,
    sizeBytes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadsRow &&
          other.id == this.id &&
          other.source == this.source &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.duration == this.duration &&
          other.thumb == this.thumb &&
          other.uploader == this.uploader &&
          other.url == this.url &&
          other.filePath == this.filePath &&
          other.sizeBytes == this.sizeBytes &&
          other.createdAt == this.createdAt);
}

class DownloadsRowsCompanion extends UpdateCompanion<DownloadsRow> {
  final Value<String> id;
  final Value<String> source;
  final Value<String> title;
  final Value<String> artist;
  final Value<int> duration;
  final Value<String> thumb;
  final Value<String> uploader;
  final Value<String> url;
  final Value<String> filePath;
  final Value<int> sizeBytes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DownloadsRowsCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.duration = const Value.absent(),
    this.thumb = const Value.absent(),
    this.uploader = const Value.absent(),
    this.url = const Value.absent(),
    this.filePath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsRowsCompanion.insert({
    required String id,
    required String source,
    required String title,
    this.artist = const Value.absent(),
    this.duration = const Value.absent(),
    this.thumb = const Value.absent(),
    this.uploader = const Value.absent(),
    this.url = const Value.absent(),
    required String filePath,
    this.sizeBytes = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       source = Value(source),
       title = Value(title),
       filePath = Value(filePath),
       createdAt = Value(createdAt);
  static Insertable<DownloadsRow> custom({
    Expression<String>? id,
    Expression<String>? source,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<int>? duration,
    Expression<String>? thumb,
    Expression<String>? uploader,
    Expression<String>? url,
    Expression<String>? filePath,
    Expression<int>? sizeBytes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (duration != null) 'duration': duration,
      if (thumb != null) 'thumb': thumb,
      if (uploader != null) 'uploader': uploader,
      if (url != null) 'url': url,
      if (filePath != null) 'file_path': filePath,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? source,
    Value<String>? title,
    Value<String>? artist,
    Value<int>? duration,
    Value<String>? thumb,
    Value<String>? uploader,
    Value<String>? url,
    Value<String>? filePath,
    Value<int>? sizeBytes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DownloadsRowsCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      thumb: thumb ?? this.thumb,
      uploader: uploader ?? this.uploader,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (thumb.present) {
      map['thumb'] = Variable<String>(thumb.value);
    }
    if (uploader.present) {
      map['uploader'] = Variable<String>(uploader.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsRowsCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('duration: $duration, ')
          ..write('thumb: $thumb, ')
          ..write('uploader: $uploader, ')
          ..write('url: $url, ')
          ..write('filePath: $filePath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackHistoryRowsTable extends PlaybackHistoryRows
    with TableInfo<$PlaybackHistoryRowsTable, PlaybackHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackHistoryRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _thumbMeta = const VerificationMeta('thumb');
  @override
  late final GeneratedColumn<String> thumb = GeneratedColumn<String>(
    'thumb',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _uploaderMeta = const VerificationMeta(
    'uploader',
  );
  @override
  late final GeneratedColumn<String> uploader = GeneratedColumn<String>(
    'uploader',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playsMeta = const VerificationMeta('plays');
  @override
  late final GeneratedColumn<int> plays = GeneratedColumn<int>(
    'plays',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackId,
    source,
    title,
    artist,
    duration,
    thumb,
    uploader,
    url,
    playedAt,
    plays,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_history_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('thumb')) {
      context.handle(
        _thumbMeta,
        thumb.isAcceptableOrUnknown(data['thumb']!, _thumbMeta),
      );
    }
    if (data.containsKey('uploader')) {
      context.handle(
        _uploaderMeta,
        uploader.isAcceptableOrUnknown(data['uploader']!, _uploaderMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    if (data.containsKey('plays')) {
      context.handle(
        _playsMeta,
        plays.isAcceptableOrUnknown(data['plays']!, _playsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaybackHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      thumb: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb'],
      )!,
      uploader: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uploader'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
      plays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plays'],
      )!,
    );
  }

  @override
  $PlaybackHistoryRowsTable createAlias(String alias) {
    return $PlaybackHistoryRowsTable(attachedDatabase, alias);
  }
}

class PlaybackHistoryRow extends DataClass
    implements Insertable<PlaybackHistoryRow> {
  final int id;
  final String trackId;
  final String source;
  final String title;
  final String artist;
  final int duration;
  final String thumb;
  final String uploader;
  final String url;
  final DateTime playedAt;
  final int plays;
  const PlaybackHistoryRow({
    required this.id,
    required this.trackId,
    required this.source,
    required this.title,
    required this.artist,
    required this.duration,
    required this.thumb,
    required this.uploader,
    required this.url,
    required this.playedAt,
    required this.plays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<String>(trackId);
    map['source'] = Variable<String>(source);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['duration'] = Variable<int>(duration);
    map['thumb'] = Variable<String>(thumb);
    map['uploader'] = Variable<String>(uploader);
    map['url'] = Variable<String>(url);
    map['played_at'] = Variable<DateTime>(playedAt);
    map['plays'] = Variable<int>(plays);
    return map;
  }

  PlaybackHistoryRowsCompanion toCompanion(bool nullToAbsent) {
    return PlaybackHistoryRowsCompanion(
      id: Value(id),
      trackId: Value(trackId),
      source: Value(source),
      title: Value(title),
      artist: Value(artist),
      duration: Value(duration),
      thumb: Value(thumb),
      uploader: Value(uploader),
      url: Value(url),
      playedAt: Value(playedAt),
      plays: Value(plays),
    );
  }

  factory PlaybackHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackHistoryRow(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<String>(json['trackId']),
      source: serializer.fromJson<String>(json['source']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      duration: serializer.fromJson<int>(json['duration']),
      thumb: serializer.fromJson<String>(json['thumb']),
      uploader: serializer.fromJson<String>(json['uploader']),
      url: serializer.fromJson<String>(json['url']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
      plays: serializer.fromJson<int>(json['plays']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<String>(trackId),
      'source': serializer.toJson<String>(source),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'duration': serializer.toJson<int>(duration),
      'thumb': serializer.toJson<String>(thumb),
      'uploader': serializer.toJson<String>(uploader),
      'url': serializer.toJson<String>(url),
      'playedAt': serializer.toJson<DateTime>(playedAt),
      'plays': serializer.toJson<int>(plays),
    };
  }

  PlaybackHistoryRow copyWith({
    int? id,
    String? trackId,
    String? source,
    String? title,
    String? artist,
    int? duration,
    String? thumb,
    String? uploader,
    String? url,
    DateTime? playedAt,
    int? plays,
  }) => PlaybackHistoryRow(
    id: id ?? this.id,
    trackId: trackId ?? this.trackId,
    source: source ?? this.source,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    duration: duration ?? this.duration,
    thumb: thumb ?? this.thumb,
    uploader: uploader ?? this.uploader,
    url: url ?? this.url,
    playedAt: playedAt ?? this.playedAt,
    plays: plays ?? this.plays,
  );
  PlaybackHistoryRow copyWithCompanion(PlaybackHistoryRowsCompanion data) {
    return PlaybackHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      source: data.source.present ? data.source.value : this.source,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      duration: data.duration.present ? data.duration.value : this.duration,
      thumb: data.thumb.present ? data.thumb.value : this.thumb,
      uploader: data.uploader.present ? data.uploader.value : this.uploader,
      url: data.url.present ? data.url.value : this.url,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      plays: data.plays.present ? data.plays.value : this.plays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackHistoryRow(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('source: $source, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('duration: $duration, ')
          ..write('thumb: $thumb, ')
          ..write('uploader: $uploader, ')
          ..write('url: $url, ')
          ..write('playedAt: $playedAt, ')
          ..write('plays: $plays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trackId,
    source,
    title,
    artist,
    duration,
    thumb,
    uploader,
    url,
    playedAt,
    plays,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackHistoryRow &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.source == this.source &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.duration == this.duration &&
          other.thumb == this.thumb &&
          other.uploader == this.uploader &&
          other.url == this.url &&
          other.playedAt == this.playedAt &&
          other.plays == this.plays);
}

class PlaybackHistoryRowsCompanion extends UpdateCompanion<PlaybackHistoryRow> {
  final Value<int> id;
  final Value<String> trackId;
  final Value<String> source;
  final Value<String> title;
  final Value<String> artist;
  final Value<int> duration;
  final Value<String> thumb;
  final Value<String> uploader;
  final Value<String> url;
  final Value<DateTime> playedAt;
  final Value<int> plays;
  const PlaybackHistoryRowsCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.source = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.duration = const Value.absent(),
    this.thumb = const Value.absent(),
    this.uploader = const Value.absent(),
    this.url = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.plays = const Value.absent(),
  });
  PlaybackHistoryRowsCompanion.insert({
    this.id = const Value.absent(),
    required String trackId,
    required String source,
    required String title,
    this.artist = const Value.absent(),
    this.duration = const Value.absent(),
    this.thumb = const Value.absent(),
    this.uploader = const Value.absent(),
    this.url = const Value.absent(),
    required DateTime playedAt,
    this.plays = const Value.absent(),
  }) : trackId = Value(trackId),
       source = Value(source),
       title = Value(title),
       playedAt = Value(playedAt);
  static Insertable<PlaybackHistoryRow> custom({
    Expression<int>? id,
    Expression<String>? trackId,
    Expression<String>? source,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<int>? duration,
    Expression<String>? thumb,
    Expression<String>? uploader,
    Expression<String>? url,
    Expression<DateTime>? playedAt,
    Expression<int>? plays,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (source != null) 'source': source,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (duration != null) 'duration': duration,
      if (thumb != null) 'thumb': thumb,
      if (uploader != null) 'uploader': uploader,
      if (url != null) 'url': url,
      if (playedAt != null) 'played_at': playedAt,
      if (plays != null) 'plays': plays,
    });
  }

  PlaybackHistoryRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? trackId,
    Value<String>? source,
    Value<String>? title,
    Value<String>? artist,
    Value<int>? duration,
    Value<String>? thumb,
    Value<String>? uploader,
    Value<String>? url,
    Value<DateTime>? playedAt,
    Value<int>? plays,
  }) {
    return PlaybackHistoryRowsCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      source: source ?? this.source,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      thumb: thumb ?? this.thumb,
      uploader: uploader ?? this.uploader,
      url: url ?? this.url,
      playedAt: playedAt ?? this.playedAt,
      plays: plays ?? this.plays,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (thumb.present) {
      map['thumb'] = Variable<String>(thumb.value);
    }
    if (uploader.present) {
      map['uploader'] = Variable<String>(uploader.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (plays.present) {
      map['plays'] = Variable<int>(plays.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackHistoryRowsCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('source: $source, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('duration: $duration, ')
          ..write('thumb: $thumb, ')
          ..write('uploader: $uploader, ')
          ..write('url: $url, ')
          ..write('playedAt: $playedAt, ')
          ..write('plays: $plays')
          ..write(')'))
        .toString();
  }
}

class $SavedMixRowsTable extends SavedMixRows
    with TableInfo<$SavedMixRowsTable, SavedMixRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedMixRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mixIdMeta = const VerificationMeta('mixId');
  @override
  late final GeneratedColumn<String> mixId = GeneratedColumn<String>(
    'mix_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('youtube'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [mixId, title, source, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_mix_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedMixRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mix_id')) {
      context.handle(
        _mixIdMeta,
        mixId.isAcceptableOrUnknown(data['mix_id']!, _mixIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mixIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  SavedMixRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedMixRow(
      mixId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mix_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SavedMixRowsTable createAlias(String alias) {
    return $SavedMixRowsTable(attachedDatabase, alias);
  }
}

class SavedMixRow extends DataClass implements Insertable<SavedMixRow> {
  final String mixId;
  final String title;
  final String source;
  final DateTime createdAt;
  const SavedMixRow({
    required this.mixId,
    required this.title,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mix_id'] = Variable<String>(mixId);
    map['title'] = Variable<String>(title);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SavedMixRowsCompanion toCompanion(bool nullToAbsent) {
    return SavedMixRowsCompanion(
      mixId: Value(mixId),
      title: Value(title),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory SavedMixRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedMixRow(
      mixId: serializer.fromJson<String>(json['mixId']),
      title: serializer.fromJson<String>(json['title']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mixId': serializer.toJson<String>(mixId),
      'title': serializer.toJson<String>(title),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SavedMixRow copyWith({
    String? mixId,
    String? title,
    String? source,
    DateTime? createdAt,
  }) => SavedMixRow(
    mixId: mixId ?? this.mixId,
    title: title ?? this.title,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  SavedMixRow copyWithCompanion(SavedMixRowsCompanion data) {
    return SavedMixRow(
      mixId: data.mixId.present ? data.mixId.value : this.mixId,
      title: data.title.present ? data.title.value : this.title,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedMixRow(')
          ..write('mixId: $mixId, ')
          ..write('title: $title, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mixId, title, source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedMixRow &&
          other.mixId == this.mixId &&
          other.title == this.title &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class SavedMixRowsCompanion extends UpdateCompanion<SavedMixRow> {
  final Value<String> mixId;
  final Value<String> title;
  final Value<String> source;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SavedMixRowsCompanion({
    this.mixId = const Value.absent(),
    this.title = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedMixRowsCompanion.insert({
    required String mixId,
    this.title = const Value.absent(),
    this.source = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : mixId = Value(mixId),
       createdAt = Value(createdAt);
  static Insertable<SavedMixRow> custom({
    Expression<String>? mixId,
    Expression<String>? title,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mixId != null) 'mix_id': mixId,
      if (title != null) 'title': title,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedMixRowsCompanion copyWith({
    Value<String>? mixId,
    Value<String>? title,
    Value<String>? source,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SavedMixRowsCompanion(
      mixId: mixId ?? this.mixId,
      title: title ?? this.title,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mixId.present) {
      map['mix_id'] = Variable<String>(mixId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedMixRowsCompanion(')
          ..write('mixId: $mixId, ')
          ..write('title: $title, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SearchHistoryRowsTable searchHistoryRows =
      $SearchHistoryRowsTable(this);
  late final $QueueRowsTable queueRows = $QueueRowsTable(this);
  late final $MetaRowsTable metaRows = $MetaRowsTable(this);
  late final $DownloadsRowsTable downloadsRows = $DownloadsRowsTable(this);
  late final $PlaybackHistoryRowsTable playbackHistoryRows =
      $PlaybackHistoryRowsTable(this);
  late final $SavedMixRowsTable savedMixRows = $SavedMixRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    searchHistoryRows,
    queueRows,
    metaRows,
    downloadsRows,
    playbackHistoryRows,
    savedMixRows,
  ];
}

typedef $$SearchHistoryRowsTableCreateCompanionBuilder =
    SearchHistoryRowsCompanion Function({
      Value<int> id,
      required String term,
      required DateTime createdAt,
    });
typedef $$SearchHistoryRowsTableUpdateCompanionBuilder =
    SearchHistoryRowsCompanion Function({
      Value<int> id,
      Value<String> term,
      Value<DateTime> createdAt,
    });

class $$SearchHistoryRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SearchHistoryRowsTable> {
  $$SearchHistoryRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchHistoryRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchHistoryRowsTable> {
  $$SearchHistoryRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchHistoryRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchHistoryRowsTable> {
  $$SearchHistoryRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SearchHistoryRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchHistoryRowsTable,
          SearchHistoryRow,
          $$SearchHistoryRowsTableFilterComposer,
          $$SearchHistoryRowsTableOrderingComposer,
          $$SearchHistoryRowsTableAnnotationComposer,
          $$SearchHistoryRowsTableCreateCompanionBuilder,
          $$SearchHistoryRowsTableUpdateCompanionBuilder,
          (
            SearchHistoryRow,
            BaseReferences<
              _$AppDatabase,
              $SearchHistoryRowsTable,
              SearchHistoryRow
            >,
          ),
          SearchHistoryRow,
          PrefetchHooks Function()
        > {
  $$SearchHistoryRowsTableTableManager(
    _$AppDatabase db,
    $SearchHistoryRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchHistoryRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchHistoryRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchHistoryRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> term = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SearchHistoryRowsCompanion(
                id: id,
                term: term,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String term,
                required DateTime createdAt,
              }) => SearchHistoryRowsCompanion.insert(
                id: id,
                term: term,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoryRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchHistoryRowsTable,
      SearchHistoryRow,
      $$SearchHistoryRowsTableFilterComposer,
      $$SearchHistoryRowsTableOrderingComposer,
      $$SearchHistoryRowsTableAnnotationComposer,
      $$SearchHistoryRowsTableCreateCompanionBuilder,
      $$SearchHistoryRowsTableUpdateCompanionBuilder,
      (
        SearchHistoryRow,
        BaseReferences<
          _$AppDatabase,
          $SearchHistoryRowsTable,
          SearchHistoryRow
        >,
      ),
      SearchHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$QueueRowsTableCreateCompanionBuilder = QueueRowsCompanion Function({
  required int position,
  required String id,
  required String source,
  required String title,
  Value<String> artist,
  Value<int> duration,
  Value<String> thumb,
  Value<String> uploader,
  Value<String> url,
  Value<int> rowid,
});
typedef $$QueueRowsTableUpdateCompanionBuilder = QueueRowsCompanion Function({
  Value<int> position,
  Value<String> id,
  Value<String> source,
  Value<String> title,
  Value<String> artist,
  Value<int> duration,
  Value<String> thumb,
  Value<String> uploader,
  Value<String> url,
  Value<int> rowid,
});

class $$QueueRowsTableFilterComposer
    extends Composer<_$AppDatabase, $QueueRowsTable> {
  $$QueueRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumb => $composableBuilder(
    column: $table.thumb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploader => $composableBuilder(
    column: $table.uploader,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueueRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $QueueRowsTable> {
  $$QueueRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumb => $composableBuilder(
    column: $table.thumb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploader => $composableBuilder(
    column: $table.uploader,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueueRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueueRowsTable> {
  $$QueueRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get thumb =>
      $composableBuilder(column: $table.thumb, builder: (column) => column);

  GeneratedColumn<String> get uploader =>
      $composableBuilder(column: $table.uploader, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);
}

class $$QueueRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QueueRowsTable,
          QueueRow,
          $$QueueRowsTableFilterComposer,
          $$QueueRowsTableOrderingComposer,
          $$QueueRowsTableAnnotationComposer,
          $$QueueRowsTableCreateCompanionBuilder,
          $$QueueRowsTableUpdateCompanionBuilder,
          (QueueRow, BaseReferences<_$AppDatabase, $QueueRowsTable, QueueRow>),
          QueueRow,
          PrefetchHooks Function()
        > {
  $$QueueRowsTableTableManager(_$AppDatabase db, $QueueRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> position = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String> thumb = const Value.absent(),
                Value<String> uploader = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueueRowsCompanion(
                position: position,
                id: id,
                source: source,
                title: title,
                artist: artist,
                duration: duration,
                thumb: thumb,
                uploader: uploader,
                url: url,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int position,
                required String id,
                required String source,
                required String title,
                Value<String> artist = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String> thumb = const Value.absent(),
                Value<String> uploader = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueueRowsCompanion.insert(
                position: position,
                id: id,
                source: source,
                title: title,
                artist: artist,
                duration: duration,
                thumb: thumb,
                uploader: uploader,
                url: url,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueueRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QueueRowsTable,
      QueueRow,
      $$QueueRowsTableFilterComposer,
      $$QueueRowsTableOrderingComposer,
      $$QueueRowsTableAnnotationComposer,
      $$QueueRowsTableCreateCompanionBuilder,
      $$QueueRowsTableUpdateCompanionBuilder,
      (QueueRow, BaseReferences<_$AppDatabase, $QueueRowsTable, QueueRow>),
      QueueRow,
      PrefetchHooks Function()
    >;
typedef $$MetaRowsTableCreateCompanionBuilder = MetaRowsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$MetaRowsTableUpdateCompanionBuilder = MetaRowsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$MetaRowsTableFilterComposer
    extends Composer<_$AppDatabase, $MetaRowsTable> {
  $$MetaRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetaRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $MetaRowsTable> {
  $$MetaRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetaRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetaRowsTable> {
  $$MetaRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MetaRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetaRowsTable,
          MetaRow,
          $$MetaRowsTableFilterComposer,
          $$MetaRowsTableOrderingComposer,
          $$MetaRowsTableAnnotationComposer,
          $$MetaRowsTableCreateCompanionBuilder,
          $$MetaRowsTableUpdateCompanionBuilder,
          (MetaRow, BaseReferences<_$AppDatabase, $MetaRowsTable, MetaRow>),
          MetaRow,
          PrefetchHooks Function()
        > {
  $$MetaRowsTableTableManager(_$AppDatabase db, $MetaRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetaRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetaRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetaRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => MetaRowsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => MetaRowsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetaRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetaRowsTable,
      MetaRow,
      $$MetaRowsTableFilterComposer,
      $$MetaRowsTableOrderingComposer,
      $$MetaRowsTableAnnotationComposer,
      $$MetaRowsTableCreateCompanionBuilder,
      $$MetaRowsTableUpdateCompanionBuilder,
      (MetaRow, BaseReferences<_$AppDatabase, $MetaRowsTable, MetaRow>),
      MetaRow,
      PrefetchHooks Function()
    >;
typedef $$DownloadsRowsTableCreateCompanionBuilder =
    DownloadsRowsCompanion Function({
      required String id,
      required String source,
      required String title,
      Value<String> artist,
      Value<int> duration,
      Value<String> thumb,
      Value<String> uploader,
      Value<String> url,
      required String filePath,
      Value<int> sizeBytes,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DownloadsRowsTableUpdateCompanionBuilder =
    DownloadsRowsCompanion Function({
      Value<String> id,
      Value<String> source,
      Value<String> title,
      Value<String> artist,
      Value<int> duration,
      Value<String> thumb,
      Value<String> uploader,
      Value<String> url,
      Value<String> filePath,
      Value<int> sizeBytes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$DownloadsRowsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadsRowsTable> {
  $$DownloadsRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumb => $composableBuilder(
    column: $table.thumb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploader => $composableBuilder(
    column: $table.uploader,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadsRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadsRowsTable> {
  $$DownloadsRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumb => $composableBuilder(
    column: $table.thumb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploader => $composableBuilder(
    column: $table.uploader,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadsRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadsRowsTable> {
  $$DownloadsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get thumb =>
      $composableBuilder(column: $table.thumb, builder: (column) => column);

  GeneratedColumn<String> get uploader =>
      $composableBuilder(column: $table.uploader, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DownloadsRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadsRowsTable,
          DownloadsRow,
          $$DownloadsRowsTableFilterComposer,
          $$DownloadsRowsTableOrderingComposer,
          $$DownloadsRowsTableAnnotationComposer,
          $$DownloadsRowsTableCreateCompanionBuilder,
          $$DownloadsRowsTableUpdateCompanionBuilder,
          (
            DownloadsRow,
            BaseReferences<_$AppDatabase, $DownloadsRowsTable, DownloadsRow>,
          ),
          DownloadsRow,
          PrefetchHooks Function()
        > {
  $$DownloadsRowsTableTableManager(_$AppDatabase db, $DownloadsRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String> thumb = const Value.absent(),
                Value<String> uploader = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadsRowsCompanion(
                id: id,
                source: source,
                title: title,
                artist: artist,
                duration: duration,
                thumb: thumb,
                uploader: uploader,
                url: url,
                filePath: filePath,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String source,
                required String title,
                Value<String> artist = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String> thumb = const Value.absent(),
                Value<String> uploader = const Value.absent(),
                Value<String> url = const Value.absent(),
                required String filePath,
                Value<int> sizeBytes = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadsRowsCompanion.insert(
                id: id,
                source: source,
                title: title,
                artist: artist,
                duration: duration,
                thumb: thumb,
                uploader: uploader,
                url: url,
                filePath: filePath,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadsRowsTable,
      DownloadsRow,
      $$DownloadsRowsTableFilterComposer,
      $$DownloadsRowsTableOrderingComposer,
      $$DownloadsRowsTableAnnotationComposer,
      $$DownloadsRowsTableCreateCompanionBuilder,
      $$DownloadsRowsTableUpdateCompanionBuilder,
      (
        DownloadsRow,
        BaseReferences<_$AppDatabase, $DownloadsRowsTable, DownloadsRow>,
      ),
      DownloadsRow,
      PrefetchHooks Function()
    >;
typedef $$PlaybackHistoryRowsTableCreateCompanionBuilder =
    PlaybackHistoryRowsCompanion Function({
      Value<int> id,
      required String trackId,
      required String source,
      required String title,
      Value<String> artist,
      Value<int> duration,
      Value<String> thumb,
      Value<String> uploader,
      Value<String> url,
      required DateTime playedAt,
      Value<int> plays,
    });
typedef $$PlaybackHistoryRowsTableUpdateCompanionBuilder =
    PlaybackHistoryRowsCompanion Function({
      Value<int> id,
      Value<String> trackId,
      Value<String> source,
      Value<String> title,
      Value<String> artist,
      Value<int> duration,
      Value<String> thumb,
      Value<String> uploader,
      Value<String> url,
      Value<DateTime> playedAt,
      Value<int> plays,
    });

class $$PlaybackHistoryRowsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackHistoryRowsTable> {
  $$PlaybackHistoryRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumb => $composableBuilder(
    column: $table.thumb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploader => $composableBuilder(
    column: $table.uploader,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plays => $composableBuilder(
    column: $table.plays,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaybackHistoryRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackHistoryRowsTable> {
  $$PlaybackHistoryRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumb => $composableBuilder(
    column: $table.thumb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploader => $composableBuilder(
    column: $table.uploader,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plays => $composableBuilder(
    column: $table.plays,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaybackHistoryRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackHistoryRowsTable> {
  $$PlaybackHistoryRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get thumb =>
      $composableBuilder(column: $table.thumb, builder: (column) => column);

  GeneratedColumn<String> get uploader =>
      $composableBuilder(column: $table.uploader, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  GeneratedColumn<int> get plays =>
      $composableBuilder(column: $table.plays, builder: (column) => column);
}

class $$PlaybackHistoryRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaybackHistoryRowsTable,
          PlaybackHistoryRow,
          $$PlaybackHistoryRowsTableFilterComposer,
          $$PlaybackHistoryRowsTableOrderingComposer,
          $$PlaybackHistoryRowsTableAnnotationComposer,
          $$PlaybackHistoryRowsTableCreateCompanionBuilder,
          $$PlaybackHistoryRowsTableUpdateCompanionBuilder,
          (
            PlaybackHistoryRow,
            BaseReferences<
              _$AppDatabase,
              $PlaybackHistoryRowsTable,
              PlaybackHistoryRow
            >,
          ),
          PlaybackHistoryRow,
          PrefetchHooks Function()
        > {
  $$PlaybackHistoryRowsTableTableManager(
    _$AppDatabase db,
    $PlaybackHistoryRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackHistoryRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackHistoryRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlaybackHistoryRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String> thumb = const Value.absent(),
                Value<String> uploader = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
                Value<int> plays = const Value.absent(),
              }) => PlaybackHistoryRowsCompanion(
                id: id,
                trackId: trackId,
                source: source,
                title: title,
                artist: artist,
                duration: duration,
                thumb: thumb,
                uploader: uploader,
                url: url,
                playedAt: playedAt,
                plays: plays,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String trackId,
                required String source,
                required String title,
                Value<String> artist = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String> thumb = const Value.absent(),
                Value<String> uploader = const Value.absent(),
                Value<String> url = const Value.absent(),
                required DateTime playedAt,
                Value<int> plays = const Value.absent(),
              }) => PlaybackHistoryRowsCompanion.insert(
                id: id,
                trackId: trackId,
                source: source,
                title: title,
                artist: artist,
                duration: duration,
                thumb: thumb,
                uploader: uploader,
                url: url,
                playedAt: playedAt,
                plays: plays,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaybackHistoryRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaybackHistoryRowsTable,
      PlaybackHistoryRow,
      $$PlaybackHistoryRowsTableFilterComposer,
      $$PlaybackHistoryRowsTableOrderingComposer,
      $$PlaybackHistoryRowsTableAnnotationComposer,
      $$PlaybackHistoryRowsTableCreateCompanionBuilder,
      $$PlaybackHistoryRowsTableUpdateCompanionBuilder,
      (
        PlaybackHistoryRow,
        BaseReferences<
          _$AppDatabase,
          $PlaybackHistoryRowsTable,
          PlaybackHistoryRow
        >,
      ),
      PlaybackHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$SavedMixRowsTableCreateCompanionBuilder =
    SavedMixRowsCompanion Function({
      required String mixId,
      Value<String> title,
      Value<String> source,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SavedMixRowsTableUpdateCompanionBuilder =
    SavedMixRowsCompanion Function({
      Value<String> mixId,
      Value<String> title,
      Value<String> source,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SavedMixRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedMixRowsTable> {
  $$SavedMixRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mixId => $composableBuilder(
    column: $table.mixId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedMixRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedMixRowsTable> {
  $$SavedMixRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mixId => $composableBuilder(
    column: $table.mixId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedMixRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedMixRowsTable> {
  $$SavedMixRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mixId =>
      $composableBuilder(column: $table.mixId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SavedMixRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedMixRowsTable,
          SavedMixRow,
          $$SavedMixRowsTableFilterComposer,
          $$SavedMixRowsTableOrderingComposer,
          $$SavedMixRowsTableAnnotationComposer,
          $$SavedMixRowsTableCreateCompanionBuilder,
          $$SavedMixRowsTableUpdateCompanionBuilder,
          (
            SavedMixRow,
            BaseReferences<_$AppDatabase, $SavedMixRowsTable, SavedMixRow>,
          ),
          SavedMixRow,
          PrefetchHooks Function()
        > {
  $$SavedMixRowsTableTableManager(_$AppDatabase db, $SavedMixRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedMixRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedMixRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedMixRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> mixId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedMixRowsCompanion(
                mixId: mixId,
                title: title,
                source: source,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mixId,
                Value<String> title = const Value.absent(),
                Value<String> source = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedMixRowsCompanion.insert(
                mixId: mixId,
                title: title,
                source: source,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedMixRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedMixRowsTable,
      SavedMixRow,
      $$SavedMixRowsTableFilterComposer,
      $$SavedMixRowsTableOrderingComposer,
      $$SavedMixRowsTableAnnotationComposer,
      $$SavedMixRowsTableCreateCompanionBuilder,
      $$SavedMixRowsTableUpdateCompanionBuilder,
      (
        SavedMixRow,
        BaseReferences<_$AppDatabase, $SavedMixRowsTable, SavedMixRow>,
      ),
      SavedMixRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SearchHistoryRowsTableTableManager get searchHistoryRows =>
      $$SearchHistoryRowsTableTableManager(_db, _db.searchHistoryRows);
  $$QueueRowsTableTableManager get queueRows =>
      $$QueueRowsTableTableManager(_db, _db.queueRows);
  $$MetaRowsTableTableManager get metaRows =>
      $$MetaRowsTableTableManager(_db, _db.metaRows);
  $$DownloadsRowsTableTableManager get downloadsRows =>
      $$DownloadsRowsTableTableManager(_db, _db.downloadsRows);
  $$PlaybackHistoryRowsTableTableManager get playbackHistoryRows =>
      $$PlaybackHistoryRowsTableTableManager(_db, _db.playbackHistoryRows);
  $$SavedMixRowsTableTableManager get savedMixRows =>
      $$SavedMixRowsTableTableManager(_db, _db.savedMixRows);
}
