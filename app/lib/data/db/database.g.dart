// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SciencesTable extends Sciences with TableInfo<$SciencesTable, Science> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SciencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionArMeta = const VerificationMeta(
    'descriptionAr',
  );
  @override
  late final GeneratedColumn<String> descriptionAr = GeneratedColumn<String>(
    'description_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    slug,
    nameAr,
    descriptionAr,
    icon,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sciences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Science> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(
        _nameArMeta,
        nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta),
      );
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('description_ar')) {
      context.handle(
        _descriptionArMeta,
        descriptionAr.isAcceptableOrUnknown(
          data['description_ar']!,
          _descriptionArMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slug};
  @override
  Science map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Science(
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      descriptionAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_ar'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $SciencesTable createAlias(String alias) {
    return $SciencesTable(attachedDatabase, alias);
  }
}

class Science extends DataClass implements Insertable<Science> {
  final String slug;
  final String nameAr;
  final String? descriptionAr;
  final String? icon;
  final int sortOrder;
  const Science({
    required this.slug,
    required this.nameAr,
    this.descriptionAr,
    this.icon,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slug'] = Variable<String>(slug);
    map['name_ar'] = Variable<String>(nameAr);
    if (!nullToAbsent || descriptionAr != null) {
      map['description_ar'] = Variable<String>(descriptionAr);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  SciencesCompanion toCompanion(bool nullToAbsent) {
    return SciencesCompanion(
      slug: Value(slug),
      nameAr: Value(nameAr),
      descriptionAr: descriptionAr == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionAr),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      sortOrder: Value(sortOrder),
    );
  }

  factory Science.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Science(
      slug: serializer.fromJson<String>(json['slug']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      descriptionAr: serializer.fromJson<String?>(json['descriptionAr']),
      icon: serializer.fromJson<String?>(json['icon']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slug': serializer.toJson<String>(slug),
      'nameAr': serializer.toJson<String>(nameAr),
      'descriptionAr': serializer.toJson<String?>(descriptionAr),
      'icon': serializer.toJson<String?>(icon),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Science copyWith({
    String? slug,
    String? nameAr,
    Value<String?> descriptionAr = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    int? sortOrder,
  }) => Science(
    slug: slug ?? this.slug,
    nameAr: nameAr ?? this.nameAr,
    descriptionAr: descriptionAr.present
        ? descriptionAr.value
        : this.descriptionAr,
    icon: icon.present ? icon.value : this.icon,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Science copyWithCompanion(SciencesCompanion data) {
    return Science(
      slug: data.slug.present ? data.slug.value : this.slug,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      descriptionAr: data.descriptionAr.present
          ? data.descriptionAr.value
          : this.descriptionAr,
      icon: data.icon.present ? data.icon.value : this.icon,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Science(')
          ..write('slug: $slug, ')
          ..write('nameAr: $nameAr, ')
          ..write('descriptionAr: $descriptionAr, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(slug, nameAr, descriptionAr, icon, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Science &&
          other.slug == this.slug &&
          other.nameAr == this.nameAr &&
          other.descriptionAr == this.descriptionAr &&
          other.icon == this.icon &&
          other.sortOrder == this.sortOrder);
}

class SciencesCompanion extends UpdateCompanion<Science> {
  final Value<String> slug;
  final Value<String> nameAr;
  final Value<String?> descriptionAr;
  final Value<String?> icon;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const SciencesCompanion({
    this.slug = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.descriptionAr = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SciencesCompanion.insert({
    required String slug,
    required String nameAr,
    this.descriptionAr = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : slug = Value(slug),
       nameAr = Value(nameAr);
  static Insertable<Science> custom({
    Expression<String>? slug,
    Expression<String>? nameAr,
    Expression<String>? descriptionAr,
    Expression<String>? icon,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slug != null) 'slug': slug,
      if (nameAr != null) 'name_ar': nameAr,
      if (descriptionAr != null) 'description_ar': descriptionAr,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SciencesCompanion copyWith({
    Value<String>? slug,
    Value<String>? nameAr,
    Value<String?>? descriptionAr,
    Value<String?>? icon,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return SciencesCompanion(
      slug: slug ?? this.slug,
      nameAr: nameAr ?? this.nameAr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (descriptionAr.present) {
      map['description_ar'] = Variable<String>(descriptionAr.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SciencesCompanion(')
          ..write('slug: $slug, ')
          ..write('nameAr: $nameAr, ')
          ..write('descriptionAr: $descriptionAr, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeriesEntriesTable extends SeriesEntries
    with TableInfo<$SeriesEntriesTable, SeriesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scienceSlugMeta = const VerificationMeta(
    'scienceSlug',
  );
  @override
  late final GeneratedColumn<String> scienceSlug = GeneratedColumn<String>(
    'science_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleArMeta = const VerificationMeta(
    'titleAr',
  );
  @override
  late final GeneratedColumn<String> titleAr = GeneratedColumn<String>(
    'title_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionArMeta = const VerificationMeta(
    'descriptionAr',
  );
  @override
  late final GeneratedColumn<String> descriptionAr = GeneratedColumn<String>(
    'description_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    slug,
    scienceSlug,
    titleAr,
    descriptionAr,
    thumbnailUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('science_slug')) {
      context.handle(
        _scienceSlugMeta,
        scienceSlug.isAcceptableOrUnknown(
          data['science_slug']!,
          _scienceSlugMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scienceSlugMeta);
    }
    if (data.containsKey('title_ar')) {
      context.handle(
        _titleArMeta,
        titleAr.isAcceptableOrUnknown(data['title_ar']!, _titleArMeta),
      );
    } else if (isInserting) {
      context.missing(_titleArMeta);
    }
    if (data.containsKey('description_ar')) {
      context.handle(
        _descriptionArMeta,
        descriptionAr.isAcceptableOrUnknown(
          data['description_ar']!,
          _descriptionArMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slug};
  @override
  SeriesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesRow(
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      scienceSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}science_slug'],
      )!,
      titleAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_ar'],
      )!,
      descriptionAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_ar'],
      ),
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
    );
  }

  @override
  $SeriesEntriesTable createAlias(String alias) {
    return $SeriesEntriesTable(attachedDatabase, alias);
  }
}

class SeriesRow extends DataClass implements Insertable<SeriesRow> {
  final String slug;
  final String scienceSlug;
  final String titleAr;
  final String? descriptionAr;
  final String? thumbnailUrl;
  const SeriesRow({
    required this.slug,
    required this.scienceSlug,
    required this.titleAr,
    this.descriptionAr,
    this.thumbnailUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slug'] = Variable<String>(slug);
    map['science_slug'] = Variable<String>(scienceSlug);
    map['title_ar'] = Variable<String>(titleAr);
    if (!nullToAbsent || descriptionAr != null) {
      map['description_ar'] = Variable<String>(descriptionAr);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    return map;
  }

  SeriesEntriesCompanion toCompanion(bool nullToAbsent) {
    return SeriesEntriesCompanion(
      slug: Value(slug),
      scienceSlug: Value(scienceSlug),
      titleAr: Value(titleAr),
      descriptionAr: descriptionAr == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionAr),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
    );
  }

  factory SeriesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesRow(
      slug: serializer.fromJson<String>(json['slug']),
      scienceSlug: serializer.fromJson<String>(json['scienceSlug']),
      titleAr: serializer.fromJson<String>(json['titleAr']),
      descriptionAr: serializer.fromJson<String?>(json['descriptionAr']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slug': serializer.toJson<String>(slug),
      'scienceSlug': serializer.toJson<String>(scienceSlug),
      'titleAr': serializer.toJson<String>(titleAr),
      'descriptionAr': serializer.toJson<String?>(descriptionAr),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
    };
  }

  SeriesRow copyWith({
    String? slug,
    String? scienceSlug,
    String? titleAr,
    Value<String?> descriptionAr = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
  }) => SeriesRow(
    slug: slug ?? this.slug,
    scienceSlug: scienceSlug ?? this.scienceSlug,
    titleAr: titleAr ?? this.titleAr,
    descriptionAr: descriptionAr.present
        ? descriptionAr.value
        : this.descriptionAr,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
  );
  SeriesRow copyWithCompanion(SeriesEntriesCompanion data) {
    return SeriesRow(
      slug: data.slug.present ? data.slug.value : this.slug,
      scienceSlug: data.scienceSlug.present
          ? data.scienceSlug.value
          : this.scienceSlug,
      titleAr: data.titleAr.present ? data.titleAr.value : this.titleAr,
      descriptionAr: data.descriptionAr.present
          ? data.descriptionAr.value
          : this.descriptionAr,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesRow(')
          ..write('slug: $slug, ')
          ..write('scienceSlug: $scienceSlug, ')
          ..write('titleAr: $titleAr, ')
          ..write('descriptionAr: $descriptionAr, ')
          ..write('thumbnailUrl: $thumbnailUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(slug, scienceSlug, titleAr, descriptionAr, thumbnailUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesRow &&
          other.slug == this.slug &&
          other.scienceSlug == this.scienceSlug &&
          other.titleAr == this.titleAr &&
          other.descriptionAr == this.descriptionAr &&
          other.thumbnailUrl == this.thumbnailUrl);
}

class SeriesEntriesCompanion extends UpdateCompanion<SeriesRow> {
  final Value<String> slug;
  final Value<String> scienceSlug;
  final Value<String> titleAr;
  final Value<String?> descriptionAr;
  final Value<String?> thumbnailUrl;
  final Value<int> rowid;
  const SeriesEntriesCompanion({
    this.slug = const Value.absent(),
    this.scienceSlug = const Value.absent(),
    this.titleAr = const Value.absent(),
    this.descriptionAr = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeriesEntriesCompanion.insert({
    required String slug,
    required String scienceSlug,
    required String titleAr,
    this.descriptionAr = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : slug = Value(slug),
       scienceSlug = Value(scienceSlug),
       titleAr = Value(titleAr);
  static Insertable<SeriesRow> custom({
    Expression<String>? slug,
    Expression<String>? scienceSlug,
    Expression<String>? titleAr,
    Expression<String>? descriptionAr,
    Expression<String>? thumbnailUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slug != null) 'slug': slug,
      if (scienceSlug != null) 'science_slug': scienceSlug,
      if (titleAr != null) 'title_ar': titleAr,
      if (descriptionAr != null) 'description_ar': descriptionAr,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeriesEntriesCompanion copyWith({
    Value<String>? slug,
    Value<String>? scienceSlug,
    Value<String>? titleAr,
    Value<String?>? descriptionAr,
    Value<String?>? thumbnailUrl,
    Value<int>? rowid,
  }) {
    return SeriesEntriesCompanion(
      slug: slug ?? this.slug,
      scienceSlug: scienceSlug ?? this.scienceSlug,
      titleAr: titleAr ?? this.titleAr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (scienceSlug.present) {
      map['science_slug'] = Variable<String>(scienceSlug.value);
    }
    if (titleAr.present) {
      map['title_ar'] = Variable<String>(titleAr.value);
    }
    if (descriptionAr.present) {
      map['description_ar'] = Variable<String>(descriptionAr.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesEntriesCompanion(')
          ..write('slug: $slug, ')
          ..write('scienceSlug: $scienceSlug, ')
          ..write('titleAr: $titleAr, ')
          ..write('descriptionAr: $descriptionAr, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonsTable extends Lessons with TableInfo<$LessonsTable, Lesson> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesSlugMeta = const VerificationMeta(
    'seriesSlug',
  );
  @override
  late final GeneratedColumn<String> seriesSlug = GeneratedColumn<String>(
    'series_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _titleArMeta = const VerificationMeta(
    'titleAr',
  );
  @override
  late final GeneratedColumn<String> titleAr = GeneratedColumn<String>(
    'title_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    videoId,
    seriesSlug,
    position,
    titleAr,
    durationSeconds,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lessons';
  @override
  VerificationContext validateIntegrity(
    Insertable<Lesson> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('series_slug')) {
      context.handle(
        _seriesSlugMeta,
        seriesSlug.isAcceptableOrUnknown(data['series_slug']!, _seriesSlugMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesSlugMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('title_ar')) {
      context.handle(
        _titleArMeta,
        titleAr.isAcceptableOrUnknown(data['title_ar']!, _titleArMeta),
      );
    } else if (isInserting) {
      context.missing(_titleArMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId};
  @override
  Lesson map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lesson(
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      seriesSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_slug'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      titleAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_ar'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $LessonsTable createAlias(String alias) {
    return $LessonsTable(attachedDatabase, alias);
  }
}

class Lesson extends DataClass implements Insertable<Lesson> {
  final String videoId;
  final String seriesSlug;
  final int position;
  final String titleAr;
  final int? durationSeconds;

  /// 'active' | 'hidden' | 'unavailable'
  final String status;
  const Lesson({
    required this.videoId,
    required this.seriesSlug,
    required this.position,
    required this.titleAr,
    this.durationSeconds,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    map['series_slug'] = Variable<String>(seriesSlug);
    map['position'] = Variable<int>(position);
    map['title_ar'] = Variable<String>(titleAr);
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  LessonsCompanion toCompanion(bool nullToAbsent) {
    return LessonsCompanion(
      videoId: Value(videoId),
      seriesSlug: Value(seriesSlug),
      position: Value(position),
      titleAr: Value(titleAr),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      status: Value(status),
    );
  }

  factory Lesson.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lesson(
      videoId: serializer.fromJson<String>(json['videoId']),
      seriesSlug: serializer.fromJson<String>(json['seriesSlug']),
      position: serializer.fromJson<int>(json['position']),
      titleAr: serializer.fromJson<String>(json['titleAr']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'seriesSlug': serializer.toJson<String>(seriesSlug),
      'position': serializer.toJson<int>(position),
      'titleAr': serializer.toJson<String>(titleAr),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'status': serializer.toJson<String>(status),
    };
  }

  Lesson copyWith({
    String? videoId,
    String? seriesSlug,
    int? position,
    String? titleAr,
    Value<int?> durationSeconds = const Value.absent(),
    String? status,
  }) => Lesson(
    videoId: videoId ?? this.videoId,
    seriesSlug: seriesSlug ?? this.seriesSlug,
    position: position ?? this.position,
    titleAr: titleAr ?? this.titleAr,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    status: status ?? this.status,
  );
  Lesson copyWithCompanion(LessonsCompanion data) {
    return Lesson(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      seriesSlug: data.seriesSlug.present
          ? data.seriesSlug.value
          : this.seriesSlug,
      position: data.position.present ? data.position.value : this.position,
      titleAr: data.titleAr.present ? data.titleAr.value : this.titleAr,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lesson(')
          ..write('videoId: $videoId, ')
          ..write('seriesSlug: $seriesSlug, ')
          ..write('position: $position, ')
          ..write('titleAr: $titleAr, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    videoId,
    seriesSlug,
    position,
    titleAr,
    durationSeconds,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lesson &&
          other.videoId == this.videoId &&
          other.seriesSlug == this.seriesSlug &&
          other.position == this.position &&
          other.titleAr == this.titleAr &&
          other.durationSeconds == this.durationSeconds &&
          other.status == this.status);
}

class LessonsCompanion extends UpdateCompanion<Lesson> {
  final Value<String> videoId;
  final Value<String> seriesSlug;
  final Value<int> position;
  final Value<String> titleAr;
  final Value<int?> durationSeconds;
  final Value<String> status;
  final Value<int> rowid;
  const LessonsCompanion({
    this.videoId = const Value.absent(),
    this.seriesSlug = const Value.absent(),
    this.position = const Value.absent(),
    this.titleAr = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonsCompanion.insert({
    required String videoId,
    required String seriesSlug,
    required int position,
    required String titleAr,
    this.durationSeconds = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : videoId = Value(videoId),
       seriesSlug = Value(seriesSlug),
       position = Value(position),
       titleAr = Value(titleAr);
  static Insertable<Lesson> custom({
    Expression<String>? videoId,
    Expression<String>? seriesSlug,
    Expression<int>? position,
    Expression<String>? titleAr,
    Expression<int>? durationSeconds,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (seriesSlug != null) 'series_slug': seriesSlug,
      if (position != null) 'position': position,
      if (titleAr != null) 'title_ar': titleAr,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonsCompanion copyWith({
    Value<String>? videoId,
    Value<String>? seriesSlug,
    Value<int>? position,
    Value<String>? titleAr,
    Value<int?>? durationSeconds,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return LessonsCompanion(
      videoId: videoId ?? this.videoId,
      seriesSlug: seriesSlug ?? this.seriesSlug,
      position: position ?? this.position,
      titleAr: titleAr ?? this.titleAr,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (seriesSlug.present) {
      map['series_slug'] = Variable<String>(seriesSlug.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (titleAr.present) {
      map['title_ar'] = Variable<String>(titleAr.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonsCompanion(')
          ..write('videoId: $videoId, ')
          ..write('seriesSlug: $seriesSlug, ')
          ..write('position: $position, ')
          ..write('titleAr: $titleAr, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JourneysTable extends Journeys with TableInfo<$JourneysTable, Journey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JourneysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleArMeta = const VerificationMeta(
    'titleAr',
  );
  @override
  late final GeneratedColumn<String> titleAr = GeneratedColumn<String>(
    'title_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionArMeta = const VerificationMeta(
    'descriptionAr',
  );
  @override
  late final GeneratedColumn<String> descriptionAr = GeneratedColumn<String>(
    'description_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scienceSlugMeta = const VerificationMeta(
    'scienceSlug',
  );
  @override
  late final GeneratedColumn<String> scienceSlug = GeneratedColumn<String>(
    'science_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    slug,
    titleAr,
    descriptionAr,
    level,
    scienceSlug,
    coverUrl,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journeys';
  @override
  VerificationContext validateIntegrity(
    Insertable<Journey> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('title_ar')) {
      context.handle(
        _titleArMeta,
        titleAr.isAcceptableOrUnknown(data['title_ar']!, _titleArMeta),
      );
    } else if (isInserting) {
      context.missing(_titleArMeta);
    }
    if (data.containsKey('description_ar')) {
      context.handle(
        _descriptionArMeta,
        descriptionAr.isAcceptableOrUnknown(
          data['description_ar']!,
          _descriptionArMeta,
        ),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('science_slug')) {
      context.handle(
        _scienceSlugMeta,
        scienceSlug.isAcceptableOrUnknown(
          data['science_slug']!,
          _scienceSlugMeta,
        ),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slug};
  @override
  Journey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Journey(
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      titleAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_ar'],
      )!,
      descriptionAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_ar'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      scienceSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}science_slug'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $JourneysTable createAlias(String alias) {
    return $JourneysTable(attachedDatabase, alias);
  }
}

class Journey extends DataClass implements Insertable<Journey> {
  final String slug;
  final String titleAr;
  final String? descriptionAr;

  /// 'beginner' | 'intermediate' | 'advanced'
  final String level;
  final String? scienceSlug;
  final String? coverUrl;
  final int sortOrder;
  const Journey({
    required this.slug,
    required this.titleAr,
    this.descriptionAr,
    required this.level,
    this.scienceSlug,
    this.coverUrl,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slug'] = Variable<String>(slug);
    map['title_ar'] = Variable<String>(titleAr);
    if (!nullToAbsent || descriptionAr != null) {
      map['description_ar'] = Variable<String>(descriptionAr);
    }
    map['level'] = Variable<String>(level);
    if (!nullToAbsent || scienceSlug != null) {
      map['science_slug'] = Variable<String>(scienceSlug);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  JourneysCompanion toCompanion(bool nullToAbsent) {
    return JourneysCompanion(
      slug: Value(slug),
      titleAr: Value(titleAr),
      descriptionAr: descriptionAr == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionAr),
      level: Value(level),
      scienceSlug: scienceSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(scienceSlug),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      sortOrder: Value(sortOrder),
    );
  }

  factory Journey.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Journey(
      slug: serializer.fromJson<String>(json['slug']),
      titleAr: serializer.fromJson<String>(json['titleAr']),
      descriptionAr: serializer.fromJson<String?>(json['descriptionAr']),
      level: serializer.fromJson<String>(json['level']),
      scienceSlug: serializer.fromJson<String?>(json['scienceSlug']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slug': serializer.toJson<String>(slug),
      'titleAr': serializer.toJson<String>(titleAr),
      'descriptionAr': serializer.toJson<String?>(descriptionAr),
      'level': serializer.toJson<String>(level),
      'scienceSlug': serializer.toJson<String?>(scienceSlug),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Journey copyWith({
    String? slug,
    String? titleAr,
    Value<String?> descriptionAr = const Value.absent(),
    String? level,
    Value<String?> scienceSlug = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    int? sortOrder,
  }) => Journey(
    slug: slug ?? this.slug,
    titleAr: titleAr ?? this.titleAr,
    descriptionAr: descriptionAr.present
        ? descriptionAr.value
        : this.descriptionAr,
    level: level ?? this.level,
    scienceSlug: scienceSlug.present ? scienceSlug.value : this.scienceSlug,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Journey copyWithCompanion(JourneysCompanion data) {
    return Journey(
      slug: data.slug.present ? data.slug.value : this.slug,
      titleAr: data.titleAr.present ? data.titleAr.value : this.titleAr,
      descriptionAr: data.descriptionAr.present
          ? data.descriptionAr.value
          : this.descriptionAr,
      level: data.level.present ? data.level.value : this.level,
      scienceSlug: data.scienceSlug.present
          ? data.scienceSlug.value
          : this.scienceSlug,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Journey(')
          ..write('slug: $slug, ')
          ..write('titleAr: $titleAr, ')
          ..write('descriptionAr: $descriptionAr, ')
          ..write('level: $level, ')
          ..write('scienceSlug: $scienceSlug, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    slug,
    titleAr,
    descriptionAr,
    level,
    scienceSlug,
    coverUrl,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Journey &&
          other.slug == this.slug &&
          other.titleAr == this.titleAr &&
          other.descriptionAr == this.descriptionAr &&
          other.level == this.level &&
          other.scienceSlug == this.scienceSlug &&
          other.coverUrl == this.coverUrl &&
          other.sortOrder == this.sortOrder);
}

class JourneysCompanion extends UpdateCompanion<Journey> {
  final Value<String> slug;
  final Value<String> titleAr;
  final Value<String?> descriptionAr;
  final Value<String> level;
  final Value<String?> scienceSlug;
  final Value<String?> coverUrl;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const JourneysCompanion({
    this.slug = const Value.absent(),
    this.titleAr = const Value.absent(),
    this.descriptionAr = const Value.absent(),
    this.level = const Value.absent(),
    this.scienceSlug = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneysCompanion.insert({
    required String slug,
    required String titleAr,
    this.descriptionAr = const Value.absent(),
    required String level,
    this.scienceSlug = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : slug = Value(slug),
       titleAr = Value(titleAr),
       level = Value(level);
  static Insertable<Journey> custom({
    Expression<String>? slug,
    Expression<String>? titleAr,
    Expression<String>? descriptionAr,
    Expression<String>? level,
    Expression<String>? scienceSlug,
    Expression<String>? coverUrl,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slug != null) 'slug': slug,
      if (titleAr != null) 'title_ar': titleAr,
      if (descriptionAr != null) 'description_ar': descriptionAr,
      if (level != null) 'level': level,
      if (scienceSlug != null) 'science_slug': scienceSlug,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneysCompanion copyWith({
    Value<String>? slug,
    Value<String>? titleAr,
    Value<String?>? descriptionAr,
    Value<String>? level,
    Value<String?>? scienceSlug,
    Value<String?>? coverUrl,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return JourneysCompanion(
      slug: slug ?? this.slug,
      titleAr: titleAr ?? this.titleAr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      level: level ?? this.level,
      scienceSlug: scienceSlug ?? this.scienceSlug,
      coverUrl: coverUrl ?? this.coverUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (titleAr.present) {
      map['title_ar'] = Variable<String>(titleAr.value);
    }
    if (descriptionAr.present) {
      map['description_ar'] = Variable<String>(descriptionAr.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (scienceSlug.present) {
      map['science_slug'] = Variable<String>(scienceSlug.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JourneysCompanion(')
          ..write('slug: $slug, ')
          ..write('titleAr: $titleAr, ')
          ..write('descriptionAr: $descriptionAr, ')
          ..write('level: $level, ')
          ..write('scienceSlug: $scienceSlug, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JourneyStagesTable extends JourneyStages
    with TableInfo<$JourneyStagesTable, JourneyStage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JourneyStagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _journeySlugMeta = const VerificationMeta(
    'journeySlug',
  );
  @override
  late final GeneratedColumn<String> journeySlug = GeneratedColumn<String>(
    'journey_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _titleArMeta = const VerificationMeta(
    'titleAr',
  );
  @override
  late final GeneratedColumn<String> titleAr = GeneratedColumn<String>(
    'title_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionArMeta = const VerificationMeta(
    'descriptionAr',
  );
  @override
  late final GeneratedColumn<String> descriptionAr = GeneratedColumn<String>(
    'description_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    journeySlug,
    position,
    titleAr,
    descriptionAr,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journey_stages';
  @override
  VerificationContext validateIntegrity(
    Insertable<JourneyStage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('journey_slug')) {
      context.handle(
        _journeySlugMeta,
        journeySlug.isAcceptableOrUnknown(
          data['journey_slug']!,
          _journeySlugMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_journeySlugMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('title_ar')) {
      context.handle(
        _titleArMeta,
        titleAr.isAcceptableOrUnknown(data['title_ar']!, _titleArMeta),
      );
    } else if (isInserting) {
      context.missing(_titleArMeta);
    }
    if (data.containsKey('description_ar')) {
      context.handle(
        _descriptionArMeta,
        descriptionAr.isAcceptableOrUnknown(
          data['description_ar']!,
          _descriptionArMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {journeySlug, position};
  @override
  JourneyStage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JourneyStage(
      journeySlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journey_slug'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      titleAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_ar'],
      )!,
      descriptionAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_ar'],
      ),
    );
  }

  @override
  $JourneyStagesTable createAlias(String alias) {
    return $JourneyStagesTable(attachedDatabase, alias);
  }
}

class JourneyStage extends DataClass implements Insertable<JourneyStage> {
  final String journeySlug;
  final int position;
  final String titleAr;
  final String? descriptionAr;
  const JourneyStage({
    required this.journeySlug,
    required this.position,
    required this.titleAr,
    this.descriptionAr,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['journey_slug'] = Variable<String>(journeySlug);
    map['position'] = Variable<int>(position);
    map['title_ar'] = Variable<String>(titleAr);
    if (!nullToAbsent || descriptionAr != null) {
      map['description_ar'] = Variable<String>(descriptionAr);
    }
    return map;
  }

  JourneyStagesCompanion toCompanion(bool nullToAbsent) {
    return JourneyStagesCompanion(
      journeySlug: Value(journeySlug),
      position: Value(position),
      titleAr: Value(titleAr),
      descriptionAr: descriptionAr == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionAr),
    );
  }

  factory JourneyStage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JourneyStage(
      journeySlug: serializer.fromJson<String>(json['journeySlug']),
      position: serializer.fromJson<int>(json['position']),
      titleAr: serializer.fromJson<String>(json['titleAr']),
      descriptionAr: serializer.fromJson<String?>(json['descriptionAr']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'journeySlug': serializer.toJson<String>(journeySlug),
      'position': serializer.toJson<int>(position),
      'titleAr': serializer.toJson<String>(titleAr),
      'descriptionAr': serializer.toJson<String?>(descriptionAr),
    };
  }

  JourneyStage copyWith({
    String? journeySlug,
    int? position,
    String? titleAr,
    Value<String?> descriptionAr = const Value.absent(),
  }) => JourneyStage(
    journeySlug: journeySlug ?? this.journeySlug,
    position: position ?? this.position,
    titleAr: titleAr ?? this.titleAr,
    descriptionAr: descriptionAr.present
        ? descriptionAr.value
        : this.descriptionAr,
  );
  JourneyStage copyWithCompanion(JourneyStagesCompanion data) {
    return JourneyStage(
      journeySlug: data.journeySlug.present
          ? data.journeySlug.value
          : this.journeySlug,
      position: data.position.present ? data.position.value : this.position,
      titleAr: data.titleAr.present ? data.titleAr.value : this.titleAr,
      descriptionAr: data.descriptionAr.present
          ? data.descriptionAr.value
          : this.descriptionAr,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JourneyStage(')
          ..write('journeySlug: $journeySlug, ')
          ..write('position: $position, ')
          ..write('titleAr: $titleAr, ')
          ..write('descriptionAr: $descriptionAr')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(journeySlug, position, titleAr, descriptionAr);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JourneyStage &&
          other.journeySlug == this.journeySlug &&
          other.position == this.position &&
          other.titleAr == this.titleAr &&
          other.descriptionAr == this.descriptionAr);
}

class JourneyStagesCompanion extends UpdateCompanion<JourneyStage> {
  final Value<String> journeySlug;
  final Value<int> position;
  final Value<String> titleAr;
  final Value<String?> descriptionAr;
  final Value<int> rowid;
  const JourneyStagesCompanion({
    this.journeySlug = const Value.absent(),
    this.position = const Value.absent(),
    this.titleAr = const Value.absent(),
    this.descriptionAr = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneyStagesCompanion.insert({
    required String journeySlug,
    required int position,
    required String titleAr,
    this.descriptionAr = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : journeySlug = Value(journeySlug),
       position = Value(position),
       titleAr = Value(titleAr);
  static Insertable<JourneyStage> custom({
    Expression<String>? journeySlug,
    Expression<int>? position,
    Expression<String>? titleAr,
    Expression<String>? descriptionAr,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (journeySlug != null) 'journey_slug': journeySlug,
      if (position != null) 'position': position,
      if (titleAr != null) 'title_ar': titleAr,
      if (descriptionAr != null) 'description_ar': descriptionAr,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneyStagesCompanion copyWith({
    Value<String>? journeySlug,
    Value<int>? position,
    Value<String>? titleAr,
    Value<String?>? descriptionAr,
    Value<int>? rowid,
  }) {
    return JourneyStagesCompanion(
      journeySlug: journeySlug ?? this.journeySlug,
      position: position ?? this.position,
      titleAr: titleAr ?? this.titleAr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (journeySlug.present) {
      map['journey_slug'] = Variable<String>(journeySlug.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (titleAr.present) {
      map['title_ar'] = Variable<String>(titleAr.value);
    }
    if (descriptionAr.present) {
      map['description_ar'] = Variable<String>(descriptionAr.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JourneyStagesCompanion(')
          ..write('journeySlug: $journeySlug, ')
          ..write('position: $position, ')
          ..write('titleAr: $titleAr, ')
          ..write('descriptionAr: $descriptionAr, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JourneyItemsTable extends JourneyItems
    with TableInfo<$JourneyItemsTable, JourneyItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JourneyItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _journeySlugMeta = const VerificationMeta(
    'journeySlug',
  );
  @override
  late final GeneratedColumn<String> journeySlug = GeneratedColumn<String>(
    'journey_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stagePositionMeta = const VerificationMeta(
    'stagePosition',
  );
  @override
  late final GeneratedColumn<int> stagePosition = GeneratedColumn<int>(
    'stage_position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _seriesSlugMeta = const VerificationMeta(
    'seriesSlug',
  );
  @override
  late final GeneratedColumn<String> seriesSlug = GeneratedColumn<String>(
    'series_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    journeySlug,
    stagePosition,
    position,
    seriesSlug,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journey_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<JourneyItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('journey_slug')) {
      context.handle(
        _journeySlugMeta,
        journeySlug.isAcceptableOrUnknown(
          data['journey_slug']!,
          _journeySlugMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_journeySlugMeta);
    }
    if (data.containsKey('stage_position')) {
      context.handle(
        _stagePositionMeta,
        stagePosition.isAcceptableOrUnknown(
          data['stage_position']!,
          _stagePositionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stagePositionMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('series_slug')) {
      context.handle(
        _seriesSlugMeta,
        seriesSlug.isAcceptableOrUnknown(data['series_slug']!, _seriesSlugMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesSlugMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    journeySlug,
    stagePosition,
    position,
  };
  @override
  JourneyItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JourneyItem(
      journeySlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journey_slug'],
      )!,
      stagePosition: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_position'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      seriesSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_slug'],
      )!,
    );
  }

  @override
  $JourneyItemsTable createAlias(String alias) {
    return $JourneyItemsTable(attachedDatabase, alias);
  }
}

class JourneyItem extends DataClass implements Insertable<JourneyItem> {
  final String journeySlug;
  final int stagePosition;
  final int position;
  final String seriesSlug;
  const JourneyItem({
    required this.journeySlug,
    required this.stagePosition,
    required this.position,
    required this.seriesSlug,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['journey_slug'] = Variable<String>(journeySlug);
    map['stage_position'] = Variable<int>(stagePosition);
    map['position'] = Variable<int>(position);
    map['series_slug'] = Variable<String>(seriesSlug);
    return map;
  }

  JourneyItemsCompanion toCompanion(bool nullToAbsent) {
    return JourneyItemsCompanion(
      journeySlug: Value(journeySlug),
      stagePosition: Value(stagePosition),
      position: Value(position),
      seriesSlug: Value(seriesSlug),
    );
  }

  factory JourneyItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JourneyItem(
      journeySlug: serializer.fromJson<String>(json['journeySlug']),
      stagePosition: serializer.fromJson<int>(json['stagePosition']),
      position: serializer.fromJson<int>(json['position']),
      seriesSlug: serializer.fromJson<String>(json['seriesSlug']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'journeySlug': serializer.toJson<String>(journeySlug),
      'stagePosition': serializer.toJson<int>(stagePosition),
      'position': serializer.toJson<int>(position),
      'seriesSlug': serializer.toJson<String>(seriesSlug),
    };
  }

  JourneyItem copyWith({
    String? journeySlug,
    int? stagePosition,
    int? position,
    String? seriesSlug,
  }) => JourneyItem(
    journeySlug: journeySlug ?? this.journeySlug,
    stagePosition: stagePosition ?? this.stagePosition,
    position: position ?? this.position,
    seriesSlug: seriesSlug ?? this.seriesSlug,
  );
  JourneyItem copyWithCompanion(JourneyItemsCompanion data) {
    return JourneyItem(
      journeySlug: data.journeySlug.present
          ? data.journeySlug.value
          : this.journeySlug,
      stagePosition: data.stagePosition.present
          ? data.stagePosition.value
          : this.stagePosition,
      position: data.position.present ? data.position.value : this.position,
      seriesSlug: data.seriesSlug.present
          ? data.seriesSlug.value
          : this.seriesSlug,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JourneyItem(')
          ..write('journeySlug: $journeySlug, ')
          ..write('stagePosition: $stagePosition, ')
          ..write('position: $position, ')
          ..write('seriesSlug: $seriesSlug')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(journeySlug, stagePosition, position, seriesSlug);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JourneyItem &&
          other.journeySlug == this.journeySlug &&
          other.stagePosition == this.stagePosition &&
          other.position == this.position &&
          other.seriesSlug == this.seriesSlug);
}

class JourneyItemsCompanion extends UpdateCompanion<JourneyItem> {
  final Value<String> journeySlug;
  final Value<int> stagePosition;
  final Value<int> position;
  final Value<String> seriesSlug;
  final Value<int> rowid;
  const JourneyItemsCompanion({
    this.journeySlug = const Value.absent(),
    this.stagePosition = const Value.absent(),
    this.position = const Value.absent(),
    this.seriesSlug = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneyItemsCompanion.insert({
    required String journeySlug,
    required int stagePosition,
    required int position,
    required String seriesSlug,
    this.rowid = const Value.absent(),
  }) : journeySlug = Value(journeySlug),
       stagePosition = Value(stagePosition),
       position = Value(position),
       seriesSlug = Value(seriesSlug);
  static Insertable<JourneyItem> custom({
    Expression<String>? journeySlug,
    Expression<int>? stagePosition,
    Expression<int>? position,
    Expression<String>? seriesSlug,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (journeySlug != null) 'journey_slug': journeySlug,
      if (stagePosition != null) 'stage_position': stagePosition,
      if (position != null) 'position': position,
      if (seriesSlug != null) 'series_slug': seriesSlug,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneyItemsCompanion copyWith({
    Value<String>? journeySlug,
    Value<int>? stagePosition,
    Value<int>? position,
    Value<String>? seriesSlug,
    Value<int>? rowid,
  }) {
    return JourneyItemsCompanion(
      journeySlug: journeySlug ?? this.journeySlug,
      stagePosition: stagePosition ?? this.stagePosition,
      position: position ?? this.position,
      seriesSlug: seriesSlug ?? this.seriesSlug,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (journeySlug.present) {
      map['journey_slug'] = Variable<String>(journeySlug.value);
    }
    if (stagePosition.present) {
      map['stage_position'] = Variable<int>(stagePosition.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (seriesSlug.present) {
      map['series_slug'] = Variable<String>(seriesSlug.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JourneyItemsCompanion(')
          ..write('journeySlug: $journeySlug, ')
          ..write('stagePosition: $stagePosition, ')
          ..write('position: $position, ')
          ..write('seriesSlug: $seriesSlug, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CatalogInfoTable extends CatalogInfo
    with TableInfo<$CatalogInfoTable, CatalogInfoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogInfoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
    'generated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, version, generatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_info';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogInfoData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CatalogInfoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogInfoData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      generatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}generated_at'],
      ),
    );
  }

  @override
  $CatalogInfoTable createAlias(String alias) {
    return $CatalogInfoTable(attachedDatabase, alias);
  }
}

class CatalogInfoData extends DataClass implements Insertable<CatalogInfoData> {
  final int id;
  final int version;
  final DateTime? generatedAt;
  const CatalogInfoData({
    required this.id,
    required this.version,
    this.generatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || generatedAt != null) {
      map['generated_at'] = Variable<DateTime>(generatedAt);
    }
    return map;
  }

  CatalogInfoCompanion toCompanion(bool nullToAbsent) {
    return CatalogInfoCompanion(
      id: Value(id),
      version: Value(version),
      generatedAt: generatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(generatedAt),
    );
  }

  factory CatalogInfoData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogInfoData(
      id: serializer.fromJson<int>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      generatedAt: serializer.fromJson<DateTime?>(json['generatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'version': serializer.toJson<int>(version),
      'generatedAt': serializer.toJson<DateTime?>(generatedAt),
    };
  }

  CatalogInfoData copyWith({
    int? id,
    int? version,
    Value<DateTime?> generatedAt = const Value.absent(),
  }) => CatalogInfoData(
    id: id ?? this.id,
    version: version ?? this.version,
    generatedAt: generatedAt.present ? generatedAt.value : this.generatedAt,
  );
  CatalogInfoData copyWithCompanion(CatalogInfoCompanion data) {
    return CatalogInfoData(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogInfoData(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('generatedAt: $generatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, version, generatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogInfoData &&
          other.id == this.id &&
          other.version == this.version &&
          other.generatedAt == this.generatedAt);
}

class CatalogInfoCompanion extends UpdateCompanion<CatalogInfoData> {
  final Value<int> id;
  final Value<int> version;
  final Value<DateTime?> generatedAt;
  const CatalogInfoCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.generatedAt = const Value.absent(),
  });
  CatalogInfoCompanion.insert({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.generatedAt = const Value.absent(),
  });
  static Insertable<CatalogInfoData> custom({
    Expression<int>? id,
    Expression<int>? version,
    Expression<DateTime>? generatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (generatedAt != null) 'generated_at': generatedAt,
    });
  }

  CatalogInfoCompanion copyWith({
    Value<int>? id,
    Value<int>? version,
    Value<DateTime?>? generatedAt,
  }) {
    return CatalogInfoCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogInfoCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('generatedAt: $generatedAt')
          ..write(')'))
        .toString();
  }
}

class $LessonProgressTable extends LessonProgress
    with TableInfo<$LessonProgressTable, LessonProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _watchedSecondsMeta = const VerificationMeta(
    'watchedSeconds',
  );
  @override
  late final GeneratedColumn<int> watchedSeconds = GeneratedColumn<int>(
    'watched_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastWatchedAtMeta = const VerificationMeta(
    'lastWatchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastWatchedAt =
      GeneratedColumn<DateTime>(
        'last_watched_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    videoId,
    watchedSeconds,
    durationSeconds,
    completed,
    lastWatchedAt,
    updatedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('watched_seconds')) {
      context.handle(
        _watchedSecondsMeta,
        watchedSeconds.isAcceptableOrUnknown(
          data['watched_seconds']!,
          _watchedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('last_watched_at')) {
      context.handle(
        _lastWatchedAtMeta,
        lastWatchedAt.isAcceptableOrUnknown(
          data['last_watched_at']!,
          _lastWatchedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastWatchedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId};
  @override
  LessonProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonProgressData(
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      watchedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}watched_seconds'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      lastWatchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_watched_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $LessonProgressTable createAlias(String alias) {
    return $LessonProgressTable(attachedDatabase, alias);
  }
}

class LessonProgressData extends DataClass
    implements Insertable<LessonProgressData> {
  final String videoId;
  final int watchedSeconds;
  final int? durationSeconds;
  final bool completed;
  final DateTime lastWatchedAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  const LessonProgressData({
    required this.videoId,
    required this.watchedSeconds,
    this.durationSeconds,
    required this.completed,
    required this.lastWatchedAt,
    required this.updatedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    map['watched_seconds'] = Variable<int>(watchedSeconds);
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['completed'] = Variable<bool>(completed);
    map['last_watched_at'] = Variable<DateTime>(lastWatchedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  LessonProgressCompanion toCompanion(bool nullToAbsent) {
    return LessonProgressCompanion(
      videoId: Value(videoId),
      watchedSeconds: Value(watchedSeconds),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      completed: Value(completed),
      lastWatchedAt: Value(lastWatchedAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory LessonProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonProgressData(
      videoId: serializer.fromJson<String>(json['videoId']),
      watchedSeconds: serializer.fromJson<int>(json['watchedSeconds']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      completed: serializer.fromJson<bool>(json['completed']),
      lastWatchedAt: serializer.fromJson<DateTime>(json['lastWatchedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'watchedSeconds': serializer.toJson<int>(watchedSeconds),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'completed': serializer.toJson<bool>(completed),
      'lastWatchedAt': serializer.toJson<DateTime>(lastWatchedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  LessonProgressData copyWith({
    String? videoId,
    int? watchedSeconds,
    Value<int?> durationSeconds = const Value.absent(),
    bool? completed,
    DateTime? lastWatchedAt,
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => LessonProgressData(
    videoId: videoId ?? this.videoId,
    watchedSeconds: watchedSeconds ?? this.watchedSeconds,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    completed: completed ?? this.completed,
    lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  LessonProgressData copyWithCompanion(LessonProgressCompanion data) {
    return LessonProgressData(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      watchedSeconds: data.watchedSeconds.present
          ? data.watchedSeconds.value
          : this.watchedSeconds,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      completed: data.completed.present ? data.completed.value : this.completed,
      lastWatchedAt: data.lastWatchedAt.present
          ? data.lastWatchedAt.value
          : this.lastWatchedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressData(')
          ..write('videoId: $videoId, ')
          ..write('watchedSeconds: $watchedSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('completed: $completed, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    videoId,
    watchedSeconds,
    durationSeconds,
    completed,
    lastWatchedAt,
    updatedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonProgressData &&
          other.videoId == this.videoId &&
          other.watchedSeconds == this.watchedSeconds &&
          other.durationSeconds == this.durationSeconds &&
          other.completed == this.completed &&
          other.lastWatchedAt == this.lastWatchedAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt);
}

class LessonProgressCompanion extends UpdateCompanion<LessonProgressData> {
  final Value<String> videoId;
  final Value<int> watchedSeconds;
  final Value<int?> durationSeconds;
  final Value<bool> completed;
  final Value<DateTime> lastWatchedAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const LessonProgressCompanion({
    this.videoId = const Value.absent(),
    this.watchedSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.completed = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonProgressCompanion.insert({
    required String videoId,
    this.watchedSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.completed = const Value.absent(),
    required DateTime lastWatchedAt,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : videoId = Value(videoId),
       lastWatchedAt = Value(lastWatchedAt),
       updatedAt = Value(updatedAt);
  static Insertable<LessonProgressData> custom({
    Expression<String>? videoId,
    Expression<int>? watchedSeconds,
    Expression<int>? durationSeconds,
    Expression<bool>? completed,
    Expression<DateTime>? lastWatchedAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (watchedSeconds != null) 'watched_seconds': watchedSeconds,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (completed != null) 'completed': completed,
      if (lastWatchedAt != null) 'last_watched_at': lastWatchedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonProgressCompanion copyWith({
    Value<String>? videoId,
    Value<int>? watchedSeconds,
    Value<int?>? durationSeconds,
    Value<bool>? completed,
    Value<DateTime>? lastWatchedAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? rowid,
  }) {
    return LessonProgressCompanion(
      videoId: videoId ?? this.videoId,
      watchedSeconds: watchedSeconds ?? this.watchedSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completed: completed ?? this.completed,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (watchedSeconds.present) {
      map['watched_seconds'] = Variable<int>(watchedSeconds.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (lastWatchedAt.present) {
      map['last_watched_at'] = Variable<DateTime>(lastWatchedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressCompanion(')
          ..write('videoId: $videoId, ')
          ..write('watchedSeconds: $watchedSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('completed: $completed, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JourneyEnrollmentsTable extends JourneyEnrollments
    with TableInfo<$JourneyEnrollmentsTable, JourneyEnrollment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JourneyEnrollmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _journeySlugMeta = const VerificationMeta(
    'journeySlug',
  );
  @override
  late final GeneratedColumn<String> journeySlug = GeneratedColumn<String>(
    'journey_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enrolledAtMeta = const VerificationMeta(
    'enrolledAt',
  );
  @override
  late final GeneratedColumn<DateTime> enrolledAt = GeneratedColumn<DateTime>(
    'enrolled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastActivityAtMeta = const VerificationMeta(
    'lastActivityAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastActivityAt =
      GeneratedColumn<DateTime>(
        'last_activity_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    journeySlug,
    enrolledAt,
    lastActivityAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journey_enrollments';
  @override
  VerificationContext validateIntegrity(
    Insertable<JourneyEnrollment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('journey_slug')) {
      context.handle(
        _journeySlugMeta,
        journeySlug.isAcceptableOrUnknown(
          data['journey_slug']!,
          _journeySlugMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_journeySlugMeta);
    }
    if (data.containsKey('enrolled_at')) {
      context.handle(
        _enrolledAtMeta,
        enrolledAt.isAcceptableOrUnknown(data['enrolled_at']!, _enrolledAtMeta),
      );
    } else if (isInserting) {
      context.missing(_enrolledAtMeta);
    }
    if (data.containsKey('last_activity_at')) {
      context.handle(
        _lastActivityAtMeta,
        lastActivityAt.isAcceptableOrUnknown(
          data['last_activity_at']!,
          _lastActivityAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastActivityAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {journeySlug};
  @override
  JourneyEnrollment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JourneyEnrollment(
      journeySlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journey_slug'],
      )!,
      enrolledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}enrolled_at'],
      )!,
      lastActivityAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_activity_at'],
      )!,
    );
  }

  @override
  $JourneyEnrollmentsTable createAlias(String alias) {
    return $JourneyEnrollmentsTable(attachedDatabase, alias);
  }
}

class JourneyEnrollment extends DataClass
    implements Insertable<JourneyEnrollment> {
  final String journeySlug;
  final DateTime enrolledAt;
  final DateTime lastActivityAt;
  const JourneyEnrollment({
    required this.journeySlug,
    required this.enrolledAt,
    required this.lastActivityAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['journey_slug'] = Variable<String>(journeySlug);
    map['enrolled_at'] = Variable<DateTime>(enrolledAt);
    map['last_activity_at'] = Variable<DateTime>(lastActivityAt);
    return map;
  }

  JourneyEnrollmentsCompanion toCompanion(bool nullToAbsent) {
    return JourneyEnrollmentsCompanion(
      journeySlug: Value(journeySlug),
      enrolledAt: Value(enrolledAt),
      lastActivityAt: Value(lastActivityAt),
    );
  }

  factory JourneyEnrollment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JourneyEnrollment(
      journeySlug: serializer.fromJson<String>(json['journeySlug']),
      enrolledAt: serializer.fromJson<DateTime>(json['enrolledAt']),
      lastActivityAt: serializer.fromJson<DateTime>(json['lastActivityAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'journeySlug': serializer.toJson<String>(journeySlug),
      'enrolledAt': serializer.toJson<DateTime>(enrolledAt),
      'lastActivityAt': serializer.toJson<DateTime>(lastActivityAt),
    };
  }

  JourneyEnrollment copyWith({
    String? journeySlug,
    DateTime? enrolledAt,
    DateTime? lastActivityAt,
  }) => JourneyEnrollment(
    journeySlug: journeySlug ?? this.journeySlug,
    enrolledAt: enrolledAt ?? this.enrolledAt,
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
  );
  JourneyEnrollment copyWithCompanion(JourneyEnrollmentsCompanion data) {
    return JourneyEnrollment(
      journeySlug: data.journeySlug.present
          ? data.journeySlug.value
          : this.journeySlug,
      enrolledAt: data.enrolledAt.present
          ? data.enrolledAt.value
          : this.enrolledAt,
      lastActivityAt: data.lastActivityAt.present
          ? data.lastActivityAt.value
          : this.lastActivityAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JourneyEnrollment(')
          ..write('journeySlug: $journeySlug, ')
          ..write('enrolledAt: $enrolledAt, ')
          ..write('lastActivityAt: $lastActivityAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(journeySlug, enrolledAt, lastActivityAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JourneyEnrollment &&
          other.journeySlug == this.journeySlug &&
          other.enrolledAt == this.enrolledAt &&
          other.lastActivityAt == this.lastActivityAt);
}

class JourneyEnrollmentsCompanion extends UpdateCompanion<JourneyEnrollment> {
  final Value<String> journeySlug;
  final Value<DateTime> enrolledAt;
  final Value<DateTime> lastActivityAt;
  final Value<int> rowid;
  const JourneyEnrollmentsCompanion({
    this.journeySlug = const Value.absent(),
    this.enrolledAt = const Value.absent(),
    this.lastActivityAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneyEnrollmentsCompanion.insert({
    required String journeySlug,
    required DateTime enrolledAt,
    required DateTime lastActivityAt,
    this.rowid = const Value.absent(),
  }) : journeySlug = Value(journeySlug),
       enrolledAt = Value(enrolledAt),
       lastActivityAt = Value(lastActivityAt);
  static Insertable<JourneyEnrollment> custom({
    Expression<String>? journeySlug,
    Expression<DateTime>? enrolledAt,
    Expression<DateTime>? lastActivityAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (journeySlug != null) 'journey_slug': journeySlug,
      if (enrolledAt != null) 'enrolled_at': enrolledAt,
      if (lastActivityAt != null) 'last_activity_at': lastActivityAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneyEnrollmentsCompanion copyWith({
    Value<String>? journeySlug,
    Value<DateTime>? enrolledAt,
    Value<DateTime>? lastActivityAt,
    Value<int>? rowid,
  }) {
    return JourneyEnrollmentsCompanion(
      journeySlug: journeySlug ?? this.journeySlug,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (journeySlug.present) {
      map['journey_slug'] = Variable<String>(journeySlug.value);
    }
    if (enrolledAt.present) {
      map['enrolled_at'] = Variable<DateTime>(enrolledAt.value);
    }
    if (lastActivityAt.present) {
      map['last_activity_at'] = Variable<DateTime>(lastActivityAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JourneyEnrollmentsCompanion(')
          ..write('journeySlug: $journeySlug, ')
          ..write('enrolledAt: $enrolledAt, ')
          ..write('lastActivityAt: $lastActivityAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SciencesTable sciences = $SciencesTable(this);
  late final $SeriesEntriesTable seriesEntries = $SeriesEntriesTable(this);
  late final $LessonsTable lessons = $LessonsTable(this);
  late final $JourneysTable journeys = $JourneysTable(this);
  late final $JourneyStagesTable journeyStages = $JourneyStagesTable(this);
  late final $JourneyItemsTable journeyItems = $JourneyItemsTable(this);
  late final $CatalogInfoTable catalogInfo = $CatalogInfoTable(this);
  late final $LessonProgressTable lessonProgress = $LessonProgressTable(this);
  late final $JourneyEnrollmentsTable journeyEnrollments =
      $JourneyEnrollmentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sciences,
    seriesEntries,
    lessons,
    journeys,
    journeyStages,
    journeyItems,
    catalogInfo,
    lessonProgress,
    journeyEnrollments,
  ];
}

typedef $$SciencesTableCreateCompanionBuilder =
    SciencesCompanion Function({
      required String slug,
      required String nameAr,
      Value<String?> descriptionAr,
      Value<String?> icon,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$SciencesTableUpdateCompanionBuilder =
    SciencesCompanion Function({
      Value<String> slug,
      Value<String> nameAr,
      Value<String?> descriptionAr,
      Value<String?> icon,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$SciencesTableFilterComposer
    extends Composer<_$AppDatabase, $SciencesTable> {
  $$SciencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionAr => $composableBuilder(
    column: $table.descriptionAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SciencesTableOrderingComposer
    extends Composer<_$AppDatabase, $SciencesTable> {
  $$SciencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameAr => $composableBuilder(
    column: $table.nameAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionAr => $composableBuilder(
    column: $table.descriptionAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SciencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SciencesTable> {
  $$SciencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get descriptionAr => $composableBuilder(
    column: $table.descriptionAr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$SciencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SciencesTable,
          Science,
          $$SciencesTableFilterComposer,
          $$SciencesTableOrderingComposer,
          $$SciencesTableAnnotationComposer,
          $$SciencesTableCreateCompanionBuilder,
          $$SciencesTableUpdateCompanionBuilder,
          (Science, BaseReferences<_$AppDatabase, $SciencesTable, Science>),
          Science,
          PrefetchHooks Function()
        > {
  $$SciencesTableTableManager(_$AppDatabase db, $SciencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SciencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SciencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SciencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> slug = const Value.absent(),
                Value<String> nameAr = const Value.absent(),
                Value<String?> descriptionAr = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SciencesCompanion(
                slug: slug,
                nameAr: nameAr,
                descriptionAr: descriptionAr,
                icon: icon,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String slug,
                required String nameAr,
                Value<String?> descriptionAr = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SciencesCompanion.insert(
                slug: slug,
                nameAr: nameAr,
                descriptionAr: descriptionAr,
                icon: icon,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SciencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SciencesTable,
      Science,
      $$SciencesTableFilterComposer,
      $$SciencesTableOrderingComposer,
      $$SciencesTableAnnotationComposer,
      $$SciencesTableCreateCompanionBuilder,
      $$SciencesTableUpdateCompanionBuilder,
      (Science, BaseReferences<_$AppDatabase, $SciencesTable, Science>),
      Science,
      PrefetchHooks Function()
    >;
typedef $$SeriesEntriesTableCreateCompanionBuilder =
    SeriesEntriesCompanion Function({
      required String slug,
      required String scienceSlug,
      required String titleAr,
      Value<String?> descriptionAr,
      Value<String?> thumbnailUrl,
      Value<int> rowid,
    });
typedef $$SeriesEntriesTableUpdateCompanionBuilder =
    SeriesEntriesCompanion Function({
      Value<String> slug,
      Value<String> scienceSlug,
      Value<String> titleAr,
      Value<String?> descriptionAr,
      Value<String?> thumbnailUrl,
      Value<int> rowid,
    });

class $$SeriesEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SeriesEntriesTable> {
  $$SeriesEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scienceSlug => $composableBuilder(
    column: $table.scienceSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleAr => $composableBuilder(
    column: $table.titleAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionAr => $composableBuilder(
    column: $table.descriptionAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeriesEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SeriesEntriesTable> {
  $$SeriesEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scienceSlug => $composableBuilder(
    column: $table.scienceSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleAr => $composableBuilder(
    column: $table.titleAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionAr => $composableBuilder(
    column: $table.descriptionAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeriesEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeriesEntriesTable> {
  $$SeriesEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get scienceSlug => $composableBuilder(
    column: $table.scienceSlug,
    builder: (column) => column,
  );

  GeneratedColumn<String> get titleAr =>
      $composableBuilder(column: $table.titleAr, builder: (column) => column);

  GeneratedColumn<String> get descriptionAr => $composableBuilder(
    column: $table.descriptionAr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );
}

class $$SeriesEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeriesEntriesTable,
          SeriesRow,
          $$SeriesEntriesTableFilterComposer,
          $$SeriesEntriesTableOrderingComposer,
          $$SeriesEntriesTableAnnotationComposer,
          $$SeriesEntriesTableCreateCompanionBuilder,
          $$SeriesEntriesTableUpdateCompanionBuilder,
          (
            SeriesRow,
            BaseReferences<_$AppDatabase, $SeriesEntriesTable, SeriesRow>,
          ),
          SeriesRow,
          PrefetchHooks Function()
        > {
  $$SeriesEntriesTableTableManager(_$AppDatabase db, $SeriesEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> slug = const Value.absent(),
                Value<String> scienceSlug = const Value.absent(),
                Value<String> titleAr = const Value.absent(),
                Value<String?> descriptionAr = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesEntriesCompanion(
                slug: slug,
                scienceSlug: scienceSlug,
                titleAr: titleAr,
                descriptionAr: descriptionAr,
                thumbnailUrl: thumbnailUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String slug,
                required String scienceSlug,
                required String titleAr,
                Value<String?> descriptionAr = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesEntriesCompanion.insert(
                slug: slug,
                scienceSlug: scienceSlug,
                titleAr: titleAr,
                descriptionAr: descriptionAr,
                thumbnailUrl: thumbnailUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeriesEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeriesEntriesTable,
      SeriesRow,
      $$SeriesEntriesTableFilterComposer,
      $$SeriesEntriesTableOrderingComposer,
      $$SeriesEntriesTableAnnotationComposer,
      $$SeriesEntriesTableCreateCompanionBuilder,
      $$SeriesEntriesTableUpdateCompanionBuilder,
      (
        SeriesRow,
        BaseReferences<_$AppDatabase, $SeriesEntriesTable, SeriesRow>,
      ),
      SeriesRow,
      PrefetchHooks Function()
    >;
typedef $$LessonsTableCreateCompanionBuilder =
    LessonsCompanion Function({
      required String videoId,
      required String seriesSlug,
      required int position,
      required String titleAr,
      Value<int?> durationSeconds,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$LessonsTableUpdateCompanionBuilder =
    LessonsCompanion Function({
      Value<String> videoId,
      Value<String> seriesSlug,
      Value<int> position,
      Value<String> titleAr,
      Value<int?> durationSeconds,
      Value<String> status,
      Value<int> rowid,
    });

class $$LessonsTableFilterComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesSlug => $composableBuilder(
    column: $table.seriesSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleAr => $composableBuilder(
    column: $table.titleAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LessonsTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesSlug => $composableBuilder(
    column: $table.seriesSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleAr => $composableBuilder(
    column: $table.titleAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LessonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get seriesSlug => $composableBuilder(
    column: $table.seriesSlug,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get titleAr =>
      $composableBuilder(column: $table.titleAr, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$LessonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LessonsTable,
          Lesson,
          $$LessonsTableFilterComposer,
          $$LessonsTableOrderingComposer,
          $$LessonsTableAnnotationComposer,
          $$LessonsTableCreateCompanionBuilder,
          $$LessonsTableUpdateCompanionBuilder,
          (Lesson, BaseReferences<_$AppDatabase, $LessonsTable, Lesson>),
          Lesson,
          PrefetchHooks Function()
        > {
  $$LessonsTableTableManager(_$AppDatabase db, $LessonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> videoId = const Value.absent(),
                Value<String> seriesSlug = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> titleAr = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonsCompanion(
                videoId: videoId,
                seriesSlug: seriesSlug,
                position: position,
                titleAr: titleAr,
                durationSeconds: durationSeconds,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String videoId,
                required String seriesSlug,
                required int position,
                required String titleAr,
                Value<int?> durationSeconds = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonsCompanion.insert(
                videoId: videoId,
                seriesSlug: seriesSlug,
                position: position,
                titleAr: titleAr,
                durationSeconds: durationSeconds,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LessonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LessonsTable,
      Lesson,
      $$LessonsTableFilterComposer,
      $$LessonsTableOrderingComposer,
      $$LessonsTableAnnotationComposer,
      $$LessonsTableCreateCompanionBuilder,
      $$LessonsTableUpdateCompanionBuilder,
      (Lesson, BaseReferences<_$AppDatabase, $LessonsTable, Lesson>),
      Lesson,
      PrefetchHooks Function()
    >;
typedef $$JourneysTableCreateCompanionBuilder =
    JourneysCompanion Function({
      required String slug,
      required String titleAr,
      Value<String?> descriptionAr,
      required String level,
      Value<String?> scienceSlug,
      Value<String?> coverUrl,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$JourneysTableUpdateCompanionBuilder =
    JourneysCompanion Function({
      Value<String> slug,
      Value<String> titleAr,
      Value<String?> descriptionAr,
      Value<String> level,
      Value<String?> scienceSlug,
      Value<String?> coverUrl,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$JourneysTableFilterComposer
    extends Composer<_$AppDatabase, $JourneysTable> {
  $$JourneysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleAr => $composableBuilder(
    column: $table.titleAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionAr => $composableBuilder(
    column: $table.descriptionAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scienceSlug => $composableBuilder(
    column: $table.scienceSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JourneysTableOrderingComposer
    extends Composer<_$AppDatabase, $JourneysTable> {
  $$JourneysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleAr => $composableBuilder(
    column: $table.titleAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionAr => $composableBuilder(
    column: $table.descriptionAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scienceSlug => $composableBuilder(
    column: $table.scienceSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JourneysTableAnnotationComposer
    extends Composer<_$AppDatabase, $JourneysTable> {
  $$JourneysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get titleAr =>
      $composableBuilder(column: $table.titleAr, builder: (column) => column);

  GeneratedColumn<String> get descriptionAr => $composableBuilder(
    column: $table.descriptionAr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get scienceSlug => $composableBuilder(
    column: $table.scienceSlug,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$JourneysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JourneysTable,
          Journey,
          $$JourneysTableFilterComposer,
          $$JourneysTableOrderingComposer,
          $$JourneysTableAnnotationComposer,
          $$JourneysTableCreateCompanionBuilder,
          $$JourneysTableUpdateCompanionBuilder,
          (Journey, BaseReferences<_$AppDatabase, $JourneysTable, Journey>),
          Journey,
          PrefetchHooks Function()
        > {
  $$JourneysTableTableManager(_$AppDatabase db, $JourneysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JourneysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JourneysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JourneysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> slug = const Value.absent(),
                Value<String> titleAr = const Value.absent(),
                Value<String?> descriptionAr = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String?> scienceSlug = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneysCompanion(
                slug: slug,
                titleAr: titleAr,
                descriptionAr: descriptionAr,
                level: level,
                scienceSlug: scienceSlug,
                coverUrl: coverUrl,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String slug,
                required String titleAr,
                Value<String?> descriptionAr = const Value.absent(),
                required String level,
                Value<String?> scienceSlug = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneysCompanion.insert(
                slug: slug,
                titleAr: titleAr,
                descriptionAr: descriptionAr,
                level: level,
                scienceSlug: scienceSlug,
                coverUrl: coverUrl,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JourneysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JourneysTable,
      Journey,
      $$JourneysTableFilterComposer,
      $$JourneysTableOrderingComposer,
      $$JourneysTableAnnotationComposer,
      $$JourneysTableCreateCompanionBuilder,
      $$JourneysTableUpdateCompanionBuilder,
      (Journey, BaseReferences<_$AppDatabase, $JourneysTable, Journey>),
      Journey,
      PrefetchHooks Function()
    >;
typedef $$JourneyStagesTableCreateCompanionBuilder =
    JourneyStagesCompanion Function({
      required String journeySlug,
      required int position,
      required String titleAr,
      Value<String?> descriptionAr,
      Value<int> rowid,
    });
typedef $$JourneyStagesTableUpdateCompanionBuilder =
    JourneyStagesCompanion Function({
      Value<String> journeySlug,
      Value<int> position,
      Value<String> titleAr,
      Value<String?> descriptionAr,
      Value<int> rowid,
    });

class $$JourneyStagesTableFilterComposer
    extends Composer<_$AppDatabase, $JourneyStagesTable> {
  $$JourneyStagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get journeySlug => $composableBuilder(
    column: $table.journeySlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleAr => $composableBuilder(
    column: $table.titleAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionAr => $composableBuilder(
    column: $table.descriptionAr,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JourneyStagesTableOrderingComposer
    extends Composer<_$AppDatabase, $JourneyStagesTable> {
  $$JourneyStagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get journeySlug => $composableBuilder(
    column: $table.journeySlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleAr => $composableBuilder(
    column: $table.titleAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionAr => $composableBuilder(
    column: $table.descriptionAr,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JourneyStagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $JourneyStagesTable> {
  $$JourneyStagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get journeySlug => $composableBuilder(
    column: $table.journeySlug,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get titleAr =>
      $composableBuilder(column: $table.titleAr, builder: (column) => column);

  GeneratedColumn<String> get descriptionAr => $composableBuilder(
    column: $table.descriptionAr,
    builder: (column) => column,
  );
}

class $$JourneyStagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JourneyStagesTable,
          JourneyStage,
          $$JourneyStagesTableFilterComposer,
          $$JourneyStagesTableOrderingComposer,
          $$JourneyStagesTableAnnotationComposer,
          $$JourneyStagesTableCreateCompanionBuilder,
          $$JourneyStagesTableUpdateCompanionBuilder,
          (
            JourneyStage,
            BaseReferences<_$AppDatabase, $JourneyStagesTable, JourneyStage>,
          ),
          JourneyStage,
          PrefetchHooks Function()
        > {
  $$JourneyStagesTableTableManager(_$AppDatabase db, $JourneyStagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JourneyStagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JourneyStagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JourneyStagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> journeySlug = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> titleAr = const Value.absent(),
                Value<String?> descriptionAr = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneyStagesCompanion(
                journeySlug: journeySlug,
                position: position,
                titleAr: titleAr,
                descriptionAr: descriptionAr,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String journeySlug,
                required int position,
                required String titleAr,
                Value<String?> descriptionAr = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneyStagesCompanion.insert(
                journeySlug: journeySlug,
                position: position,
                titleAr: titleAr,
                descriptionAr: descriptionAr,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JourneyStagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JourneyStagesTable,
      JourneyStage,
      $$JourneyStagesTableFilterComposer,
      $$JourneyStagesTableOrderingComposer,
      $$JourneyStagesTableAnnotationComposer,
      $$JourneyStagesTableCreateCompanionBuilder,
      $$JourneyStagesTableUpdateCompanionBuilder,
      (
        JourneyStage,
        BaseReferences<_$AppDatabase, $JourneyStagesTable, JourneyStage>,
      ),
      JourneyStage,
      PrefetchHooks Function()
    >;
typedef $$JourneyItemsTableCreateCompanionBuilder =
    JourneyItemsCompanion Function({
      required String journeySlug,
      required int stagePosition,
      required int position,
      required String seriesSlug,
      Value<int> rowid,
    });
typedef $$JourneyItemsTableUpdateCompanionBuilder =
    JourneyItemsCompanion Function({
      Value<String> journeySlug,
      Value<int> stagePosition,
      Value<int> position,
      Value<String> seriesSlug,
      Value<int> rowid,
    });

class $$JourneyItemsTableFilterComposer
    extends Composer<_$AppDatabase, $JourneyItemsTable> {
  $$JourneyItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get journeySlug => $composableBuilder(
    column: $table.journeySlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stagePosition => $composableBuilder(
    column: $table.stagePosition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesSlug => $composableBuilder(
    column: $table.seriesSlug,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JourneyItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $JourneyItemsTable> {
  $$JourneyItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get journeySlug => $composableBuilder(
    column: $table.journeySlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stagePosition => $composableBuilder(
    column: $table.stagePosition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesSlug => $composableBuilder(
    column: $table.seriesSlug,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JourneyItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JourneyItemsTable> {
  $$JourneyItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get journeySlug => $composableBuilder(
    column: $table.journeySlug,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stagePosition => $composableBuilder(
    column: $table.stagePosition,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get seriesSlug => $composableBuilder(
    column: $table.seriesSlug,
    builder: (column) => column,
  );
}

class $$JourneyItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JourneyItemsTable,
          JourneyItem,
          $$JourneyItemsTableFilterComposer,
          $$JourneyItemsTableOrderingComposer,
          $$JourneyItemsTableAnnotationComposer,
          $$JourneyItemsTableCreateCompanionBuilder,
          $$JourneyItemsTableUpdateCompanionBuilder,
          (
            JourneyItem,
            BaseReferences<_$AppDatabase, $JourneyItemsTable, JourneyItem>,
          ),
          JourneyItem,
          PrefetchHooks Function()
        > {
  $$JourneyItemsTableTableManager(_$AppDatabase db, $JourneyItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JourneyItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JourneyItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JourneyItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> journeySlug = const Value.absent(),
                Value<int> stagePosition = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> seriesSlug = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneyItemsCompanion(
                journeySlug: journeySlug,
                stagePosition: stagePosition,
                position: position,
                seriesSlug: seriesSlug,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String journeySlug,
                required int stagePosition,
                required int position,
                required String seriesSlug,
                Value<int> rowid = const Value.absent(),
              }) => JourneyItemsCompanion.insert(
                journeySlug: journeySlug,
                stagePosition: stagePosition,
                position: position,
                seriesSlug: seriesSlug,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JourneyItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JourneyItemsTable,
      JourneyItem,
      $$JourneyItemsTableFilterComposer,
      $$JourneyItemsTableOrderingComposer,
      $$JourneyItemsTableAnnotationComposer,
      $$JourneyItemsTableCreateCompanionBuilder,
      $$JourneyItemsTableUpdateCompanionBuilder,
      (
        JourneyItem,
        BaseReferences<_$AppDatabase, $JourneyItemsTable, JourneyItem>,
      ),
      JourneyItem,
      PrefetchHooks Function()
    >;
typedef $$CatalogInfoTableCreateCompanionBuilder =
    CatalogInfoCompanion Function({
      Value<int> id,
      Value<int> version,
      Value<DateTime?> generatedAt,
    });
typedef $$CatalogInfoTableUpdateCompanionBuilder =
    CatalogInfoCompanion Function({
      Value<int> id,
      Value<int> version,
      Value<DateTime?> generatedAt,
    });

class $$CatalogInfoTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogInfoTable> {
  $$CatalogInfoTableFilterComposer({
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CatalogInfoTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogInfoTable> {
  $$CatalogInfoTableOrderingComposer({
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CatalogInfoTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogInfoTable> {
  $$CatalogInfoTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => column,
  );
}

class $$CatalogInfoTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatalogInfoTable,
          CatalogInfoData,
          $$CatalogInfoTableFilterComposer,
          $$CatalogInfoTableOrderingComposer,
          $$CatalogInfoTableAnnotationComposer,
          $$CatalogInfoTableCreateCompanionBuilder,
          $$CatalogInfoTableUpdateCompanionBuilder,
          (
            CatalogInfoData,
            BaseReferences<_$AppDatabase, $CatalogInfoTable, CatalogInfoData>,
          ),
          CatalogInfoData,
          PrefetchHooks Function()
        > {
  $$CatalogInfoTableTableManager(_$AppDatabase db, $CatalogInfoTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogInfoTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogInfoTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogInfoTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> generatedAt = const Value.absent(),
              }) => CatalogInfoCompanion(
                id: id,
                version: version,
                generatedAt: generatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> generatedAt = const Value.absent(),
              }) => CatalogInfoCompanion.insert(
                id: id,
                version: version,
                generatedAt: generatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CatalogInfoTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatalogInfoTable,
      CatalogInfoData,
      $$CatalogInfoTableFilterComposer,
      $$CatalogInfoTableOrderingComposer,
      $$CatalogInfoTableAnnotationComposer,
      $$CatalogInfoTableCreateCompanionBuilder,
      $$CatalogInfoTableUpdateCompanionBuilder,
      (
        CatalogInfoData,
        BaseReferences<_$AppDatabase, $CatalogInfoTable, CatalogInfoData>,
      ),
      CatalogInfoData,
      PrefetchHooks Function()
    >;
typedef $$LessonProgressTableCreateCompanionBuilder =
    LessonProgressCompanion Function({
      required String videoId,
      Value<int> watchedSeconds,
      Value<int?> durationSeconds,
      Value<bool> completed,
      required DateTime lastWatchedAt,
      required DateTime updatedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });
typedef $$LessonProgressTableUpdateCompanionBuilder =
    LessonProgressCompanion Function({
      Value<String> videoId,
      Value<int> watchedSeconds,
      Value<int?> durationSeconds,
      Value<bool> completed,
      Value<DateTime> lastWatchedAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
      Value<int> rowid,
    });

class $$LessonProgressTableFilterComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get watchedSeconds => $composableBuilder(
    column: $table.watchedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LessonProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get watchedSeconds => $composableBuilder(
    column: $table.watchedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LessonProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonProgressTable> {
  $$LessonProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<int> get watchedSeconds => $composableBuilder(
    column: $table.watchedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<DateTime> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LessonProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LessonProgressTable,
          LessonProgressData,
          $$LessonProgressTableFilterComposer,
          $$LessonProgressTableOrderingComposer,
          $$LessonProgressTableAnnotationComposer,
          $$LessonProgressTableCreateCompanionBuilder,
          $$LessonProgressTableUpdateCompanionBuilder,
          (
            LessonProgressData,
            BaseReferences<
              _$AppDatabase,
              $LessonProgressTable,
              LessonProgressData
            >,
          ),
          LessonProgressData,
          PrefetchHooks Function()
        > {
  $$LessonProgressTableTableManager(
    _$AppDatabase db,
    $LessonProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> videoId = const Value.absent(),
                Value<int> watchedSeconds = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime> lastWatchedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressCompanion(
                videoId: videoId,
                watchedSeconds: watchedSeconds,
                durationSeconds: durationSeconds,
                completed: completed,
                lastWatchedAt: lastWatchedAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String videoId,
                Value<int> watchedSeconds = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                required DateTime lastWatchedAt,
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressCompanion.insert(
                videoId: videoId,
                watchedSeconds: watchedSeconds,
                durationSeconds: durationSeconds,
                completed: completed,
                lastWatchedAt: lastWatchedAt,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LessonProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LessonProgressTable,
      LessonProgressData,
      $$LessonProgressTableFilterComposer,
      $$LessonProgressTableOrderingComposer,
      $$LessonProgressTableAnnotationComposer,
      $$LessonProgressTableCreateCompanionBuilder,
      $$LessonProgressTableUpdateCompanionBuilder,
      (
        LessonProgressData,
        BaseReferences<_$AppDatabase, $LessonProgressTable, LessonProgressData>,
      ),
      LessonProgressData,
      PrefetchHooks Function()
    >;
typedef $$JourneyEnrollmentsTableCreateCompanionBuilder =
    JourneyEnrollmentsCompanion Function({
      required String journeySlug,
      required DateTime enrolledAt,
      required DateTime lastActivityAt,
      Value<int> rowid,
    });
typedef $$JourneyEnrollmentsTableUpdateCompanionBuilder =
    JourneyEnrollmentsCompanion Function({
      Value<String> journeySlug,
      Value<DateTime> enrolledAt,
      Value<DateTime> lastActivityAt,
      Value<int> rowid,
    });

class $$JourneyEnrollmentsTableFilterComposer
    extends Composer<_$AppDatabase, $JourneyEnrollmentsTable> {
  $$JourneyEnrollmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get journeySlug => $composableBuilder(
    column: $table.journeySlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get enrolledAt => $composableBuilder(
    column: $table.enrolledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastActivityAt => $composableBuilder(
    column: $table.lastActivityAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JourneyEnrollmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $JourneyEnrollmentsTable> {
  $$JourneyEnrollmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get journeySlug => $composableBuilder(
    column: $table.journeySlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get enrolledAt => $composableBuilder(
    column: $table.enrolledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastActivityAt => $composableBuilder(
    column: $table.lastActivityAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JourneyEnrollmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JourneyEnrollmentsTable> {
  $$JourneyEnrollmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get journeySlug => $composableBuilder(
    column: $table.journeySlug,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get enrolledAt => $composableBuilder(
    column: $table.enrolledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastActivityAt => $composableBuilder(
    column: $table.lastActivityAt,
    builder: (column) => column,
  );
}

class $$JourneyEnrollmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JourneyEnrollmentsTable,
          JourneyEnrollment,
          $$JourneyEnrollmentsTableFilterComposer,
          $$JourneyEnrollmentsTableOrderingComposer,
          $$JourneyEnrollmentsTableAnnotationComposer,
          $$JourneyEnrollmentsTableCreateCompanionBuilder,
          $$JourneyEnrollmentsTableUpdateCompanionBuilder,
          (
            JourneyEnrollment,
            BaseReferences<
              _$AppDatabase,
              $JourneyEnrollmentsTable,
              JourneyEnrollment
            >,
          ),
          JourneyEnrollment,
          PrefetchHooks Function()
        > {
  $$JourneyEnrollmentsTableTableManager(
    _$AppDatabase db,
    $JourneyEnrollmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JourneyEnrollmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JourneyEnrollmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JourneyEnrollmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> journeySlug = const Value.absent(),
                Value<DateTime> enrolledAt = const Value.absent(),
                Value<DateTime> lastActivityAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneyEnrollmentsCompanion(
                journeySlug: journeySlug,
                enrolledAt: enrolledAt,
                lastActivityAt: lastActivityAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String journeySlug,
                required DateTime enrolledAt,
                required DateTime lastActivityAt,
                Value<int> rowid = const Value.absent(),
              }) => JourneyEnrollmentsCompanion.insert(
                journeySlug: journeySlug,
                enrolledAt: enrolledAt,
                lastActivityAt: lastActivityAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JourneyEnrollmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JourneyEnrollmentsTable,
      JourneyEnrollment,
      $$JourneyEnrollmentsTableFilterComposer,
      $$JourneyEnrollmentsTableOrderingComposer,
      $$JourneyEnrollmentsTableAnnotationComposer,
      $$JourneyEnrollmentsTableCreateCompanionBuilder,
      $$JourneyEnrollmentsTableUpdateCompanionBuilder,
      (
        JourneyEnrollment,
        BaseReferences<
          _$AppDatabase,
          $JourneyEnrollmentsTable,
          JourneyEnrollment
        >,
      ),
      JourneyEnrollment,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SciencesTableTableManager get sciences =>
      $$SciencesTableTableManager(_db, _db.sciences);
  $$SeriesEntriesTableTableManager get seriesEntries =>
      $$SeriesEntriesTableTableManager(_db, _db.seriesEntries);
  $$LessonsTableTableManager get lessons =>
      $$LessonsTableTableManager(_db, _db.lessons);
  $$JourneysTableTableManager get journeys =>
      $$JourneysTableTableManager(_db, _db.journeys);
  $$JourneyStagesTableTableManager get journeyStages =>
      $$JourneyStagesTableTableManager(_db, _db.journeyStages);
  $$JourneyItemsTableTableManager get journeyItems =>
      $$JourneyItemsTableTableManager(_db, _db.journeyItems);
  $$CatalogInfoTableTableManager get catalogInfo =>
      $$CatalogInfoTableTableManager(_db, _db.catalogInfo);
  $$LessonProgressTableTableManager get lessonProgress =>
      $$LessonProgressTableTableManager(_db, _db.lessonProgress);
  $$JourneyEnrollmentsTableTableManager get journeyEnrollments =>
      $$JourneyEnrollmentsTableTableManager(_db, _db.journeyEnrollments);
}
