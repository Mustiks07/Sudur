// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, ProfileRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<UiLanguage, String> uiLanguage =
      GeneratedColumn<String>('ui_language', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<UiLanguage>($ProfilesTable.$converteruiLanguage);
  @override
  late final GeneratedColumnWithTypeConverter<LearningPath, String> path =
      GeneratedColumn<String>('path', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<LearningPath>($ProfilesTable.$converterpath);
  static const VerificationMeta _dailyMinutesMeta =
      const VerificationMeta('dailyMinutes');
  @override
  late final GeneratedColumn<int> dailyMinutes = GeneratedColumn<int>(
      'daily_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<ReadingBehavior, String>
      behavior = GeneratedColumn<String>('behavior', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<ReadingBehavior>($ProfilesTable.$converterbehavior);
  static const VerificationMeta _showFirstWordMeta =
      const VerificationMeta('showFirstWord');
  @override
  late final GeneratedColumn<bool> showFirstWord = GeneratedColumn<bool>(
      'show_first_word', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_first_word" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, createdAt, uiLanguage, path, dailyMinutes, behavior, showFirstWord];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile';
  @override
  VerificationContext validateIntegrity(Insertable<ProfileRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('daily_minutes')) {
      context.handle(
          _dailyMinutesMeta,
          dailyMinutes.isAcceptableOrUnknown(
              data['daily_minutes']!, _dailyMinutesMeta));
    } else if (isInserting) {
      context.missing(_dailyMinutesMeta);
    }
    if (data.containsKey('show_first_word')) {
      context.handle(
          _showFirstWordMeta,
          showFirstWord.isAcceptableOrUnknown(
              data['show_first_word']!, _showFirstWordMeta));
    } else if (isInserting) {
      context.missing(_showFirstWordMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      uiLanguage: $ProfilesTable.$converteruiLanguage.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ui_language'])!),
      path: $ProfilesTable.$converterpath.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!),
      dailyMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}daily_minutes'])!,
      behavior: $ProfilesTable.$converterbehavior.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}behavior'])!),
      showFirstWord: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_first_word'])!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<UiLanguage, String, String> $converteruiLanguage =
      const EnumNameConverter<UiLanguage>(UiLanguage.values);
  static JsonTypeConverter2<LearningPath, String, String> $converterpath =
      const EnumNameConverter<LearningPath>(LearningPath.values);
  static JsonTypeConverter2<ReadingBehavior, String, String>
      $converterbehavior =
      const EnumNameConverter<ReadingBehavior>(ReadingBehavior.values);
}

class ProfileRecord extends DataClass implements Insertable<ProfileRecord> {
  final String id;
  final int createdAt;
  final UiLanguage uiLanguage;
  final LearningPath path;
  final int dailyMinutes;
  final ReadingBehavior behavior;
  final bool showFirstWord;
  const ProfileRecord(
      {required this.id,
      required this.createdAt,
      required this.uiLanguage,
      required this.path,
      required this.dailyMinutes,
      required this.behavior,
      required this.showFirstWord});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    {
      map['ui_language'] = Variable<String>(
          $ProfilesTable.$converteruiLanguage.toSql(uiLanguage));
    }
    {
      map['path'] = Variable<String>($ProfilesTable.$converterpath.toSql(path));
    }
    map['daily_minutes'] = Variable<int>(dailyMinutes);
    {
      map['behavior'] =
          Variable<String>($ProfilesTable.$converterbehavior.toSql(behavior));
    }
    map['show_first_word'] = Variable<bool>(showFirstWord);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      uiLanguage: Value(uiLanguage),
      path: Value(path),
      dailyMinutes: Value(dailyMinutes),
      behavior: Value(behavior),
      showFirstWord: Value(showFirstWord),
    );
  }

  factory ProfileRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRecord(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      uiLanguage: $ProfilesTable.$converteruiLanguage
          .fromJson(serializer.fromJson<String>(json['uiLanguage'])),
      path: $ProfilesTable.$converterpath
          .fromJson(serializer.fromJson<String>(json['path'])),
      dailyMinutes: serializer.fromJson<int>(json['dailyMinutes']),
      behavior: $ProfilesTable.$converterbehavior
          .fromJson(serializer.fromJson<String>(json['behavior'])),
      showFirstWord: serializer.fromJson<bool>(json['showFirstWord']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'uiLanguage': serializer.toJson<String>(
          $ProfilesTable.$converteruiLanguage.toJson(uiLanguage)),
      'path':
          serializer.toJson<String>($ProfilesTable.$converterpath.toJson(path)),
      'dailyMinutes': serializer.toJson<int>(dailyMinutes),
      'behavior': serializer
          .toJson<String>($ProfilesTable.$converterbehavior.toJson(behavior)),
      'showFirstWord': serializer.toJson<bool>(showFirstWord),
    };
  }

  ProfileRecord copyWith(
          {String? id,
          int? createdAt,
          UiLanguage? uiLanguage,
          LearningPath? path,
          int? dailyMinutes,
          ReadingBehavior? behavior,
          bool? showFirstWord}) =>
      ProfileRecord(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        uiLanguage: uiLanguage ?? this.uiLanguage,
        path: path ?? this.path,
        dailyMinutes: dailyMinutes ?? this.dailyMinutes,
        behavior: behavior ?? this.behavior,
        showFirstWord: showFirstWord ?? this.showFirstWord,
      );
  ProfileRecord copyWithCompanion(ProfilesCompanion data) {
    return ProfileRecord(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      uiLanguage:
          data.uiLanguage.present ? data.uiLanguage.value : this.uiLanguage,
      path: data.path.present ? data.path.value : this.path,
      dailyMinutes: data.dailyMinutes.present
          ? data.dailyMinutes.value
          : this.dailyMinutes,
      behavior: data.behavior.present ? data.behavior.value : this.behavior,
      showFirstWord: data.showFirstWord.present
          ? data.showFirstWord.value
          : this.showFirstWord,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRecord(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('uiLanguage: $uiLanguage, ')
          ..write('path: $path, ')
          ..write('dailyMinutes: $dailyMinutes, ')
          ..write('behavior: $behavior, ')
          ..write('showFirstWord: $showFirstWord')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, createdAt, uiLanguage, path, dailyMinutes, behavior, showFirstWord);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRecord &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.uiLanguage == this.uiLanguage &&
          other.path == this.path &&
          other.dailyMinutes == this.dailyMinutes &&
          other.behavior == this.behavior &&
          other.showFirstWord == this.showFirstWord);
}

class ProfilesCompanion extends UpdateCompanion<ProfileRecord> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<UiLanguage> uiLanguage;
  final Value<LearningPath> path;
  final Value<int> dailyMinutes;
  final Value<ReadingBehavior> behavior;
  final Value<bool> showFirstWord;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uiLanguage = const Value.absent(),
    this.path = const Value.absent(),
    this.dailyMinutes = const Value.absent(),
    this.behavior = const Value.absent(),
    this.showFirstWord = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required int createdAt,
    required UiLanguage uiLanguage,
    required LearningPath path,
    required int dailyMinutes,
    required ReadingBehavior behavior,
    required bool showFirstWord,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        uiLanguage = Value(uiLanguage),
        path = Value(path),
        dailyMinutes = Value(dailyMinutes),
        behavior = Value(behavior),
        showFirstWord = Value(showFirstWord);
  static Insertable<ProfileRecord> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<String>? uiLanguage,
    Expression<String>? path,
    Expression<int>? dailyMinutes,
    Expression<String>? behavior,
    Expression<bool>? showFirstWord,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (uiLanguage != null) 'ui_language': uiLanguage,
      if (path != null) 'path': path,
      if (dailyMinutes != null) 'daily_minutes': dailyMinutes,
      if (behavior != null) 'behavior': behavior,
      if (showFirstWord != null) 'show_first_word': showFirstWord,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith(
      {Value<String>? id,
      Value<int>? createdAt,
      Value<UiLanguage>? uiLanguage,
      Value<LearningPath>? path,
      Value<int>? dailyMinutes,
      Value<ReadingBehavior>? behavior,
      Value<bool>? showFirstWord,
      Value<int>? rowid}) {
    return ProfilesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      uiLanguage: uiLanguage ?? this.uiLanguage,
      path: path ?? this.path,
      dailyMinutes: dailyMinutes ?? this.dailyMinutes,
      behavior: behavior ?? this.behavior,
      showFirstWord: showFirstWord ?? this.showFirstWord,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (uiLanguage.present) {
      map['ui_language'] = Variable<String>(
          $ProfilesTable.$converteruiLanguage.toSql(uiLanguage.value));
    }
    if (path.present) {
      map['path'] =
          Variable<String>($ProfilesTable.$converterpath.toSql(path.value));
    }
    if (dailyMinutes.present) {
      map['daily_minutes'] = Variable<int>(dailyMinutes.value);
    }
    if (behavior.present) {
      map['behavior'] = Variable<String>(
          $ProfilesTable.$converterbehavior.toSql(behavior.value));
    }
    if (showFirstWord.present) {
      map['show_first_word'] = Variable<bool>(showFirstWord.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('uiLanguage: $uiLanguage, ')
          ..write('path: $path, ')
          ..write('dailyMinutes: $dailyMinutes, ')
          ..write('behavior: $behavior, ')
          ..write('showFirstWord: $showFirstWord, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitsTable extends Units with TableInfo<$UnitsTable, UnitRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profile_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<UnitKind, String> kind =
      GeneratedColumn<String>('kind', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<UnitKind>($UnitsTable.$converterkind);
  static const VerificationMeta _fromWordIndexMeta =
      const VerificationMeta('fromWordIndex');
  @override
  late final GeneratedColumn<int> fromWordIndex = GeneratedColumn<int>(
      'from_word_index', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _toWordIndexMeta =
      const VerificationMeta('toWordIndex');
  @override
  late final GeneratedColumn<int> toWordIndex = GeneratedColumn<int>(
      'to_word_index', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _skillIdMeta =
      const VerificationMeta('skillId');
  @override
  late final GeneratedColumn<String> skillId = GeneratedColumn<String>(
      'skill_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
      'surah', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<UnitOrigin, String> origin =
      GeneratedColumn<String>('origin', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<UnitOrigin>($UnitsTable.$converterorigin);
  static const VerificationMeta _parentUnitIdMeta =
      const VerificationMeta('parentUnitId');
  @override
  late final GeneratedColumn<String> parentUnitId = GeneratedColumn<String>(
      'parent_unit_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        kind,
        fromWordIndex,
        toWordIndex,
        skillId,
        surah,
        origin,
        parentUnitId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unit';
  @override
  VerificationContext validateIntegrity(Insertable<UnitRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('from_word_index')) {
      context.handle(
          _fromWordIndexMeta,
          fromWordIndex.isAcceptableOrUnknown(
              data['from_word_index']!, _fromWordIndexMeta));
    }
    if (data.containsKey('to_word_index')) {
      context.handle(
          _toWordIndexMeta,
          toWordIndex.isAcceptableOrUnknown(
              data['to_word_index']!, _toWordIndexMeta));
    }
    if (data.containsKey('skill_id')) {
      context.handle(_skillIdMeta,
          skillId.isAcceptableOrUnknown(data['skill_id']!, _skillIdMeta));
    }
    if (data.containsKey('surah')) {
      context.handle(
          _surahMeta, surah.isAcceptableOrUnknown(data['surah']!, _surahMeta));
    }
    if (data.containsKey('parent_unit_id')) {
      context.handle(
          _parentUnitIdMeta,
          parentUnitId.isAcceptableOrUnknown(
              data['parent_unit_id']!, _parentUnitIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UnitRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnitRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id'])!,
      kind: $UnitsTable.$converterkind.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
      fromWordIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}from_word_index']),
      toWordIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}to_word_index']),
      skillId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}skill_id']),
      surah: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah']),
      origin: $UnitsTable.$converterorigin.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}origin'])!),
      parentUnitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_unit_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $UnitsTable createAlias(String alias) {
    return $UnitsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<UnitKind, String, String> $converterkind =
      const EnumNameConverter<UnitKind>(UnitKind.values);
  static TypeConverter<UnitOrigin, String> $converterorigin =
      const UnitOriginConverter();
}

class UnitRecord extends DataClass implements Insertable<UnitRecord> {
  final String id;
  final String profileId;
  final UnitKind kind;
  final int? fromWordIndex;
  final int? toWordIndex;
  final String? skillId;
  final int? surah;
  final UnitOrigin origin;
  final String? parentUnitId;
  final int createdAt;
  const UnitRecord(
      {required this.id,
      required this.profileId,
      required this.kind,
      this.fromWordIndex,
      this.toWordIndex,
      this.skillId,
      this.surah,
      required this.origin,
      this.parentUnitId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    {
      map['kind'] = Variable<String>($UnitsTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || fromWordIndex != null) {
      map['from_word_index'] = Variable<int>(fromWordIndex);
    }
    if (!nullToAbsent || toWordIndex != null) {
      map['to_word_index'] = Variable<int>(toWordIndex);
    }
    if (!nullToAbsent || skillId != null) {
      map['skill_id'] = Variable<String>(skillId);
    }
    if (!nullToAbsent || surah != null) {
      map['surah'] = Variable<int>(surah);
    }
    {
      map['origin'] =
          Variable<String>($UnitsTable.$converterorigin.toSql(origin));
    }
    if (!nullToAbsent || parentUnitId != null) {
      map['parent_unit_id'] = Variable<String>(parentUnitId);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  UnitsCompanion toCompanion(bool nullToAbsent) {
    return UnitsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      kind: Value(kind),
      fromWordIndex: fromWordIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(fromWordIndex),
      toWordIndex: toWordIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(toWordIndex),
      skillId: skillId == null && nullToAbsent
          ? const Value.absent()
          : Value(skillId),
      surah:
          surah == null && nullToAbsent ? const Value.absent() : Value(surah),
      origin: Value(origin),
      parentUnitId: parentUnitId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentUnitId),
      createdAt: Value(createdAt),
    );
  }

  factory UnitRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnitRecord(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      kind: $UnitsTable.$converterkind
          .fromJson(serializer.fromJson<String>(json['kind'])),
      fromWordIndex: serializer.fromJson<int?>(json['fromWordIndex']),
      toWordIndex: serializer.fromJson<int?>(json['toWordIndex']),
      skillId: serializer.fromJson<String?>(json['skillId']),
      surah: serializer.fromJson<int?>(json['surah']),
      origin: serializer.fromJson<UnitOrigin>(json['origin']),
      parentUnitId: serializer.fromJson<String?>(json['parentUnitId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'kind':
          serializer.toJson<String>($UnitsTable.$converterkind.toJson(kind)),
      'fromWordIndex': serializer.toJson<int?>(fromWordIndex),
      'toWordIndex': serializer.toJson<int?>(toWordIndex),
      'skillId': serializer.toJson<String?>(skillId),
      'surah': serializer.toJson<int?>(surah),
      'origin': serializer.toJson<UnitOrigin>(origin),
      'parentUnitId': serializer.toJson<String?>(parentUnitId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  UnitRecord copyWith(
          {String? id,
          String? profileId,
          UnitKind? kind,
          Value<int?> fromWordIndex = const Value.absent(),
          Value<int?> toWordIndex = const Value.absent(),
          Value<String?> skillId = const Value.absent(),
          Value<int?> surah = const Value.absent(),
          UnitOrigin? origin,
          Value<String?> parentUnitId = const Value.absent(),
          int? createdAt}) =>
      UnitRecord(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        kind: kind ?? this.kind,
        fromWordIndex:
            fromWordIndex.present ? fromWordIndex.value : this.fromWordIndex,
        toWordIndex: toWordIndex.present ? toWordIndex.value : this.toWordIndex,
        skillId: skillId.present ? skillId.value : this.skillId,
        surah: surah.present ? surah.value : this.surah,
        origin: origin ?? this.origin,
        parentUnitId:
            parentUnitId.present ? parentUnitId.value : this.parentUnitId,
        createdAt: createdAt ?? this.createdAt,
      );
  UnitRecord copyWithCompanion(UnitsCompanion data) {
    return UnitRecord(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      kind: data.kind.present ? data.kind.value : this.kind,
      fromWordIndex: data.fromWordIndex.present
          ? data.fromWordIndex.value
          : this.fromWordIndex,
      toWordIndex:
          data.toWordIndex.present ? data.toWordIndex.value : this.toWordIndex,
      skillId: data.skillId.present ? data.skillId.value : this.skillId,
      surah: data.surah.present ? data.surah.value : this.surah,
      origin: data.origin.present ? data.origin.value : this.origin,
      parentUnitId: data.parentUnitId.present
          ? data.parentUnitId.value
          : this.parentUnitId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnitRecord(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('kind: $kind, ')
          ..write('fromWordIndex: $fromWordIndex, ')
          ..write('toWordIndex: $toWordIndex, ')
          ..write('skillId: $skillId, ')
          ..write('surah: $surah, ')
          ..write('origin: $origin, ')
          ..write('parentUnitId: $parentUnitId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, kind, fromWordIndex,
      toWordIndex, skillId, surah, origin, parentUnitId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnitRecord &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.kind == this.kind &&
          other.fromWordIndex == this.fromWordIndex &&
          other.toWordIndex == this.toWordIndex &&
          other.skillId == this.skillId &&
          other.surah == this.surah &&
          other.origin == this.origin &&
          other.parentUnitId == this.parentUnitId &&
          other.createdAt == this.createdAt);
}

class UnitsCompanion extends UpdateCompanion<UnitRecord> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<UnitKind> kind;
  final Value<int?> fromWordIndex;
  final Value<int?> toWordIndex;
  final Value<String?> skillId;
  final Value<int?> surah;
  final Value<UnitOrigin> origin;
  final Value<String?> parentUnitId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const UnitsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.kind = const Value.absent(),
    this.fromWordIndex = const Value.absent(),
    this.toWordIndex = const Value.absent(),
    this.skillId = const Value.absent(),
    this.surah = const Value.absent(),
    this.origin = const Value.absent(),
    this.parentUnitId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitsCompanion.insert({
    required String id,
    required String profileId,
    required UnitKind kind,
    this.fromWordIndex = const Value.absent(),
    this.toWordIndex = const Value.absent(),
    this.skillId = const Value.absent(),
    this.surah = const Value.absent(),
    required UnitOrigin origin,
    this.parentUnitId = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        kind = Value(kind),
        origin = Value(origin),
        createdAt = Value(createdAt);
  static Insertable<UnitRecord> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? kind,
    Expression<int>? fromWordIndex,
    Expression<int>? toWordIndex,
    Expression<String>? skillId,
    Expression<int>? surah,
    Expression<String>? origin,
    Expression<String>? parentUnitId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (kind != null) 'kind': kind,
      if (fromWordIndex != null) 'from_word_index': fromWordIndex,
      if (toWordIndex != null) 'to_word_index': toWordIndex,
      if (skillId != null) 'skill_id': skillId,
      if (surah != null) 'surah': surah,
      if (origin != null) 'origin': origin,
      if (parentUnitId != null) 'parent_unit_id': parentUnitId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitsCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<UnitKind>? kind,
      Value<int?>? fromWordIndex,
      Value<int?>? toWordIndex,
      Value<String?>? skillId,
      Value<int?>? surah,
      Value<UnitOrigin>? origin,
      Value<String?>? parentUnitId,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return UnitsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      kind: kind ?? this.kind,
      fromWordIndex: fromWordIndex ?? this.fromWordIndex,
      toWordIndex: toWordIndex ?? this.toWordIndex,
      skillId: skillId ?? this.skillId,
      surah: surah ?? this.surah,
      origin: origin ?? this.origin,
      parentUnitId: parentUnitId ?? this.parentUnitId,
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
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (kind.present) {
      map['kind'] =
          Variable<String>($UnitsTable.$converterkind.toSql(kind.value));
    }
    if (fromWordIndex.present) {
      map['from_word_index'] = Variable<int>(fromWordIndex.value);
    }
    if (toWordIndex.present) {
      map['to_word_index'] = Variable<int>(toWordIndex.value);
    }
    if (skillId.present) {
      map['skill_id'] = Variable<String>(skillId.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (origin.present) {
      map['origin'] =
          Variable<String>($UnitsTable.$converterorigin.toSql(origin.value));
    }
    if (parentUnitId.present) {
      map['parent_unit_id'] = Variable<String>(parentUnitId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('kind: $kind, ')
          ..write('fromWordIndex: $fromWordIndex, ')
          ..write('toWordIndex: $toWordIndex, ')
          ..write('skillId: $skillId, ')
          ..write('surah: $surah, ')
          ..write('origin: $origin, ')
          ..write('parentUnitId: $parentUnitId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitStatesTable extends UnitStates
    with TableInfo<$UnitStatesTable, UnitStateRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
      'unit_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<UnitQueue, String> queue =
      GeneratedColumn<String>('queue', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<UnitQueue>($UnitStatesTable.$converterqueue);
  @override
  late final GeneratedColumnWithTypeConverter<JsonObjectData?, String>
      memoryState = GeneratedColumn<String>('memory_state', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<JsonObjectData?>(
              $UnitStatesTable.$convertermemoryStaten);
  @override
  late final GeneratedColumnWithTypeConverter<JsonObjectData?, String>
      fsrsCard = GeneratedColumn<String>('fsrs_card', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<JsonObjectData?>($UnitStatesTable.$converterfsrsCardn);
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<int> dueAt = GeneratedColumn<int>(
      'due_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _recentSinceMeta =
      const VerificationMeta('recentSince');
  @override
  late final GeneratedColumn<int> recentSince = GeneratedColumn<int>(
      'recent_since', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastAttemptAtMeta =
      const VerificationMeta('lastAttemptAt');
  @override
  late final GeneratedColumn<int> lastAttemptAt = GeneratedColumn<int>(
      'last_attempt_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<CheckMethod?, String> lastMethod =
      GeneratedColumn<String>('last_method', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<CheckMethod?>($UnitStatesTable.$converterlastMethodn);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        unitId,
        queue,
        memoryState,
        fsrsCard,
        dueAt,
        recentSince,
        lastAttemptAt,
        lastMethod,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unit_state';
  @override
  VerificationContext validateIntegrity(Insertable<UnitStateRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    } else if (isInserting) {
      context.missing(_unitIdMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
          _dueAtMeta, dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta));
    }
    if (data.containsKey('recent_since')) {
      context.handle(
          _recentSinceMeta,
          recentSince.isAcceptableOrUnknown(
              data['recent_since']!, _recentSinceMeta));
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
          _lastAttemptAtMeta,
          lastAttemptAt.isAcceptableOrUnknown(
              data['last_attempt_at']!, _lastAttemptAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {unitId};
  @override
  UnitStateRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnitStateRecord(
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_id'])!,
      queue: $UnitStatesTable.$converterqueue.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}queue'])!),
      memoryState: $UnitStatesTable.$convertermemoryStaten.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}memory_state'])),
      fsrsCard: $UnitStatesTable.$converterfsrsCardn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fsrs_card'])),
      dueAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}due_at']),
      recentSince: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}recent_since']),
      lastAttemptAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_attempt_at']),
      lastMethod: $UnitStatesTable.$converterlastMethodn.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}last_method'])),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UnitStatesTable createAlias(String alias) {
    return $UnitStatesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<UnitQueue, String, String> $converterqueue =
      const EnumNameConverter<UnitQueue>(UnitQueue.values);
  static TypeConverter<JsonObjectData, String> $convertermemoryState =
      const JsonObjectConverter();
  static TypeConverter<JsonObjectData?, String?> $convertermemoryStaten =
      NullAwareTypeConverter.wrap($convertermemoryState);
  static TypeConverter<JsonObjectData, String> $converterfsrsCard =
      const JsonObjectConverter();
  static TypeConverter<JsonObjectData?, String?> $converterfsrsCardn =
      NullAwareTypeConverter.wrap($converterfsrsCard);
  static JsonTypeConverter2<CheckMethod, String, String> $converterlastMethod =
      const EnumNameConverter<CheckMethod>(CheckMethod.values);
  static JsonTypeConverter2<CheckMethod?, String?, String?>
      $converterlastMethodn =
      JsonTypeConverter2.asNullable($converterlastMethod);
}

class UnitStateRecord extends DataClass implements Insertable<UnitStateRecord> {
  final String unitId;
  final UnitQueue queue;
  final JsonObjectData? memoryState;
  final JsonObjectData? fsrsCard;
  final int? dueAt;
  final int? recentSince;
  final int? lastAttemptAt;
  final CheckMethod? lastMethod;
  final int updatedAt;
  const UnitStateRecord(
      {required this.unitId,
      required this.queue,
      this.memoryState,
      this.fsrsCard,
      this.dueAt,
      this.recentSince,
      this.lastAttemptAt,
      this.lastMethod,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['unit_id'] = Variable<String>(unitId);
    {
      map['queue'] =
          Variable<String>($UnitStatesTable.$converterqueue.toSql(queue));
    }
    if (!nullToAbsent || memoryState != null) {
      map['memory_state'] = Variable<String>(
          $UnitStatesTable.$convertermemoryStaten.toSql(memoryState));
    }
    if (!nullToAbsent || fsrsCard != null) {
      map['fsrs_card'] = Variable<String>(
          $UnitStatesTable.$converterfsrsCardn.toSql(fsrsCard));
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<int>(dueAt);
    }
    if (!nullToAbsent || recentSince != null) {
      map['recent_since'] = Variable<int>(recentSince);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt);
    }
    if (!nullToAbsent || lastMethod != null) {
      map['last_method'] = Variable<String>(
          $UnitStatesTable.$converterlastMethodn.toSql(lastMethod));
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  UnitStatesCompanion toCompanion(bool nullToAbsent) {
    return UnitStatesCompanion(
      unitId: Value(unitId),
      queue: Value(queue),
      memoryState: memoryState == null && nullToAbsent
          ? const Value.absent()
          : Value(memoryState),
      fsrsCard: fsrsCard == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsCard),
      dueAt:
          dueAt == null && nullToAbsent ? const Value.absent() : Value(dueAt),
      recentSince: recentSince == null && nullToAbsent
          ? const Value.absent()
          : Value(recentSince),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastMethod: lastMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMethod),
      updatedAt: Value(updatedAt),
    );
  }

  factory UnitStateRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnitStateRecord(
      unitId: serializer.fromJson<String>(json['unitId']),
      queue: $UnitStatesTable.$converterqueue
          .fromJson(serializer.fromJson<String>(json['queue'])),
      memoryState: serializer.fromJson<JsonObjectData?>(json['memoryState']),
      fsrsCard: serializer.fromJson<JsonObjectData?>(json['fsrsCard']),
      dueAt: serializer.fromJson<int?>(json['dueAt']),
      recentSince: serializer.fromJson<int?>(json['recentSince']),
      lastAttemptAt: serializer.fromJson<int?>(json['lastAttemptAt']),
      lastMethod: $UnitStatesTable.$converterlastMethodn
          .fromJson(serializer.fromJson<String?>(json['lastMethod'])),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'unitId': serializer.toJson<String>(unitId),
      'queue': serializer
          .toJson<String>($UnitStatesTable.$converterqueue.toJson(queue)),
      'memoryState': serializer.toJson<JsonObjectData?>(memoryState),
      'fsrsCard': serializer.toJson<JsonObjectData?>(fsrsCard),
      'dueAt': serializer.toJson<int?>(dueAt),
      'recentSince': serializer.toJson<int?>(recentSince),
      'lastAttemptAt': serializer.toJson<int?>(lastAttemptAt),
      'lastMethod': serializer.toJson<String?>(
          $UnitStatesTable.$converterlastMethodn.toJson(lastMethod)),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  UnitStateRecord copyWith(
          {String? unitId,
          UnitQueue? queue,
          Value<JsonObjectData?> memoryState = const Value.absent(),
          Value<JsonObjectData?> fsrsCard = const Value.absent(),
          Value<int?> dueAt = const Value.absent(),
          Value<int?> recentSince = const Value.absent(),
          Value<int?> lastAttemptAt = const Value.absent(),
          Value<CheckMethod?> lastMethod = const Value.absent(),
          int? updatedAt}) =>
      UnitStateRecord(
        unitId: unitId ?? this.unitId,
        queue: queue ?? this.queue,
        memoryState: memoryState.present ? memoryState.value : this.memoryState,
        fsrsCard: fsrsCard.present ? fsrsCard.value : this.fsrsCard,
        dueAt: dueAt.present ? dueAt.value : this.dueAt,
        recentSince: recentSince.present ? recentSince.value : this.recentSince,
        lastAttemptAt:
            lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
        lastMethod: lastMethod.present ? lastMethod.value : this.lastMethod,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  UnitStateRecord copyWithCompanion(UnitStatesCompanion data) {
    return UnitStateRecord(
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      queue: data.queue.present ? data.queue.value : this.queue,
      memoryState:
          data.memoryState.present ? data.memoryState.value : this.memoryState,
      fsrsCard: data.fsrsCard.present ? data.fsrsCard.value : this.fsrsCard,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      recentSince:
          data.recentSince.present ? data.recentSince.value : this.recentSince,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastMethod:
          data.lastMethod.present ? data.lastMethod.value : this.lastMethod,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnitStateRecord(')
          ..write('unitId: $unitId, ')
          ..write('queue: $queue, ')
          ..write('memoryState: $memoryState, ')
          ..write('fsrsCard: $fsrsCard, ')
          ..write('dueAt: $dueAt, ')
          ..write('recentSince: $recentSince, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastMethod: $lastMethod, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(unitId, queue, memoryState, fsrsCard, dueAt,
      recentSince, lastAttemptAt, lastMethod, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnitStateRecord &&
          other.unitId == this.unitId &&
          other.queue == this.queue &&
          other.memoryState == this.memoryState &&
          other.fsrsCard == this.fsrsCard &&
          other.dueAt == this.dueAt &&
          other.recentSince == this.recentSince &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastMethod == this.lastMethod &&
          other.updatedAt == this.updatedAt);
}

class UnitStatesCompanion extends UpdateCompanion<UnitStateRecord> {
  final Value<String> unitId;
  final Value<UnitQueue> queue;
  final Value<JsonObjectData?> memoryState;
  final Value<JsonObjectData?> fsrsCard;
  final Value<int?> dueAt;
  final Value<int?> recentSince;
  final Value<int?> lastAttemptAt;
  final Value<CheckMethod?> lastMethod;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const UnitStatesCompanion({
    this.unitId = const Value.absent(),
    this.queue = const Value.absent(),
    this.memoryState = const Value.absent(),
    this.fsrsCard = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.recentSince = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastMethod = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitStatesCompanion.insert({
    required String unitId,
    required UnitQueue queue,
    this.memoryState = const Value.absent(),
    this.fsrsCard = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.recentSince = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastMethod = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : unitId = Value(unitId),
        queue = Value(queue),
        updatedAt = Value(updatedAt);
  static Insertable<UnitStateRecord> custom({
    Expression<String>? unitId,
    Expression<String>? queue,
    Expression<String>? memoryState,
    Expression<String>? fsrsCard,
    Expression<int>? dueAt,
    Expression<int>? recentSince,
    Expression<int>? lastAttemptAt,
    Expression<String>? lastMethod,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (unitId != null) 'unit_id': unitId,
      if (queue != null) 'queue': queue,
      if (memoryState != null) 'memory_state': memoryState,
      if (fsrsCard != null) 'fsrs_card': fsrsCard,
      if (dueAt != null) 'due_at': dueAt,
      if (recentSince != null) 'recent_since': recentSince,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastMethod != null) 'last_method': lastMethod,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitStatesCompanion copyWith(
      {Value<String>? unitId,
      Value<UnitQueue>? queue,
      Value<JsonObjectData?>? memoryState,
      Value<JsonObjectData?>? fsrsCard,
      Value<int?>? dueAt,
      Value<int?>? recentSince,
      Value<int?>? lastAttemptAt,
      Value<CheckMethod?>? lastMethod,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return UnitStatesCompanion(
      unitId: unitId ?? this.unitId,
      queue: queue ?? this.queue,
      memoryState: memoryState ?? this.memoryState,
      fsrsCard: fsrsCard ?? this.fsrsCard,
      dueAt: dueAt ?? this.dueAt,
      recentSince: recentSince ?? this.recentSince,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastMethod: lastMethod ?? this.lastMethod,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (queue.present) {
      map['queue'] =
          Variable<String>($UnitStatesTable.$converterqueue.toSql(queue.value));
    }
    if (memoryState.present) {
      map['memory_state'] = Variable<String>(
          $UnitStatesTable.$convertermemoryStaten.toSql(memoryState.value));
    }
    if (fsrsCard.present) {
      map['fsrs_card'] = Variable<String>(
          $UnitStatesTable.$converterfsrsCardn.toSql(fsrsCard.value));
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (recentSince.present) {
      map['recent_since'] = Variable<int>(recentSince.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt.value);
    }
    if (lastMethod.present) {
      map['last_method'] = Variable<String>(
          $UnitStatesTable.$converterlastMethodn.toSql(lastMethod.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitStatesCompanion(')
          ..write('unitId: $unitId, ')
          ..write('queue: $queue, ')
          ..write('memoryState: $memoryState, ')
          ..write('fsrsCard: $fsrsCard, ')
          ..write('dueAt: $dueAt, ')
          ..write('recentSince: $recentSince, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastMethod: $lastMethod, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttemptsTable extends Attempts
    with TableInfo<$AttemptsTable, AttemptRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
      'unit_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<StoredReadingMode, String> mode =
      GeneratedColumn<String>('mode', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<StoredReadingMode>($AttemptsTable.$convertermode);
  @override
  late final GeneratedColumnWithTypeConverter<AttemptOutcome, String> outcome =
      GeneratedColumn<String>('outcome', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<AttemptOutcome>($AttemptsTable.$converteroutcome);
  @override
  late final GeneratedColumnWithTypeConverter<HintCounts, String> hints =
      GeneratedColumn<String>('hints', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<HintCounts>($AttemptsTable.$converterhints);
  @override
  late final GeneratedColumnWithTypeConverter<ErrorEventIds, String>
      errorEventIds = GeneratedColumn<String>(
              'error_event_ids', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<ErrorEventIds>($AttemptsTable.$convertererrorEventIds);
  @override
  late final GeneratedColumnWithTypeConverter<AttemptRating?, String> rating =
      GeneratedColumn<String>('rating', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<AttemptRating?>($AttemptsTable.$converterratingn);
  @override
  late final GeneratedColumnWithTypeConverter<CheckMethod, String> method =
      GeneratedColumn<String>('method', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<CheckMethod>($AttemptsTable.$convertermethod);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _wordsMeta = const VerificationMeta('words');
  @override
  late final GeneratedColumn<int> words = GeneratedColumn<int>(
      'words', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _modelIdMeta =
      const VerificationMeta('modelId');
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
      'model_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelVersionMeta =
      const VerificationMeta('modelVersion');
  @override
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
      'model_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rulesVersionMeta =
      const VerificationMeta('rulesVersion');
  @override
  late final GeneratedColumn<String> rulesVersion = GeneratedColumn<String>(
      'rules_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _textVersionMeta =
      const VerificationMeta('textVersion');
  @override
  late final GeneratedColumn<String> textVersion = GeneratedColumn<String>(
      'text_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        unitId,
        sessionId,
        mode,
        outcome,
        hints,
        errorEventIds,
        rating,
        method,
        durationMs,
        words,
        modelId,
        modelVersion,
        rulesVersion,
        textVersion,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attempt';
  @override
  VerificationContext validateIntegrity(Insertable<AttemptRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    } else if (isInserting) {
      context.missing(_unitIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('words')) {
      context.handle(
          _wordsMeta, words.isAcceptableOrUnknown(data['words']!, _wordsMeta));
    } else if (isInserting) {
      context.missing(_wordsMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(_modelIdMeta,
          modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta));
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('model_version')) {
      context.handle(
          _modelVersionMeta,
          modelVersion.isAcceptableOrUnknown(
              data['model_version']!, _modelVersionMeta));
    } else if (isInserting) {
      context.missing(_modelVersionMeta);
    }
    if (data.containsKey('rules_version')) {
      context.handle(
          _rulesVersionMeta,
          rulesVersion.isAcceptableOrUnknown(
              data['rules_version']!, _rulesVersionMeta));
    } else if (isInserting) {
      context.missing(_rulesVersionMeta);
    }
    if (data.containsKey('text_version')) {
      context.handle(
          _textVersionMeta,
          textVersion.isAcceptableOrUnknown(
              data['text_version']!, _textVersionMeta));
    } else if (isInserting) {
      context.missing(_textVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttemptRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttemptRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      mode: $AttemptsTable.$convertermode.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!),
      outcome: $AttemptsTable.$converteroutcome.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}outcome'])!),
      hints: $AttemptsTable.$converterhints.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hints'])!),
      errorEventIds: $AttemptsTable.$convertererrorEventIds.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}error_event_ids'])!),
      rating: $AttemptsTable.$converterratingn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rating'])),
      method: $AttemptsTable.$convertermethod.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!),
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      words: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}words'])!,
      modelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_id'])!,
      modelVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_version'])!,
      rulesVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rules_version'])!,
      textVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text_version'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AttemptsTable createAlias(String alias) {
    return $AttemptsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<StoredReadingMode, String, String> $convertermode =
      const EnumNameConverter<StoredReadingMode>(StoredReadingMode.values);
  static JsonTypeConverter2<AttemptOutcome, String, String> $converteroutcome =
      const EnumNameConverter<AttemptOutcome>(AttemptOutcome.values);
  static TypeConverter<HintCounts, String> $converterhints =
      const HintCountsConverter();
  static TypeConverter<ErrorEventIds, String> $convertererrorEventIds =
      const ErrorEventIdsConverter();
  static JsonTypeConverter2<AttemptRating, String, String> $converterrating =
      const EnumNameConverter<AttemptRating>(AttemptRating.values);
  static JsonTypeConverter2<AttemptRating?, String?, String?>
      $converterratingn = JsonTypeConverter2.asNullable($converterrating);
  static JsonTypeConverter2<CheckMethod, String, String> $convertermethod =
      const EnumNameConverter<CheckMethod>(CheckMethod.values);
}

class AttemptRecord extends DataClass implements Insertable<AttemptRecord> {
  final String id;
  final String unitId;
  final String sessionId;
  final StoredReadingMode mode;
  final AttemptOutcome outcome;
  final HintCounts hints;
  final ErrorEventIds errorEventIds;
  final AttemptRating? rating;
  final CheckMethod method;
  final int durationMs;
  final int words;
  final String modelId;
  final String modelVersion;
  final String rulesVersion;
  final String textVersion;
  final int createdAt;
  const AttemptRecord(
      {required this.id,
      required this.unitId,
      required this.sessionId,
      required this.mode,
      required this.outcome,
      required this.hints,
      required this.errorEventIds,
      this.rating,
      required this.method,
      required this.durationMs,
      required this.words,
      required this.modelId,
      required this.modelVersion,
      required this.rulesVersion,
      required this.textVersion,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['unit_id'] = Variable<String>(unitId);
    map['session_id'] = Variable<String>(sessionId);
    {
      map['mode'] = Variable<String>($AttemptsTable.$convertermode.toSql(mode));
    }
    {
      map['outcome'] =
          Variable<String>($AttemptsTable.$converteroutcome.toSql(outcome));
    }
    {
      map['hints'] =
          Variable<String>($AttemptsTable.$converterhints.toSql(hints));
    }
    {
      map['error_event_ids'] = Variable<String>(
          $AttemptsTable.$convertererrorEventIds.toSql(errorEventIds));
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] =
          Variable<String>($AttemptsTable.$converterratingn.toSql(rating));
    }
    {
      map['method'] =
          Variable<String>($AttemptsTable.$convertermethod.toSql(method));
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['words'] = Variable<int>(words);
    map['model_id'] = Variable<String>(modelId);
    map['model_version'] = Variable<String>(modelVersion);
    map['rules_version'] = Variable<String>(rulesVersion);
    map['text_version'] = Variable<String>(textVersion);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AttemptsCompanion toCompanion(bool nullToAbsent) {
    return AttemptsCompanion(
      id: Value(id),
      unitId: Value(unitId),
      sessionId: Value(sessionId),
      mode: Value(mode),
      outcome: Value(outcome),
      hints: Value(hints),
      errorEventIds: Value(errorEventIds),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      method: Value(method),
      durationMs: Value(durationMs),
      words: Value(words),
      modelId: Value(modelId),
      modelVersion: Value(modelVersion),
      rulesVersion: Value(rulesVersion),
      textVersion: Value(textVersion),
      createdAt: Value(createdAt),
    );
  }

  factory AttemptRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttemptRecord(
      id: serializer.fromJson<String>(json['id']),
      unitId: serializer.fromJson<String>(json['unitId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      mode: $AttemptsTable.$convertermode
          .fromJson(serializer.fromJson<String>(json['mode'])),
      outcome: $AttemptsTable.$converteroutcome
          .fromJson(serializer.fromJson<String>(json['outcome'])),
      hints: serializer.fromJson<HintCounts>(json['hints']),
      errorEventIds: serializer.fromJson<ErrorEventIds>(json['errorEventIds']),
      rating: $AttemptsTable.$converterratingn
          .fromJson(serializer.fromJson<String?>(json['rating'])),
      method: $AttemptsTable.$convertermethod
          .fromJson(serializer.fromJson<String>(json['method'])),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      words: serializer.fromJson<int>(json['words']),
      modelId: serializer.fromJson<String>(json['modelId']),
      modelVersion: serializer.fromJson<String>(json['modelVersion']),
      rulesVersion: serializer.fromJson<String>(json['rulesVersion']),
      textVersion: serializer.fromJson<String>(json['textVersion']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'unitId': serializer.toJson<String>(unitId),
      'sessionId': serializer.toJson<String>(sessionId),
      'mode':
          serializer.toJson<String>($AttemptsTable.$convertermode.toJson(mode)),
      'outcome': serializer
          .toJson<String>($AttemptsTable.$converteroutcome.toJson(outcome)),
      'hints': serializer.toJson<HintCounts>(hints),
      'errorEventIds': serializer.toJson<ErrorEventIds>(errorEventIds),
      'rating': serializer
          .toJson<String?>($AttemptsTable.$converterratingn.toJson(rating)),
      'method': serializer
          .toJson<String>($AttemptsTable.$convertermethod.toJson(method)),
      'durationMs': serializer.toJson<int>(durationMs),
      'words': serializer.toJson<int>(words),
      'modelId': serializer.toJson<String>(modelId),
      'modelVersion': serializer.toJson<String>(modelVersion),
      'rulesVersion': serializer.toJson<String>(rulesVersion),
      'textVersion': serializer.toJson<String>(textVersion),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  AttemptRecord copyWith(
          {String? id,
          String? unitId,
          String? sessionId,
          StoredReadingMode? mode,
          AttemptOutcome? outcome,
          HintCounts? hints,
          ErrorEventIds? errorEventIds,
          Value<AttemptRating?> rating = const Value.absent(),
          CheckMethod? method,
          int? durationMs,
          int? words,
          String? modelId,
          String? modelVersion,
          String? rulesVersion,
          String? textVersion,
          int? createdAt}) =>
      AttemptRecord(
        id: id ?? this.id,
        unitId: unitId ?? this.unitId,
        sessionId: sessionId ?? this.sessionId,
        mode: mode ?? this.mode,
        outcome: outcome ?? this.outcome,
        hints: hints ?? this.hints,
        errorEventIds: errorEventIds ?? this.errorEventIds,
        rating: rating.present ? rating.value : this.rating,
        method: method ?? this.method,
        durationMs: durationMs ?? this.durationMs,
        words: words ?? this.words,
        modelId: modelId ?? this.modelId,
        modelVersion: modelVersion ?? this.modelVersion,
        rulesVersion: rulesVersion ?? this.rulesVersion,
        textVersion: textVersion ?? this.textVersion,
        createdAt: createdAt ?? this.createdAt,
      );
  AttemptRecord copyWithCompanion(AttemptsCompanion data) {
    return AttemptRecord(
      id: data.id.present ? data.id.value : this.id,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      mode: data.mode.present ? data.mode.value : this.mode,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      hints: data.hints.present ? data.hints.value : this.hints,
      errorEventIds: data.errorEventIds.present
          ? data.errorEventIds.value
          : this.errorEventIds,
      rating: data.rating.present ? data.rating.value : this.rating,
      method: data.method.present ? data.method.value : this.method,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      words: data.words.present ? data.words.value : this.words,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      rulesVersion: data.rulesVersion.present
          ? data.rulesVersion.value
          : this.rulesVersion,
      textVersion:
          data.textVersion.present ? data.textVersion.value : this.textVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttemptRecord(')
          ..write('id: $id, ')
          ..write('unitId: $unitId, ')
          ..write('sessionId: $sessionId, ')
          ..write('mode: $mode, ')
          ..write('outcome: $outcome, ')
          ..write('hints: $hints, ')
          ..write('errorEventIds: $errorEventIds, ')
          ..write('rating: $rating, ')
          ..write('method: $method, ')
          ..write('durationMs: $durationMs, ')
          ..write('words: $words, ')
          ..write('modelId: $modelId, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('rulesVersion: $rulesVersion, ')
          ..write('textVersion: $textVersion, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      unitId,
      sessionId,
      mode,
      outcome,
      hints,
      errorEventIds,
      rating,
      method,
      durationMs,
      words,
      modelId,
      modelVersion,
      rulesVersion,
      textVersion,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttemptRecord &&
          other.id == this.id &&
          other.unitId == this.unitId &&
          other.sessionId == this.sessionId &&
          other.mode == this.mode &&
          other.outcome == this.outcome &&
          other.hints == this.hints &&
          other.errorEventIds == this.errorEventIds &&
          other.rating == this.rating &&
          other.method == this.method &&
          other.durationMs == this.durationMs &&
          other.words == this.words &&
          other.modelId == this.modelId &&
          other.modelVersion == this.modelVersion &&
          other.rulesVersion == this.rulesVersion &&
          other.textVersion == this.textVersion &&
          other.createdAt == this.createdAt);
}

class AttemptsCompanion extends UpdateCompanion<AttemptRecord> {
  final Value<String> id;
  final Value<String> unitId;
  final Value<String> sessionId;
  final Value<StoredReadingMode> mode;
  final Value<AttemptOutcome> outcome;
  final Value<HintCounts> hints;
  final Value<ErrorEventIds> errorEventIds;
  final Value<AttemptRating?> rating;
  final Value<CheckMethod> method;
  final Value<int> durationMs;
  final Value<int> words;
  final Value<String> modelId;
  final Value<String> modelVersion;
  final Value<String> rulesVersion;
  final Value<String> textVersion;
  final Value<int> createdAt;
  final Value<int> rowid;
  const AttemptsCompanion({
    this.id = const Value.absent(),
    this.unitId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.mode = const Value.absent(),
    this.outcome = const Value.absent(),
    this.hints = const Value.absent(),
    this.errorEventIds = const Value.absent(),
    this.rating = const Value.absent(),
    this.method = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.words = const Value.absent(),
    this.modelId = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.rulesVersion = const Value.absent(),
    this.textVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttemptsCompanion.insert({
    required String id,
    required String unitId,
    required String sessionId,
    required StoredReadingMode mode,
    required AttemptOutcome outcome,
    required HintCounts hints,
    required ErrorEventIds errorEventIds,
    this.rating = const Value.absent(),
    required CheckMethod method,
    required int durationMs,
    required int words,
    required String modelId,
    required String modelVersion,
    required String rulesVersion,
    required String textVersion,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        unitId = Value(unitId),
        sessionId = Value(sessionId),
        mode = Value(mode),
        outcome = Value(outcome),
        hints = Value(hints),
        errorEventIds = Value(errorEventIds),
        method = Value(method),
        durationMs = Value(durationMs),
        words = Value(words),
        modelId = Value(modelId),
        modelVersion = Value(modelVersion),
        rulesVersion = Value(rulesVersion),
        textVersion = Value(textVersion),
        createdAt = Value(createdAt);
  static Insertable<AttemptRecord> custom({
    Expression<String>? id,
    Expression<String>? unitId,
    Expression<String>? sessionId,
    Expression<String>? mode,
    Expression<String>? outcome,
    Expression<String>? hints,
    Expression<String>? errorEventIds,
    Expression<String>? rating,
    Expression<String>? method,
    Expression<int>? durationMs,
    Expression<int>? words,
    Expression<String>? modelId,
    Expression<String>? modelVersion,
    Expression<String>? rulesVersion,
    Expression<String>? textVersion,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (unitId != null) 'unit_id': unitId,
      if (sessionId != null) 'session_id': sessionId,
      if (mode != null) 'mode': mode,
      if (outcome != null) 'outcome': outcome,
      if (hints != null) 'hints': hints,
      if (errorEventIds != null) 'error_event_ids': errorEventIds,
      if (rating != null) 'rating': rating,
      if (method != null) 'method': method,
      if (durationMs != null) 'duration_ms': durationMs,
      if (words != null) 'words': words,
      if (modelId != null) 'model_id': modelId,
      if (modelVersion != null) 'model_version': modelVersion,
      if (rulesVersion != null) 'rules_version': rulesVersion,
      if (textVersion != null) 'text_version': textVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttemptsCompanion copyWith(
      {Value<String>? id,
      Value<String>? unitId,
      Value<String>? sessionId,
      Value<StoredReadingMode>? mode,
      Value<AttemptOutcome>? outcome,
      Value<HintCounts>? hints,
      Value<ErrorEventIds>? errorEventIds,
      Value<AttemptRating?>? rating,
      Value<CheckMethod>? method,
      Value<int>? durationMs,
      Value<int>? words,
      Value<String>? modelId,
      Value<String>? modelVersion,
      Value<String>? rulesVersion,
      Value<String>? textVersion,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return AttemptsCompanion(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      sessionId: sessionId ?? this.sessionId,
      mode: mode ?? this.mode,
      outcome: outcome ?? this.outcome,
      hints: hints ?? this.hints,
      errorEventIds: errorEventIds ?? this.errorEventIds,
      rating: rating ?? this.rating,
      method: method ?? this.method,
      durationMs: durationMs ?? this.durationMs,
      words: words ?? this.words,
      modelId: modelId ?? this.modelId,
      modelVersion: modelVersion ?? this.modelVersion,
      rulesVersion: rulesVersion ?? this.rulesVersion,
      textVersion: textVersion ?? this.textVersion,
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
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (mode.present) {
      map['mode'] =
          Variable<String>($AttemptsTable.$convertermode.toSql(mode.value));
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(
          $AttemptsTable.$converteroutcome.toSql(outcome.value));
    }
    if (hints.present) {
      map['hints'] =
          Variable<String>($AttemptsTable.$converterhints.toSql(hints.value));
    }
    if (errorEventIds.present) {
      map['error_event_ids'] = Variable<String>(
          $AttemptsTable.$convertererrorEventIds.toSql(errorEventIds.value));
    }
    if (rating.present) {
      map['rating'] = Variable<String>(
          $AttemptsTable.$converterratingn.toSql(rating.value));
    }
    if (method.present) {
      map['method'] =
          Variable<String>($AttemptsTable.$convertermethod.toSql(method.value));
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (words.present) {
      map['words'] = Variable<int>(words.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (rulesVersion.present) {
      map['rules_version'] = Variable<String>(rulesVersion.value);
    }
    if (textVersion.present) {
      map['text_version'] = Variable<String>(textVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttemptsCompanion(')
          ..write('id: $id, ')
          ..write('unitId: $unitId, ')
          ..write('sessionId: $sessionId, ')
          ..write('mode: $mode, ')
          ..write('outcome: $outcome, ')
          ..write('hints: $hints, ')
          ..write('errorEventIds: $errorEventIds, ')
          ..write('rating: $rating, ')
          ..write('method: $method, ')
          ..write('durationMs: $durationMs, ')
          ..write('words: $words, ')
          ..write('modelId: $modelId, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('rulesVersion: $rulesVersion, ')
          ..write('textVersion: $textVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CheckEventsTable extends CheckEvents
    with TableInfo<$CheckEventsTable, CheckEventRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<CheckKind, String> kind =
      GeneratedColumn<String>('kind', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<CheckKind>($CheckEventsTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<CheckState, String> state =
      GeneratedColumn<String>('state', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<CheckState>($CheckEventsTable.$converterstate);
  @override
  late final GeneratedColumnWithTypeConverter<WordIndexes, String> wordIndexes =
      GeneratedColumn<String>('word_indexes', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<WordIndexes>($CheckEventsTable.$converterwordIndexes);
  static const VerificationMeta _expectedTextMeta =
      const VerificationMeta('expectedText');
  @override
  late final GeneratedColumn<String> expectedText = GeneratedColumn<String>(
      'expected_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _heardTextMeta =
      const VerificationMeta('heardText');
  @override
  late final GeneratedColumn<String> heardText = GeneratedColumn<String>(
      'heard_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jumpFromWordIndexMeta =
      const VerificationMeta('jumpFromWordIndex');
  @override
  late final GeneratedColumn<int> jumpFromWordIndex = GeneratedColumn<int>(
      'jump_from_word_index', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _jumpToWordIndexMeta =
      const VerificationMeta('jumpToWordIndex');
  @override
  late final GeneratedColumn<int> jumpToWordIndex = GeneratedColumn<int>(
      'jump_to_word_index', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _audioStartMsMeta =
      const VerificationMeta('audioStartMs');
  @override
  late final GeneratedColumn<int> audioStartMs = GeneratedColumn<int>(
      'audio_start_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _audioEndMsMeta =
      const VerificationMeta('audioEndMs');
  @override
  late final GeneratedColumn<int> audioEndMs = GeneratedColumn<int>(
      'audio_end_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<ReadingVersions, String>
      versions = GeneratedColumn<String>('versions', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<ReadingVersions>($CheckEventsTable.$converterversions);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sessionId,
        kind,
        state,
        wordIndexes,
        expectedText,
        heardText,
        jumpFromWordIndex,
        jumpToWordIndex,
        audioStartMs,
        audioEndMs,
        versions,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'check_event';
  @override
  VerificationContext validateIntegrity(Insertable<CheckEventRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('expected_text')) {
      context.handle(
          _expectedTextMeta,
          expectedText.isAcceptableOrUnknown(
              data['expected_text']!, _expectedTextMeta));
    } else if (isInserting) {
      context.missing(_expectedTextMeta);
    }
    if (data.containsKey('heard_text')) {
      context.handle(_heardTextMeta,
          heardText.isAcceptableOrUnknown(data['heard_text']!, _heardTextMeta));
    } else if (isInserting) {
      context.missing(_heardTextMeta);
    }
    if (data.containsKey('jump_from_word_index')) {
      context.handle(
          _jumpFromWordIndexMeta,
          jumpFromWordIndex.isAcceptableOrUnknown(
              data['jump_from_word_index']!, _jumpFromWordIndexMeta));
    }
    if (data.containsKey('jump_to_word_index')) {
      context.handle(
          _jumpToWordIndexMeta,
          jumpToWordIndex.isAcceptableOrUnknown(
              data['jump_to_word_index']!, _jumpToWordIndexMeta));
    }
    if (data.containsKey('audio_start_ms')) {
      context.handle(
          _audioStartMsMeta,
          audioStartMs.isAcceptableOrUnknown(
              data['audio_start_ms']!, _audioStartMsMeta));
    } else if (isInserting) {
      context.missing(_audioStartMsMeta);
    }
    if (data.containsKey('audio_end_ms')) {
      context.handle(
          _audioEndMsMeta,
          audioEndMs.isAcceptableOrUnknown(
              data['audio_end_ms']!, _audioEndMsMeta));
    } else if (isInserting) {
      context.missing(_audioEndMsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CheckEventRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckEventRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      kind: $CheckEventsTable.$converterkind.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
      state: $CheckEventsTable.$converterstate.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!),
      wordIndexes: $CheckEventsTable.$converterwordIndexes.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}word_indexes'])!),
      expectedText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expected_text'])!,
      heardText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}heard_text'])!,
      jumpFromWordIndex: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}jump_from_word_index']),
      jumpToWordIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}jump_to_word_index']),
      audioStartMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}audio_start_ms'])!,
      audioEndMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}audio_end_ms'])!,
      versions: $CheckEventsTable.$converterversions.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}versions'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CheckEventsTable createAlias(String alias) {
    return $CheckEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CheckKind, String, String> $converterkind =
      const EnumNameConverter<CheckKind>(CheckKind.values);
  static JsonTypeConverter2<CheckState, String, String> $converterstate =
      const EnumNameConverter<CheckState>(CheckState.values);
  static TypeConverter<WordIndexes, String> $converterwordIndexes =
      const WordIndexesConverter();
  static TypeConverter<ReadingVersions, String> $converterversions =
      const ReadingVersionsConverter();
}

class CheckEventRecord extends DataClass
    implements Insertable<CheckEventRecord> {
  final String id;
  final String sessionId;
  final CheckKind kind;
  final CheckState state;
  final WordIndexes wordIndexes;
  final String expectedText;
  final String heardText;
  final int? jumpFromWordIndex;
  final int? jumpToWordIndex;
  final int audioStartMs;
  final int audioEndMs;
  final ReadingVersions versions;
  final int createdAt;
  final int updatedAt;
  const CheckEventRecord(
      {required this.id,
      required this.sessionId,
      required this.kind,
      required this.state,
      required this.wordIndexes,
      required this.expectedText,
      required this.heardText,
      this.jumpFromWordIndex,
      this.jumpToWordIndex,
      required this.audioStartMs,
      required this.audioEndMs,
      required this.versions,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    {
      map['kind'] =
          Variable<String>($CheckEventsTable.$converterkind.toSql(kind));
    }
    {
      map['state'] =
          Variable<String>($CheckEventsTable.$converterstate.toSql(state));
    }
    {
      map['word_indexes'] = Variable<String>(
          $CheckEventsTable.$converterwordIndexes.toSql(wordIndexes));
    }
    map['expected_text'] = Variable<String>(expectedText);
    map['heard_text'] = Variable<String>(heardText);
    if (!nullToAbsent || jumpFromWordIndex != null) {
      map['jump_from_word_index'] = Variable<int>(jumpFromWordIndex);
    }
    if (!nullToAbsent || jumpToWordIndex != null) {
      map['jump_to_word_index'] = Variable<int>(jumpToWordIndex);
    }
    map['audio_start_ms'] = Variable<int>(audioStartMs);
    map['audio_end_ms'] = Variable<int>(audioEndMs);
    {
      map['versions'] = Variable<String>(
          $CheckEventsTable.$converterversions.toSql(versions));
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CheckEventsCompanion toCompanion(bool nullToAbsent) {
    return CheckEventsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      kind: Value(kind),
      state: Value(state),
      wordIndexes: Value(wordIndexes),
      expectedText: Value(expectedText),
      heardText: Value(heardText),
      jumpFromWordIndex: jumpFromWordIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(jumpFromWordIndex),
      jumpToWordIndex: jumpToWordIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(jumpToWordIndex),
      audioStartMs: Value(audioStartMs),
      audioEndMs: Value(audioEndMs),
      versions: Value(versions),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CheckEventRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckEventRecord(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      kind: $CheckEventsTable.$converterkind
          .fromJson(serializer.fromJson<String>(json['kind'])),
      state: $CheckEventsTable.$converterstate
          .fromJson(serializer.fromJson<String>(json['state'])),
      wordIndexes: serializer.fromJson<WordIndexes>(json['wordIndexes']),
      expectedText: serializer.fromJson<String>(json['expectedText']),
      heardText: serializer.fromJson<String>(json['heardText']),
      jumpFromWordIndex: serializer.fromJson<int?>(json['jumpFromWordIndex']),
      jumpToWordIndex: serializer.fromJson<int?>(json['jumpToWordIndex']),
      audioStartMs: serializer.fromJson<int>(json['audioStartMs']),
      audioEndMs: serializer.fromJson<int>(json['audioEndMs']),
      versions: serializer.fromJson<ReadingVersions>(json['versions']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'kind': serializer
          .toJson<String>($CheckEventsTable.$converterkind.toJson(kind)),
      'state': serializer
          .toJson<String>($CheckEventsTable.$converterstate.toJson(state)),
      'wordIndexes': serializer.toJson<WordIndexes>(wordIndexes),
      'expectedText': serializer.toJson<String>(expectedText),
      'heardText': serializer.toJson<String>(heardText),
      'jumpFromWordIndex': serializer.toJson<int?>(jumpFromWordIndex),
      'jumpToWordIndex': serializer.toJson<int?>(jumpToWordIndex),
      'audioStartMs': serializer.toJson<int>(audioStartMs),
      'audioEndMs': serializer.toJson<int>(audioEndMs),
      'versions': serializer.toJson<ReadingVersions>(versions),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CheckEventRecord copyWith(
          {String? id,
          String? sessionId,
          CheckKind? kind,
          CheckState? state,
          WordIndexes? wordIndexes,
          String? expectedText,
          String? heardText,
          Value<int?> jumpFromWordIndex = const Value.absent(),
          Value<int?> jumpToWordIndex = const Value.absent(),
          int? audioStartMs,
          int? audioEndMs,
          ReadingVersions? versions,
          int? createdAt,
          int? updatedAt}) =>
      CheckEventRecord(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        kind: kind ?? this.kind,
        state: state ?? this.state,
        wordIndexes: wordIndexes ?? this.wordIndexes,
        expectedText: expectedText ?? this.expectedText,
        heardText: heardText ?? this.heardText,
        jumpFromWordIndex: jumpFromWordIndex.present
            ? jumpFromWordIndex.value
            : this.jumpFromWordIndex,
        jumpToWordIndex: jumpToWordIndex.present
            ? jumpToWordIndex.value
            : this.jumpToWordIndex,
        audioStartMs: audioStartMs ?? this.audioStartMs,
        audioEndMs: audioEndMs ?? this.audioEndMs,
        versions: versions ?? this.versions,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CheckEventRecord copyWithCompanion(CheckEventsCompanion data) {
    return CheckEventRecord(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      kind: data.kind.present ? data.kind.value : this.kind,
      state: data.state.present ? data.state.value : this.state,
      wordIndexes:
          data.wordIndexes.present ? data.wordIndexes.value : this.wordIndexes,
      expectedText: data.expectedText.present
          ? data.expectedText.value
          : this.expectedText,
      heardText: data.heardText.present ? data.heardText.value : this.heardText,
      jumpFromWordIndex: data.jumpFromWordIndex.present
          ? data.jumpFromWordIndex.value
          : this.jumpFromWordIndex,
      jumpToWordIndex: data.jumpToWordIndex.present
          ? data.jumpToWordIndex.value
          : this.jumpToWordIndex,
      audioStartMs: data.audioStartMs.present
          ? data.audioStartMs.value
          : this.audioStartMs,
      audioEndMs:
          data.audioEndMs.present ? data.audioEndMs.value : this.audioEndMs,
      versions: data.versions.present ? data.versions.value : this.versions,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckEventRecord(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('kind: $kind, ')
          ..write('state: $state, ')
          ..write('wordIndexes: $wordIndexes, ')
          ..write('expectedText: $expectedText, ')
          ..write('heardText: $heardText, ')
          ..write('jumpFromWordIndex: $jumpFromWordIndex, ')
          ..write('jumpToWordIndex: $jumpToWordIndex, ')
          ..write('audioStartMs: $audioStartMs, ')
          ..write('audioEndMs: $audioEndMs, ')
          ..write('versions: $versions, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      sessionId,
      kind,
      state,
      wordIndexes,
      expectedText,
      heardText,
      jumpFromWordIndex,
      jumpToWordIndex,
      audioStartMs,
      audioEndMs,
      versions,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckEventRecord &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.kind == this.kind &&
          other.state == this.state &&
          other.wordIndexes == this.wordIndexes &&
          other.expectedText == this.expectedText &&
          other.heardText == this.heardText &&
          other.jumpFromWordIndex == this.jumpFromWordIndex &&
          other.jumpToWordIndex == this.jumpToWordIndex &&
          other.audioStartMs == this.audioStartMs &&
          other.audioEndMs == this.audioEndMs &&
          other.versions == this.versions &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CheckEventsCompanion extends UpdateCompanion<CheckEventRecord> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<CheckKind> kind;
  final Value<CheckState> state;
  final Value<WordIndexes> wordIndexes;
  final Value<String> expectedText;
  final Value<String> heardText;
  final Value<int?> jumpFromWordIndex;
  final Value<int?> jumpToWordIndex;
  final Value<int> audioStartMs;
  final Value<int> audioEndMs;
  final Value<ReadingVersions> versions;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CheckEventsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.kind = const Value.absent(),
    this.state = const Value.absent(),
    this.wordIndexes = const Value.absent(),
    this.expectedText = const Value.absent(),
    this.heardText = const Value.absent(),
    this.jumpFromWordIndex = const Value.absent(),
    this.jumpToWordIndex = const Value.absent(),
    this.audioStartMs = const Value.absent(),
    this.audioEndMs = const Value.absent(),
    this.versions = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheckEventsCompanion.insert({
    required String id,
    required String sessionId,
    required CheckKind kind,
    required CheckState state,
    required WordIndexes wordIndexes,
    required String expectedText,
    required String heardText,
    this.jumpFromWordIndex = const Value.absent(),
    this.jumpToWordIndex = const Value.absent(),
    required int audioStartMs,
    required int audioEndMs,
    required ReadingVersions versions,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sessionId = Value(sessionId),
        kind = Value(kind),
        state = Value(state),
        wordIndexes = Value(wordIndexes),
        expectedText = Value(expectedText),
        heardText = Value(heardText),
        audioStartMs = Value(audioStartMs),
        audioEndMs = Value(audioEndMs),
        versions = Value(versions),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CheckEventRecord> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? kind,
    Expression<String>? state,
    Expression<String>? wordIndexes,
    Expression<String>? expectedText,
    Expression<String>? heardText,
    Expression<int>? jumpFromWordIndex,
    Expression<int>? jumpToWordIndex,
    Expression<int>? audioStartMs,
    Expression<int>? audioEndMs,
    Expression<String>? versions,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (kind != null) 'kind': kind,
      if (state != null) 'state': state,
      if (wordIndexes != null) 'word_indexes': wordIndexes,
      if (expectedText != null) 'expected_text': expectedText,
      if (heardText != null) 'heard_text': heardText,
      if (jumpFromWordIndex != null) 'jump_from_word_index': jumpFromWordIndex,
      if (jumpToWordIndex != null) 'jump_to_word_index': jumpToWordIndex,
      if (audioStartMs != null) 'audio_start_ms': audioStartMs,
      if (audioEndMs != null) 'audio_end_ms': audioEndMs,
      if (versions != null) 'versions': versions,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheckEventsCompanion copyWith(
      {Value<String>? id,
      Value<String>? sessionId,
      Value<CheckKind>? kind,
      Value<CheckState>? state,
      Value<WordIndexes>? wordIndexes,
      Value<String>? expectedText,
      Value<String>? heardText,
      Value<int?>? jumpFromWordIndex,
      Value<int?>? jumpToWordIndex,
      Value<int>? audioStartMs,
      Value<int>? audioEndMs,
      Value<ReadingVersions>? versions,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return CheckEventsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      kind: kind ?? this.kind,
      state: state ?? this.state,
      wordIndexes: wordIndexes ?? this.wordIndexes,
      expectedText: expectedText ?? this.expectedText,
      heardText: heardText ?? this.heardText,
      jumpFromWordIndex: jumpFromWordIndex ?? this.jumpFromWordIndex,
      jumpToWordIndex: jumpToWordIndex ?? this.jumpToWordIndex,
      audioStartMs: audioStartMs ?? this.audioStartMs,
      audioEndMs: audioEndMs ?? this.audioEndMs,
      versions: versions ?? this.versions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (kind.present) {
      map['kind'] =
          Variable<String>($CheckEventsTable.$converterkind.toSql(kind.value));
    }
    if (state.present) {
      map['state'] = Variable<String>(
          $CheckEventsTable.$converterstate.toSql(state.value));
    }
    if (wordIndexes.present) {
      map['word_indexes'] = Variable<String>(
          $CheckEventsTable.$converterwordIndexes.toSql(wordIndexes.value));
    }
    if (expectedText.present) {
      map['expected_text'] = Variable<String>(expectedText.value);
    }
    if (heardText.present) {
      map['heard_text'] = Variable<String>(heardText.value);
    }
    if (jumpFromWordIndex.present) {
      map['jump_from_word_index'] = Variable<int>(jumpFromWordIndex.value);
    }
    if (jumpToWordIndex.present) {
      map['jump_to_word_index'] = Variable<int>(jumpToWordIndex.value);
    }
    if (audioStartMs.present) {
      map['audio_start_ms'] = Variable<int>(audioStartMs.value);
    }
    if (audioEndMs.present) {
      map['audio_end_ms'] = Variable<int>(audioEndMs.value);
    }
    if (versions.present) {
      map['versions'] = Variable<String>(
          $CheckEventsTable.$converterversions.toSql(versions.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckEventsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('kind: $kind, ')
          ..write('state: $state, ')
          ..write('wordIndexes: $wordIndexes, ')
          ..write('expectedText: $expectedText, ')
          ..write('heardText: $heardText, ')
          ..write('jumpFromWordIndex: $jumpFromWordIndex, ')
          ..write('jumpToWordIndex: $jumpToWordIndex, ')
          ..write('audioStartMs: $audioStartMs, ')
          ..write('audioEndMs: $audioEndMs, ')
          ..write('versions: $versions, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profile_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _fromWordIndexMeta =
      const VerificationMeta('fromWordIndex');
  @override
  late final GeneratedColumn<int> fromWordIndex = GeneratedColumn<int>(
      'from_word_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _toWordIndexMeta =
      const VerificationMeta('toWordIndex');
  @override
  late final GeneratedColumn<int> toWordIndex = GeneratedColumn<int>(
      'to_word_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<StoredReadingMode, String> mode =
      GeneratedColumn<String>('mode', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<StoredReadingMode>($SessionsTable.$convertermode);
  @override
  late final GeneratedColumnWithTypeConverter<ReadingBehavior, String>
      behavior = GeneratedColumn<String>('behavior', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<ReadingBehavior>($SessionsTable.$converterbehavior);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
      'started_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
      'ended_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _listeningMsMeta =
      const VerificationMeta('listeningMs');
  @override
  late final GeneratedColumn<int> listeningMs = GeneratedColumn<int>(
      'listening_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _signalOkRatioMeta =
      const VerificationMeta('signalOkRatio');
  @override
  late final GeneratedColumn<double> signalOkRatio = GeneratedColumn<double>(
      'signal_ok_ratio', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<SessionSummary?, String> summary =
      GeneratedColumn<String>('summary', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<SessionSummary?>($SessionsTable.$convertersummaryn);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileId,
        fromWordIndex,
        toWordIndex,
        mode,
        behavior,
        startedAt,
        endedAt,
        listeningMs,
        signalOkRatio,
        summary
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session';
  @override
  VerificationContext validateIntegrity(Insertable<SessionRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('from_word_index')) {
      context.handle(
          _fromWordIndexMeta,
          fromWordIndex.isAcceptableOrUnknown(
              data['from_word_index']!, _fromWordIndexMeta));
    } else if (isInserting) {
      context.missing(_fromWordIndexMeta);
    }
    if (data.containsKey('to_word_index')) {
      context.handle(
          _toWordIndexMeta,
          toWordIndex.isAcceptableOrUnknown(
              data['to_word_index']!, _toWordIndexMeta));
    } else if (isInserting) {
      context.missing(_toWordIndexMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('listening_ms')) {
      context.handle(
          _listeningMsMeta,
          listeningMs.isAcceptableOrUnknown(
              data['listening_ms']!, _listeningMsMeta));
    } else if (isInserting) {
      context.missing(_listeningMsMeta);
    }
    if (data.containsKey('signal_ok_ratio')) {
      context.handle(
          _signalOkRatioMeta,
          signalOkRatio.isAcceptableOrUnknown(
              data['signal_ok_ratio']!, _signalOkRatioMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id'])!,
      fromWordIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}from_word_index'])!,
      toWordIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}to_word_index'])!,
      mode: $SessionsTable.$convertermode.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!),
      behavior: $SessionsTable.$converterbehavior.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}behavior'])!),
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ended_at']),
      listeningMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}listening_ms'])!,
      signalOkRatio: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}signal_ok_ratio']),
      summary: $SessionsTable.$convertersummaryn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary'])),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<StoredReadingMode, String, String> $convertermode =
      const EnumNameConverter<StoredReadingMode>(StoredReadingMode.values);
  static JsonTypeConverter2<ReadingBehavior, String, String>
      $converterbehavior =
      const EnumNameConverter<ReadingBehavior>(ReadingBehavior.values);
  static TypeConverter<SessionSummary, String> $convertersummary =
      const SessionSummaryConverter();
  static TypeConverter<SessionSummary?, String?> $convertersummaryn =
      NullAwareTypeConverter.wrap($convertersummary);
}

class SessionRecord extends DataClass implements Insertable<SessionRecord> {
  final String id;
  final String profileId;
  final int fromWordIndex;
  final int toWordIndex;
  final StoredReadingMode mode;
  final ReadingBehavior behavior;
  final int startedAt;
  final int? endedAt;
  final int listeningMs;
  final double? signalOkRatio;
  final SessionSummary? summary;
  const SessionRecord(
      {required this.id,
      required this.profileId,
      required this.fromWordIndex,
      required this.toWordIndex,
      required this.mode,
      required this.behavior,
      required this.startedAt,
      this.endedAt,
      required this.listeningMs,
      this.signalOkRatio,
      this.summary});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['from_word_index'] = Variable<int>(fromWordIndex);
    map['to_word_index'] = Variable<int>(toWordIndex);
    {
      map['mode'] = Variable<String>($SessionsTable.$convertermode.toSql(mode));
    }
    {
      map['behavior'] =
          Variable<String>($SessionsTable.$converterbehavior.toSql(behavior));
    }
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<int>(endedAt);
    }
    map['listening_ms'] = Variable<int>(listeningMs);
    if (!nullToAbsent || signalOkRatio != null) {
      map['signal_ok_ratio'] = Variable<double>(signalOkRatio);
    }
    if (!nullToAbsent || summary != null) {
      map['summary'] =
          Variable<String>($SessionsTable.$convertersummaryn.toSql(summary));
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      fromWordIndex: Value(fromWordIndex),
      toWordIndex: Value(toWordIndex),
      mode: Value(mode),
      behavior: Value(behavior),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      listeningMs: Value(listeningMs),
      signalOkRatio: signalOkRatio == null && nullToAbsent
          ? const Value.absent()
          : Value(signalOkRatio),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
    );
  }

  factory SessionRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRecord(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      fromWordIndex: serializer.fromJson<int>(json['fromWordIndex']),
      toWordIndex: serializer.fromJson<int>(json['toWordIndex']),
      mode: $SessionsTable.$convertermode
          .fromJson(serializer.fromJson<String>(json['mode'])),
      behavior: $SessionsTable.$converterbehavior
          .fromJson(serializer.fromJson<String>(json['behavior'])),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int?>(json['endedAt']),
      listeningMs: serializer.fromJson<int>(json['listeningMs']),
      signalOkRatio: serializer.fromJson<double?>(json['signalOkRatio']),
      summary: serializer.fromJson<SessionSummary?>(json['summary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'fromWordIndex': serializer.toJson<int>(fromWordIndex),
      'toWordIndex': serializer.toJson<int>(toWordIndex),
      'mode':
          serializer.toJson<String>($SessionsTable.$convertermode.toJson(mode)),
      'behavior': serializer
          .toJson<String>($SessionsTable.$converterbehavior.toJson(behavior)),
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int?>(endedAt),
      'listeningMs': serializer.toJson<int>(listeningMs),
      'signalOkRatio': serializer.toJson<double?>(signalOkRatio),
      'summary': serializer.toJson<SessionSummary?>(summary),
    };
  }

  SessionRecord copyWith(
          {String? id,
          String? profileId,
          int? fromWordIndex,
          int? toWordIndex,
          StoredReadingMode? mode,
          ReadingBehavior? behavior,
          int? startedAt,
          Value<int?> endedAt = const Value.absent(),
          int? listeningMs,
          Value<double?> signalOkRatio = const Value.absent(),
          Value<SessionSummary?> summary = const Value.absent()}) =>
      SessionRecord(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        fromWordIndex: fromWordIndex ?? this.fromWordIndex,
        toWordIndex: toWordIndex ?? this.toWordIndex,
        mode: mode ?? this.mode,
        behavior: behavior ?? this.behavior,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt.present ? endedAt.value : this.endedAt,
        listeningMs: listeningMs ?? this.listeningMs,
        signalOkRatio:
            signalOkRatio.present ? signalOkRatio.value : this.signalOkRatio,
        summary: summary.present ? summary.value : this.summary,
      );
  SessionRecord copyWithCompanion(SessionsCompanion data) {
    return SessionRecord(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      fromWordIndex: data.fromWordIndex.present
          ? data.fromWordIndex.value
          : this.fromWordIndex,
      toWordIndex:
          data.toWordIndex.present ? data.toWordIndex.value : this.toWordIndex,
      mode: data.mode.present ? data.mode.value : this.mode,
      behavior: data.behavior.present ? data.behavior.value : this.behavior,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      listeningMs:
          data.listeningMs.present ? data.listeningMs.value : this.listeningMs,
      signalOkRatio: data.signalOkRatio.present
          ? data.signalOkRatio.value
          : this.signalOkRatio,
      summary: data.summary.present ? data.summary.value : this.summary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRecord(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('fromWordIndex: $fromWordIndex, ')
          ..write('toWordIndex: $toWordIndex, ')
          ..write('mode: $mode, ')
          ..write('behavior: $behavior, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('listeningMs: $listeningMs, ')
          ..write('signalOkRatio: $signalOkRatio, ')
          ..write('summary: $summary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, profileId, fromWordIndex, toWordIndex,
      mode, behavior, startedAt, endedAt, listeningMs, signalOkRatio, summary);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRecord &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.fromWordIndex == this.fromWordIndex &&
          other.toWordIndex == this.toWordIndex &&
          other.mode == this.mode &&
          other.behavior == this.behavior &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.listeningMs == this.listeningMs &&
          other.signalOkRatio == this.signalOkRatio &&
          other.summary == this.summary);
}

class SessionsCompanion extends UpdateCompanion<SessionRecord> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<int> fromWordIndex;
  final Value<int> toWordIndex;
  final Value<StoredReadingMode> mode;
  final Value<ReadingBehavior> behavior;
  final Value<int> startedAt;
  final Value<int?> endedAt;
  final Value<int> listeningMs;
  final Value<double?> signalOkRatio;
  final Value<SessionSummary?> summary;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.fromWordIndex = const Value.absent(),
    this.toWordIndex = const Value.absent(),
    this.mode = const Value.absent(),
    this.behavior = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.listeningMs = const Value.absent(),
    this.signalOkRatio = const Value.absent(),
    this.summary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String profileId,
    required int fromWordIndex,
    required int toWordIndex,
    required StoredReadingMode mode,
    required ReadingBehavior behavior,
    required int startedAt,
    this.endedAt = const Value.absent(),
    required int listeningMs,
    this.signalOkRatio = const Value.absent(),
    this.summary = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        profileId = Value(profileId),
        fromWordIndex = Value(fromWordIndex),
        toWordIndex = Value(toWordIndex),
        mode = Value(mode),
        behavior = Value(behavior),
        startedAt = Value(startedAt),
        listeningMs = Value(listeningMs);
  static Insertable<SessionRecord> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<int>? fromWordIndex,
    Expression<int>? toWordIndex,
    Expression<String>? mode,
    Expression<String>? behavior,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<int>? listeningMs,
    Expression<double>? signalOkRatio,
    Expression<String>? summary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (fromWordIndex != null) 'from_word_index': fromWordIndex,
      if (toWordIndex != null) 'to_word_index': toWordIndex,
      if (mode != null) 'mode': mode,
      if (behavior != null) 'behavior': behavior,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (listeningMs != null) 'listening_ms': listeningMs,
      if (signalOkRatio != null) 'signal_ok_ratio': signalOkRatio,
      if (summary != null) 'summary': summary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? profileId,
      Value<int>? fromWordIndex,
      Value<int>? toWordIndex,
      Value<StoredReadingMode>? mode,
      Value<ReadingBehavior>? behavior,
      Value<int>? startedAt,
      Value<int?>? endedAt,
      Value<int>? listeningMs,
      Value<double?>? signalOkRatio,
      Value<SessionSummary?>? summary,
      Value<int>? rowid}) {
    return SessionsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      fromWordIndex: fromWordIndex ?? this.fromWordIndex,
      toWordIndex: toWordIndex ?? this.toWordIndex,
      mode: mode ?? this.mode,
      behavior: behavior ?? this.behavior,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      listeningMs: listeningMs ?? this.listeningMs,
      signalOkRatio: signalOkRatio ?? this.signalOkRatio,
      summary: summary ?? this.summary,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (fromWordIndex.present) {
      map['from_word_index'] = Variable<int>(fromWordIndex.value);
    }
    if (toWordIndex.present) {
      map['to_word_index'] = Variable<int>(toWordIndex.value);
    }
    if (mode.present) {
      map['mode'] =
          Variable<String>($SessionsTable.$convertermode.toSql(mode.value));
    }
    if (behavior.present) {
      map['behavior'] = Variable<String>(
          $SessionsTable.$converterbehavior.toSql(behavior.value));
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (listeningMs.present) {
      map['listening_ms'] = Variable<int>(listeningMs.value);
    }
    if (signalOkRatio.present) {
      map['signal_ok_ratio'] = Variable<double>(signalOkRatio.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(
          $SessionsTable.$convertersummaryn.toSql(summary.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('fromWordIndex: $fromWordIndex, ')
          ..write('toWordIndex: $toWordIndex, ')
          ..write('mode: $mode, ')
          ..write('behavior: $behavior, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('listeningMs: $listeningMs, ')
          ..write('signalOkRatio: $signalOkRatio, ')
          ..write('summary: $summary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyPlansTable extends DailyPlans
    with TableInfo<$DailyPlansTable, DailyPlanRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 10, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DailyPlanItems, String> items =
      GeneratedColumn<String>('items', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<DailyPlanItems>($DailyPlansTable.$converteritems);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [date, items, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_plan';
  @override
  VerificationContext validateIntegrity(Insertable<DailyPlanRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyPlanRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyPlanRecord(
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      items: $DailyPlansTable.$converteritems.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}items'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DailyPlansTable createAlias(String alias) {
    return $DailyPlansTable(attachedDatabase, alias);
  }

  static TypeConverter<DailyPlanItems, String> $converteritems =
      const DailyPlanItemsConverter();
}

class DailyPlanRecord extends DataClass implements Insertable<DailyPlanRecord> {
  final String date;
  final DailyPlanItems items;
  final int createdAt;
  const DailyPlanRecord(
      {required this.date, required this.items, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    {
      map['items'] =
          Variable<String>($DailyPlansTable.$converteritems.toSql(items));
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  DailyPlansCompanion toCompanion(bool nullToAbsent) {
    return DailyPlansCompanion(
      date: Value(date),
      items: Value(items),
      createdAt: Value(createdAt),
    );
  }

  factory DailyPlanRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyPlanRecord(
      date: serializer.fromJson<String>(json['date']),
      items: serializer.fromJson<DailyPlanItems>(json['items']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'items': serializer.toJson<DailyPlanItems>(items),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  DailyPlanRecord copyWith(
          {String? date, DailyPlanItems? items, int? createdAt}) =>
      DailyPlanRecord(
        date: date ?? this.date,
        items: items ?? this.items,
        createdAt: createdAt ?? this.createdAt,
      );
  DailyPlanRecord copyWithCompanion(DailyPlansCompanion data) {
    return DailyPlanRecord(
      date: data.date.present ? data.date.value : this.date,
      items: data.items.present ? data.items.value : this.items,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyPlanRecord(')
          ..write('date: $date, ')
          ..write('items: $items, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, items, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyPlanRecord &&
          other.date == this.date &&
          other.items == this.items &&
          other.createdAt == this.createdAt);
}

class DailyPlansCompanion extends UpdateCompanion<DailyPlanRecord> {
  final Value<String> date;
  final Value<DailyPlanItems> items;
  final Value<int> createdAt;
  final Value<int> rowid;
  const DailyPlansCompanion({
    this.date = const Value.absent(),
    this.items = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyPlansCompanion.insert({
    required String date,
    required DailyPlanItems items,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : date = Value(date),
        items = Value(items),
        createdAt = Value(createdAt);
  static Insertable<DailyPlanRecord> custom({
    Expression<String>? date,
    Expression<String>? items,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (items != null) 'items': items,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyPlansCompanion copyWith(
      {Value<String>? date,
      Value<DailyPlanItems>? items,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return DailyPlansCompanion(
      date: date ?? this.date,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (items.present) {
      map['items'] =
          Variable<String>($DailyPlansTable.$converteritems.toSql(items.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyPlansCompanion(')
          ..write('date: $date, ')
          ..write('items: $items, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonProgressEntriesTable extends LessonProgressEntries
    with TableInfo<$LessonProgressEntriesTable, LessonProgressRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonProgressEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta =
      const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
      'lesson_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<LessonState, String> state =
      GeneratedColumn<String>('state', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<LessonState>(
              $LessonProgressEntriesTable.$converterstate);
  static const VerificationMeta _stepIndexMeta =
      const VerificationMeta('stepIndex');
  @override
  late final GeneratedColumn<int> stepIndex = GeneratedColumn<int>(
      'step_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _quizPercentMeta =
      const VerificationMeta('quizPercent');
  @override
  late final GeneratedColumn<int> quizPercent = GeneratedColumn<int>(
      'quiz_percent', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _contentVersionMeta =
      const VerificationMeta('contentVersion');
  @override
  late final GeneratedColumn<String> contentVersion = GeneratedColumn<String>(
      'content_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [lessonId, state, stepIndex, quizPercent, contentVersion, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_progress';
  @override
  VerificationContext validateIntegrity(
      Insertable<LessonProgressRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta,
          lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('step_index')) {
      context.handle(_stepIndexMeta,
          stepIndex.isAcceptableOrUnknown(data['step_index']!, _stepIndexMeta));
    } else if (isInserting) {
      context.missing(_stepIndexMeta);
    }
    if (data.containsKey('quiz_percent')) {
      context.handle(
          _quizPercentMeta,
          quizPercent.isAcceptableOrUnknown(
              data['quiz_percent']!, _quizPercentMeta));
    } else if (isInserting) {
      context.missing(_quizPercentMeta);
    }
    if (data.containsKey('content_version')) {
      context.handle(
          _contentVersionMeta,
          contentVersion.isAcceptableOrUnknown(
              data['content_version']!, _contentVersionMeta));
    } else if (isInserting) {
      context.missing(_contentVersionMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lessonId};
  @override
  LessonProgressRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonProgressRecord(
      lessonId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lesson_id'])!,
      state: $LessonProgressEntriesTable.$converterstate.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.string, data['${effectivePrefix}state'])!),
      stepIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}step_index'])!,
      quizPercent: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quiz_percent'])!,
      contentVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}content_version'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LessonProgressEntriesTable createAlias(String alias) {
    return $LessonProgressEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LessonState, String, String> $converterstate =
      const EnumNameConverter<LessonState>(LessonState.values);
}

class LessonProgressRecord extends DataClass
    implements Insertable<LessonProgressRecord> {
  final String lessonId;
  final LessonState state;
  final int stepIndex;
  final int quizPercent;
  final String contentVersion;
  final int updatedAt;
  const LessonProgressRecord(
      {required this.lessonId,
      required this.state,
      required this.stepIndex,
      required this.quizPercent,
      required this.contentVersion,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    {
      map['state'] = Variable<String>(
          $LessonProgressEntriesTable.$converterstate.toSql(state));
    }
    map['step_index'] = Variable<int>(stepIndex);
    map['quiz_percent'] = Variable<int>(quizPercent);
    map['content_version'] = Variable<String>(contentVersion);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  LessonProgressEntriesCompanion toCompanion(bool nullToAbsent) {
    return LessonProgressEntriesCompanion(
      lessonId: Value(lessonId),
      state: Value(state),
      stepIndex: Value(stepIndex),
      quizPercent: Value(quizPercent),
      contentVersion: Value(contentVersion),
      updatedAt: Value(updatedAt),
    );
  }

  factory LessonProgressRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonProgressRecord(
      lessonId: serializer.fromJson<String>(json['lessonId']),
      state: $LessonProgressEntriesTable.$converterstate
          .fromJson(serializer.fromJson<String>(json['state'])),
      stepIndex: serializer.fromJson<int>(json['stepIndex']),
      quizPercent: serializer.fromJson<int>(json['quizPercent']),
      contentVersion: serializer.fromJson<String>(json['contentVersion']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lessonId': serializer.toJson<String>(lessonId),
      'state': serializer.toJson<String>(
          $LessonProgressEntriesTable.$converterstate.toJson(state)),
      'stepIndex': serializer.toJson<int>(stepIndex),
      'quizPercent': serializer.toJson<int>(quizPercent),
      'contentVersion': serializer.toJson<String>(contentVersion),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  LessonProgressRecord copyWith(
          {String? lessonId,
          LessonState? state,
          int? stepIndex,
          int? quizPercent,
          String? contentVersion,
          int? updatedAt}) =>
      LessonProgressRecord(
        lessonId: lessonId ?? this.lessonId,
        state: state ?? this.state,
        stepIndex: stepIndex ?? this.stepIndex,
        quizPercent: quizPercent ?? this.quizPercent,
        contentVersion: contentVersion ?? this.contentVersion,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LessonProgressRecord copyWithCompanion(LessonProgressEntriesCompanion data) {
    return LessonProgressRecord(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      state: data.state.present ? data.state.value : this.state,
      stepIndex: data.stepIndex.present ? data.stepIndex.value : this.stepIndex,
      quizPercent:
          data.quizPercent.present ? data.quizPercent.value : this.quizPercent,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressRecord(')
          ..write('lessonId: $lessonId, ')
          ..write('state: $state, ')
          ..write('stepIndex: $stepIndex, ')
          ..write('quizPercent: $quizPercent, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      lessonId, state, stepIndex, quizPercent, contentVersion, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonProgressRecord &&
          other.lessonId == this.lessonId &&
          other.state == this.state &&
          other.stepIndex == this.stepIndex &&
          other.quizPercent == this.quizPercent &&
          other.contentVersion == this.contentVersion &&
          other.updatedAt == this.updatedAt);
}

class LessonProgressEntriesCompanion
    extends UpdateCompanion<LessonProgressRecord> {
  final Value<String> lessonId;
  final Value<LessonState> state;
  final Value<int> stepIndex;
  final Value<int> quizPercent;
  final Value<String> contentVersion;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const LessonProgressEntriesCompanion({
    this.lessonId = const Value.absent(),
    this.state = const Value.absent(),
    this.stepIndex = const Value.absent(),
    this.quizPercent = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonProgressEntriesCompanion.insert({
    required String lessonId,
    required LessonState state,
    required int stepIndex,
    required int quizPercent,
    required String contentVersion,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : lessonId = Value(lessonId),
        state = Value(state),
        stepIndex = Value(stepIndex),
        quizPercent = Value(quizPercent),
        contentVersion = Value(contentVersion),
        updatedAt = Value(updatedAt);
  static Insertable<LessonProgressRecord> custom({
    Expression<String>? lessonId,
    Expression<String>? state,
    Expression<int>? stepIndex,
    Expression<int>? quizPercent,
    Expression<String>? contentVersion,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (state != null) 'state': state,
      if (stepIndex != null) 'step_index': stepIndex,
      if (quizPercent != null) 'quiz_percent': quizPercent,
      if (contentVersion != null) 'content_version': contentVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonProgressEntriesCompanion copyWith(
      {Value<String>? lessonId,
      Value<LessonState>? state,
      Value<int>? stepIndex,
      Value<int>? quizPercent,
      Value<String>? contentVersion,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return LessonProgressEntriesCompanion(
      lessonId: lessonId ?? this.lessonId,
      state: state ?? this.state,
      stepIndex: stepIndex ?? this.stepIndex,
      quizPercent: quizPercent ?? this.quizPercent,
      contentVersion: contentVersion ?? this.contentVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
          $LessonProgressEntriesTable.$converterstate.toSql(state.value));
    }
    if (stepIndex.present) {
      map['step_index'] = Variable<int>(stepIndex.value);
    }
    if (quizPercent.present) {
      map['quiz_percent'] = Variable<int>(quizPercent.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<String>(contentVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressEntriesCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('state: $state, ')
          ..write('stepIndex: $stepIndex, ')
          ..write('quizPercent: $quizPercent, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<JsonValueData, String> value =
      GeneratedColumn<String>('value', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<JsonValueData>($SettingsTable.$convertervalue);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting';
  @override
  VerificationContext validateIntegrity(Insertable<SettingRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRecord(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: $SettingsTable.$convertervalue.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }

  static TypeConverter<JsonValueData, String> $convertervalue =
      const JsonValueConverter();
}

class SettingRecord extends DataClass implements Insertable<SettingRecord> {
  final String key;
  final JsonValueData value;
  const SettingRecord({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    {
      map['value'] =
          Variable<String>($SettingsTable.$convertervalue.toSql(value));
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRecord(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<JsonValueData>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<JsonValueData>(value),
    };
  }

  SettingRecord copyWith({String? key, JsonValueData? value}) => SettingRecord(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingRecord copyWithCompanion(SettingsCompanion data) {
    return SettingRecord(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRecord(')
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
      (other is SettingRecord &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRecord> {
  final Value<String> key;
  final Value<JsonValueData> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required JsonValueData value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SettingRecord> custom({
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

  SettingsCompanion copyWith(
      {Value<String>? key, Value<JsonValueData>? value, Value<int>? rowid}) {
    return SettingsCompanion(
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
      map['value'] =
          Variable<String>($SettingsTable.$convertervalue.toSql(value.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, DownloadRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _packageIdMeta =
      const VerificationMeta('packageId');
  @override
  late final GeneratedColumn<String> packageId = GeneratedColumn<String>(
      'package_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DownloadKind, String> kind =
      GeneratedColumn<String>('kind', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<DownloadKind>($DownloadsTable.$converterkind);
  static const VerificationMeta _activeVersionMeta =
      const VerificationMeta('activeVersion');
  @override
  late final GeneratedColumn<String> activeVersion = GeneratedColumn<String>(
      'active_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pendingVersionMeta =
      const VerificationMeta('pendingVersion');
  @override
  late final GeneratedColumn<String> pendingVersion = GeneratedColumn<String>(
      'pending_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<DownloadState, String> state =
      GeneratedColumn<String>('state', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<DownloadState>($DownloadsTable.$converterstate);
  static const VerificationMeta _bytesTotalMeta =
      const VerificationMeta('bytesTotal');
  @override
  late final GeneratedColumn<int> bytesTotal = GeneratedColumn<int>(
      'bytes_total', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bytesDoneMeta =
      const VerificationMeta('bytesDone');
  @override
  late final GeneratedColumn<int> bytesDone = GeneratedColumn<int>(
      'bytes_done', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        packageId,
        kind,
        activeVersion,
        pendingVersion,
        state,
        bytesTotal,
        bytesDone,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download';
  @override
  VerificationContext validateIntegrity(Insertable<DownloadRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('package_id')) {
      context.handle(_packageIdMeta,
          packageId.isAcceptableOrUnknown(data['package_id']!, _packageIdMeta));
    } else if (isInserting) {
      context.missing(_packageIdMeta);
    }
    if (data.containsKey('active_version')) {
      context.handle(
          _activeVersionMeta,
          activeVersion.isAcceptableOrUnknown(
              data['active_version']!, _activeVersionMeta));
    }
    if (data.containsKey('pending_version')) {
      context.handle(
          _pendingVersionMeta,
          pendingVersion.isAcceptableOrUnknown(
              data['pending_version']!, _pendingVersionMeta));
    }
    if (data.containsKey('bytes_total')) {
      context.handle(
          _bytesTotalMeta,
          bytesTotal.isAcceptableOrUnknown(
              data['bytes_total']!, _bytesTotalMeta));
    } else if (isInserting) {
      context.missing(_bytesTotalMeta);
    }
    if (data.containsKey('bytes_done')) {
      context.handle(_bytesDoneMeta,
          bytesDone.isAcceptableOrUnknown(data['bytes_done']!, _bytesDoneMeta));
    } else if (isInserting) {
      context.missing(_bytesDoneMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packageId};
  @override
  DownloadRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadRecord(
      packageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}package_id'])!,
      kind: $DownloadsTable.$converterkind.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
      activeVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}active_version']),
      pendingVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pending_version']),
      state: $DownloadsTable.$converterstate.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!),
      bytesTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bytes_total'])!,
      bytesDone: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bytes_done'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DownloadKind, String, String> $converterkind =
      const EnumNameConverter<DownloadKind>(DownloadKind.values);
  static JsonTypeConverter2<DownloadState, String, String> $converterstate =
      const EnumNameConverter<DownloadState>(DownloadState.values);
}

class DownloadRecord extends DataClass implements Insertable<DownloadRecord> {
  final String packageId;
  final DownloadKind kind;
  final String? activeVersion;
  final String? pendingVersion;
  final DownloadState state;
  final int bytesTotal;
  final int bytesDone;
  final int updatedAt;
  const DownloadRecord(
      {required this.packageId,
      required this.kind,
      this.activeVersion,
      this.pendingVersion,
      required this.state,
      required this.bytesTotal,
      required this.bytesDone,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['package_id'] = Variable<String>(packageId);
    {
      map['kind'] =
          Variable<String>($DownloadsTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || activeVersion != null) {
      map['active_version'] = Variable<String>(activeVersion);
    }
    if (!nullToAbsent || pendingVersion != null) {
      map['pending_version'] = Variable<String>(pendingVersion);
    }
    {
      map['state'] =
          Variable<String>($DownloadsTable.$converterstate.toSql(state));
    }
    map['bytes_total'] = Variable<int>(bytesTotal);
    map['bytes_done'] = Variable<int>(bytesDone);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      packageId: Value(packageId),
      kind: Value(kind),
      activeVersion: activeVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(activeVersion),
      pendingVersion: pendingVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingVersion),
      state: Value(state),
      bytesTotal: Value(bytesTotal),
      bytesDone: Value(bytesDone),
      updatedAt: Value(updatedAt),
    );
  }

  factory DownloadRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadRecord(
      packageId: serializer.fromJson<String>(json['packageId']),
      kind: $DownloadsTable.$converterkind
          .fromJson(serializer.fromJson<String>(json['kind'])),
      activeVersion: serializer.fromJson<String?>(json['activeVersion']),
      pendingVersion: serializer.fromJson<String?>(json['pendingVersion']),
      state: $DownloadsTable.$converterstate
          .fromJson(serializer.fromJson<String>(json['state'])),
      bytesTotal: serializer.fromJson<int>(json['bytesTotal']),
      bytesDone: serializer.fromJson<int>(json['bytesDone']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packageId': serializer.toJson<String>(packageId),
      'kind': serializer
          .toJson<String>($DownloadsTable.$converterkind.toJson(kind)),
      'activeVersion': serializer.toJson<String?>(activeVersion),
      'pendingVersion': serializer.toJson<String?>(pendingVersion),
      'state': serializer
          .toJson<String>($DownloadsTable.$converterstate.toJson(state)),
      'bytesTotal': serializer.toJson<int>(bytesTotal),
      'bytesDone': serializer.toJson<int>(bytesDone),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  DownloadRecord copyWith(
          {String? packageId,
          DownloadKind? kind,
          Value<String?> activeVersion = const Value.absent(),
          Value<String?> pendingVersion = const Value.absent(),
          DownloadState? state,
          int? bytesTotal,
          int? bytesDone,
          int? updatedAt}) =>
      DownloadRecord(
        packageId: packageId ?? this.packageId,
        kind: kind ?? this.kind,
        activeVersion:
            activeVersion.present ? activeVersion.value : this.activeVersion,
        pendingVersion:
            pendingVersion.present ? pendingVersion.value : this.pendingVersion,
        state: state ?? this.state,
        bytesTotal: bytesTotal ?? this.bytesTotal,
        bytesDone: bytesDone ?? this.bytesDone,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DownloadRecord copyWithCompanion(DownloadsCompanion data) {
    return DownloadRecord(
      packageId: data.packageId.present ? data.packageId.value : this.packageId,
      kind: data.kind.present ? data.kind.value : this.kind,
      activeVersion: data.activeVersion.present
          ? data.activeVersion.value
          : this.activeVersion,
      pendingVersion: data.pendingVersion.present
          ? data.pendingVersion.value
          : this.pendingVersion,
      state: data.state.present ? data.state.value : this.state,
      bytesTotal:
          data.bytesTotal.present ? data.bytesTotal.value : this.bytesTotal,
      bytesDone: data.bytesDone.present ? data.bytesDone.value : this.bytesDone,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadRecord(')
          ..write('packageId: $packageId, ')
          ..write('kind: $kind, ')
          ..write('activeVersion: $activeVersion, ')
          ..write('pendingVersion: $pendingVersion, ')
          ..write('state: $state, ')
          ..write('bytesTotal: $bytesTotal, ')
          ..write('bytesDone: $bytesDone, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(packageId, kind, activeVersion,
      pendingVersion, state, bytesTotal, bytesDone, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadRecord &&
          other.packageId == this.packageId &&
          other.kind == this.kind &&
          other.activeVersion == this.activeVersion &&
          other.pendingVersion == this.pendingVersion &&
          other.state == this.state &&
          other.bytesTotal == this.bytesTotal &&
          other.bytesDone == this.bytesDone &&
          other.updatedAt == this.updatedAt);
}

class DownloadsCompanion extends UpdateCompanion<DownloadRecord> {
  final Value<String> packageId;
  final Value<DownloadKind> kind;
  final Value<String?> activeVersion;
  final Value<String?> pendingVersion;
  final Value<DownloadState> state;
  final Value<int> bytesTotal;
  final Value<int> bytesDone;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.packageId = const Value.absent(),
    this.kind = const Value.absent(),
    this.activeVersion = const Value.absent(),
    this.pendingVersion = const Value.absent(),
    this.state = const Value.absent(),
    this.bytesTotal = const Value.absent(),
    this.bytesDone = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required String packageId,
    required DownloadKind kind,
    this.activeVersion = const Value.absent(),
    this.pendingVersion = const Value.absent(),
    required DownloadState state,
    required int bytesTotal,
    required int bytesDone,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : packageId = Value(packageId),
        kind = Value(kind),
        state = Value(state),
        bytesTotal = Value(bytesTotal),
        bytesDone = Value(bytesDone),
        updatedAt = Value(updatedAt);
  static Insertable<DownloadRecord> custom({
    Expression<String>? packageId,
    Expression<String>? kind,
    Expression<String>? activeVersion,
    Expression<String>? pendingVersion,
    Expression<String>? state,
    Expression<int>? bytesTotal,
    Expression<int>? bytesDone,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packageId != null) 'package_id': packageId,
      if (kind != null) 'kind': kind,
      if (activeVersion != null) 'active_version': activeVersion,
      if (pendingVersion != null) 'pending_version': pendingVersion,
      if (state != null) 'state': state,
      if (bytesTotal != null) 'bytes_total': bytesTotal,
      if (bytesDone != null) 'bytes_done': bytesDone,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith(
      {Value<String>? packageId,
      Value<DownloadKind>? kind,
      Value<String?>? activeVersion,
      Value<String?>? pendingVersion,
      Value<DownloadState>? state,
      Value<int>? bytesTotal,
      Value<int>? bytesDone,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return DownloadsCompanion(
      packageId: packageId ?? this.packageId,
      kind: kind ?? this.kind,
      activeVersion: activeVersion ?? this.activeVersion,
      pendingVersion: pendingVersion ?? this.pendingVersion,
      state: state ?? this.state,
      bytesTotal: bytesTotal ?? this.bytesTotal,
      bytesDone: bytesDone ?? this.bytesDone,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packageId.present) {
      map['package_id'] = Variable<String>(packageId.value);
    }
    if (kind.present) {
      map['kind'] =
          Variable<String>($DownloadsTable.$converterkind.toSql(kind.value));
    }
    if (activeVersion.present) {
      map['active_version'] = Variable<String>(activeVersion.value);
    }
    if (pendingVersion.present) {
      map['pending_version'] = Variable<String>(pendingVersion.value);
    }
    if (state.present) {
      map['state'] =
          Variable<String>($DownloadsTable.$converterstate.toSql(state.value));
    }
    if (bytesTotal.present) {
      map['bytes_total'] = Variable<int>(bytesTotal.value);
    }
    if (bytesDone.present) {
      map['bytes_done'] = Variable<int>(bytesDone.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('packageId: $packageId, ')
          ..write('kind: $kind, ')
          ..write('activeVersion: $activeVersion, ')
          ..write('pendingVersion: $pendingVersion, ')
          ..write('state: $state, ')
          ..write('bytesTotal: $bytesTotal, ')
          ..write('bytesDone: $bytesDone, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchKeyCacheEntriesTable extends SearchKeyCacheEntries
    with TableInfo<$SearchKeyCacheEntriesTable, SearchKeyCacheRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchKeyCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _normalizerIdMeta =
      const VerificationMeta('normalizerId');
  @override
  late final GeneratedColumn<String> normalizerId = GeneratedColumn<String>(
      'normalizer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wordIndexMeta =
      const VerificationMeta('wordIndex');
  @override
  late final GeneratedColumn<int> wordIndex = GeneratedColumn<int>(
      'word_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [normalizerId, wordIndex, key];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_key_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<SearchKeyCacheRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('normalizer_id')) {
      context.handle(
          _normalizerIdMeta,
          normalizerId.isAcceptableOrUnknown(
              data['normalizer_id']!, _normalizerIdMeta));
    } else if (isInserting) {
      context.missing(_normalizerIdMeta);
    }
    if (data.containsKey('word_index')) {
      context.handle(_wordIndexMeta,
          wordIndex.isAcceptableOrUnknown(data['word_index']!, _wordIndexMeta));
    } else if (isInserting) {
      context.missing(_wordIndexMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {normalizerId, wordIndex};
  @override
  SearchKeyCacheRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchKeyCacheRecord(
      normalizerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}normalizer_id'])!,
      wordIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}word_index'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
    );
  }

  @override
  $SearchKeyCacheEntriesTable createAlias(String alias) {
    return $SearchKeyCacheEntriesTable(attachedDatabase, alias);
  }
}

class SearchKeyCacheRecord extends DataClass
    implements Insertable<SearchKeyCacheRecord> {
  final String normalizerId;
  final int wordIndex;
  final String key;
  const SearchKeyCacheRecord(
      {required this.normalizerId, required this.wordIndex, required this.key});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['normalizer_id'] = Variable<String>(normalizerId);
    map['word_index'] = Variable<int>(wordIndex);
    map['key'] = Variable<String>(key);
    return map;
  }

  SearchKeyCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return SearchKeyCacheEntriesCompanion(
      normalizerId: Value(normalizerId),
      wordIndex: Value(wordIndex),
      key: Value(key),
    );
  }

  factory SearchKeyCacheRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchKeyCacheRecord(
      normalizerId: serializer.fromJson<String>(json['normalizerId']),
      wordIndex: serializer.fromJson<int>(json['wordIndex']),
      key: serializer.fromJson<String>(json['key']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'normalizerId': serializer.toJson<String>(normalizerId),
      'wordIndex': serializer.toJson<int>(wordIndex),
      'key': serializer.toJson<String>(key),
    };
  }

  SearchKeyCacheRecord copyWith(
          {String? normalizerId, int? wordIndex, String? key}) =>
      SearchKeyCacheRecord(
        normalizerId: normalizerId ?? this.normalizerId,
        wordIndex: wordIndex ?? this.wordIndex,
        key: key ?? this.key,
      );
  SearchKeyCacheRecord copyWithCompanion(SearchKeyCacheEntriesCompanion data) {
    return SearchKeyCacheRecord(
      normalizerId: data.normalizerId.present
          ? data.normalizerId.value
          : this.normalizerId,
      wordIndex: data.wordIndex.present ? data.wordIndex.value : this.wordIndex,
      key: data.key.present ? data.key.value : this.key,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchKeyCacheRecord(')
          ..write('normalizerId: $normalizerId, ')
          ..write('wordIndex: $wordIndex, ')
          ..write('key: $key')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(normalizerId, wordIndex, key);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchKeyCacheRecord &&
          other.normalizerId == this.normalizerId &&
          other.wordIndex == this.wordIndex &&
          other.key == this.key);
}

class SearchKeyCacheEntriesCompanion
    extends UpdateCompanion<SearchKeyCacheRecord> {
  final Value<String> normalizerId;
  final Value<int> wordIndex;
  final Value<String> key;
  final Value<int> rowid;
  const SearchKeyCacheEntriesCompanion({
    this.normalizerId = const Value.absent(),
    this.wordIndex = const Value.absent(),
    this.key = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchKeyCacheEntriesCompanion.insert({
    required String normalizerId,
    required int wordIndex,
    required String key,
    this.rowid = const Value.absent(),
  })  : normalizerId = Value(normalizerId),
        wordIndex = Value(wordIndex),
        key = Value(key);
  static Insertable<SearchKeyCacheRecord> custom({
    Expression<String>? normalizerId,
    Expression<int>? wordIndex,
    Expression<String>? key,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (normalizerId != null) 'normalizer_id': normalizerId,
      if (wordIndex != null) 'word_index': wordIndex,
      if (key != null) 'key': key,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchKeyCacheEntriesCompanion copyWith(
      {Value<String>? normalizerId,
      Value<int>? wordIndex,
      Value<String>? key,
      Value<int>? rowid}) {
    return SearchKeyCacheEntriesCompanion(
      normalizerId: normalizerId ?? this.normalizerId,
      wordIndex: wordIndex ?? this.wordIndex,
      key: key ?? this.key,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (normalizerId.present) {
      map['normalizer_id'] = Variable<String>(normalizerId.value);
    }
    if (wordIndex.present) {
      map['word_index'] = Variable<int>(wordIndex.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchKeyCacheEntriesCompanion(')
          ..write('normalizerId: $normalizerId, ')
          ..write('wordIndex: $wordIndex, ')
          ..write('key: $key, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NgramCacheEntriesTable extends NgramCacheEntries
    with TableInfo<$NgramCacheEntriesTable, NgramCacheRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NgramCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _normalizerIdMeta =
      const VerificationMeta('normalizerId');
  @override
  late final GeneratedColumn<String> normalizerId = GeneratedColumn<String>(
      'normalizer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ngramMeta = const VerificationMeta('ngram');
  @override
  late final GeneratedColumn<String> ngram = GeneratedColumn<String>(
      'ngram', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<WordIndexes, String> wordIndexes =
      GeneratedColumn<String>('word_indexes', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<WordIndexes>(
              $NgramCacheEntriesTable.$converterwordIndexes);
  @override
  List<GeneratedColumn> get $columns => [normalizerId, ngram, wordIndexes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ngram_cache';
  @override
  VerificationContext validateIntegrity(Insertable<NgramCacheRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('normalizer_id')) {
      context.handle(
          _normalizerIdMeta,
          normalizerId.isAcceptableOrUnknown(
              data['normalizer_id']!, _normalizerIdMeta));
    } else if (isInserting) {
      context.missing(_normalizerIdMeta);
    }
    if (data.containsKey('ngram')) {
      context.handle(
          _ngramMeta, ngram.isAcceptableOrUnknown(data['ngram']!, _ngramMeta));
    } else if (isInserting) {
      context.missing(_ngramMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {normalizerId, ngram};
  @override
  NgramCacheRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NgramCacheRecord(
      normalizerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}normalizer_id'])!,
      ngram: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ngram'])!,
      wordIndexes: $NgramCacheEntriesTable.$converterwordIndexes.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}word_indexes'])!),
    );
  }

  @override
  $NgramCacheEntriesTable createAlias(String alias) {
    return $NgramCacheEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<WordIndexes, String> $converterwordIndexes =
      const WordIndexesConverter();
}

class NgramCacheRecord extends DataClass
    implements Insertable<NgramCacheRecord> {
  final String normalizerId;
  final String ngram;
  final WordIndexes wordIndexes;
  const NgramCacheRecord(
      {required this.normalizerId,
      required this.ngram,
      required this.wordIndexes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['normalizer_id'] = Variable<String>(normalizerId);
    map['ngram'] = Variable<String>(ngram);
    {
      map['word_indexes'] = Variable<String>(
          $NgramCacheEntriesTable.$converterwordIndexes.toSql(wordIndexes));
    }
    return map;
  }

  NgramCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return NgramCacheEntriesCompanion(
      normalizerId: Value(normalizerId),
      ngram: Value(ngram),
      wordIndexes: Value(wordIndexes),
    );
  }

  factory NgramCacheRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NgramCacheRecord(
      normalizerId: serializer.fromJson<String>(json['normalizerId']),
      ngram: serializer.fromJson<String>(json['ngram']),
      wordIndexes: serializer.fromJson<WordIndexes>(json['wordIndexes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'normalizerId': serializer.toJson<String>(normalizerId),
      'ngram': serializer.toJson<String>(ngram),
      'wordIndexes': serializer.toJson<WordIndexes>(wordIndexes),
    };
  }

  NgramCacheRecord copyWith(
          {String? normalizerId, String? ngram, WordIndexes? wordIndexes}) =>
      NgramCacheRecord(
        normalizerId: normalizerId ?? this.normalizerId,
        ngram: ngram ?? this.ngram,
        wordIndexes: wordIndexes ?? this.wordIndexes,
      );
  NgramCacheRecord copyWithCompanion(NgramCacheEntriesCompanion data) {
    return NgramCacheRecord(
      normalizerId: data.normalizerId.present
          ? data.normalizerId.value
          : this.normalizerId,
      ngram: data.ngram.present ? data.ngram.value : this.ngram,
      wordIndexes:
          data.wordIndexes.present ? data.wordIndexes.value : this.wordIndexes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NgramCacheRecord(')
          ..write('normalizerId: $normalizerId, ')
          ..write('ngram: $ngram, ')
          ..write('wordIndexes: $wordIndexes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(normalizerId, ngram, wordIndexes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NgramCacheRecord &&
          other.normalizerId == this.normalizerId &&
          other.ngram == this.ngram &&
          other.wordIndexes == this.wordIndexes);
}

class NgramCacheEntriesCompanion extends UpdateCompanion<NgramCacheRecord> {
  final Value<String> normalizerId;
  final Value<String> ngram;
  final Value<WordIndexes> wordIndexes;
  final Value<int> rowid;
  const NgramCacheEntriesCompanion({
    this.normalizerId = const Value.absent(),
    this.ngram = const Value.absent(),
    this.wordIndexes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NgramCacheEntriesCompanion.insert({
    required String normalizerId,
    required String ngram,
    required WordIndexes wordIndexes,
    this.rowid = const Value.absent(),
  })  : normalizerId = Value(normalizerId),
        ngram = Value(ngram),
        wordIndexes = Value(wordIndexes);
  static Insertable<NgramCacheRecord> custom({
    Expression<String>? normalizerId,
    Expression<String>? ngram,
    Expression<String>? wordIndexes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (normalizerId != null) 'normalizer_id': normalizerId,
      if (ngram != null) 'ngram': ngram,
      if (wordIndexes != null) 'word_indexes': wordIndexes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NgramCacheEntriesCompanion copyWith(
      {Value<String>? normalizerId,
      Value<String>? ngram,
      Value<WordIndexes>? wordIndexes,
      Value<int>? rowid}) {
    return NgramCacheEntriesCompanion(
      normalizerId: normalizerId ?? this.normalizerId,
      ngram: ngram ?? this.ngram,
      wordIndexes: wordIndexes ?? this.wordIndexes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (normalizerId.present) {
      map['normalizer_id'] = Variable<String>(normalizerId.value);
    }
    if (ngram.present) {
      map['ngram'] = Variable<String>(ngram.value);
    }
    if (wordIndexes.present) {
      map['word_indexes'] = Variable<String>($NgramCacheEntriesTable
          .$converterwordIndexes
          .toSql(wordIndexes.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NgramCacheEntriesCompanion(')
          ..write('normalizerId: $normalizerId, ')
          ..write('ngram: $ngram, ')
          ..write('wordIndexes: $wordIndexes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedRecordingsTable extends SavedRecordings
    with TableInfo<$SavedRecordingsTable, SavedRecordingRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedRecordingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, sessionId, path, durationMs, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_recording';
  @override
  VerificationContext validateIntegrity(
      Insertable<SavedRecordingRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedRecordingRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedRecordingRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SavedRecordingsTable createAlias(String alias) {
    return $SavedRecordingsTable(attachedDatabase, alias);
  }
}

class SavedRecordingRecord extends DataClass
    implements Insertable<SavedRecordingRecord> {
  final String id;
  final String sessionId;
  final String path;
  final int durationMs;
  final int createdAt;
  const SavedRecordingRecord(
      {required this.id,
      required this.sessionId,
      required this.path,
      required this.durationMs,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['path'] = Variable<String>(path);
    map['duration_ms'] = Variable<int>(durationMs);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SavedRecordingsCompanion toCompanion(bool nullToAbsent) {
    return SavedRecordingsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      path: Value(path),
      durationMs: Value(durationMs),
      createdAt: Value(createdAt),
    );
  }

  factory SavedRecordingRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedRecordingRecord(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      path: serializer.fromJson<String>(json['path']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'path': serializer.toJson<String>(path),
      'durationMs': serializer.toJson<int>(durationMs),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SavedRecordingRecord copyWith(
          {String? id,
          String? sessionId,
          String? path,
          int? durationMs,
          int? createdAt}) =>
      SavedRecordingRecord(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        path: path ?? this.path,
        durationMs: durationMs ?? this.durationMs,
        createdAt: createdAt ?? this.createdAt,
      );
  SavedRecordingRecord copyWithCompanion(SavedRecordingsCompanion data) {
    return SavedRecordingRecord(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      path: data.path.present ? data.path.value : this.path,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedRecordingRecord(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('path: $path, ')
          ..write('durationMs: $durationMs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, path, durationMs, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedRecordingRecord &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.path == this.path &&
          other.durationMs == this.durationMs &&
          other.createdAt == this.createdAt);
}

class SavedRecordingsCompanion extends UpdateCompanion<SavedRecordingRecord> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> path;
  final Value<int> durationMs;
  final Value<int> createdAt;
  final Value<int> rowid;
  const SavedRecordingsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.path = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedRecordingsCompanion.insert({
    required String id,
    required String sessionId,
    required String path,
    required int durationMs,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sessionId = Value(sessionId),
        path = Value(path),
        durationMs = Value(durationMs),
        createdAt = Value(createdAt);
  static Insertable<SavedRecordingRecord> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? path,
    Expression<int>? durationMs,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (path != null) 'path': path,
      if (durationMs != null) 'duration_ms': durationMs,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedRecordingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? sessionId,
      Value<String>? path,
      Value<int>? durationMs,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return SavedRecordingsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      path: path ?? this.path,
      durationMs: durationMs ?? this.durationMs,
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
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedRecordingsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('path: $path, ')
          ..write('durationMs: $durationMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UploadQueueEntriesTable extends UploadQueueEntries
    with TableInfo<$UploadQueueEntriesTable, UploadQueueRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UploadQueueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<UploadMetadata, String> meta =
      GeneratedColumn<String>('meta', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<UploadMetadata>(
              $UploadQueueEntriesTable.$convertermeta);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
      'bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<UploadState, String> state =
      GeneratedColumn<String>('state', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<UploadState>($UploadQueueEntriesTable.$converterstate);
  static const VerificationMeta _triesMeta = const VerificationMeta('tries');
  @override
  late final GeneratedColumn<int> tries = GeneratedColumn<int>(
      'tries', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, sessionId, filePath, meta, priority, bytes, state, tries, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'upload_queue';
  @override
  VerificationContext validateIntegrity(Insertable<UploadQueueRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
          _bytesMeta, bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta));
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('tries')) {
      context.handle(
          _triesMeta, tries.isAcceptableOrUnknown(data['tries']!, _triesMeta));
    } else if (isInserting) {
      context.missing(_triesMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UploadQueueRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UploadQueueRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      meta: $UploadQueueEntriesTable.$convertermeta.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meta'])!),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      bytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bytes'])!,
      state: $UploadQueueEntriesTable.$converterstate.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!),
      tries: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tries'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $UploadQueueEntriesTable createAlias(String alias) {
    return $UploadQueueEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<UploadMetadata, String> $convertermeta =
      const UploadMetadataConverter();
  static JsonTypeConverter2<UploadState, String, String> $converterstate =
      const EnumNameConverter<UploadState>(UploadState.values);
}

class UploadQueueRecord extends DataClass
    implements Insertable<UploadQueueRecord> {
  final String id;
  final String sessionId;
  final String filePath;
  final UploadMetadata meta;
  final int priority;
  final int bytes;
  final UploadState state;
  final int tries;
  final int createdAt;
  const UploadQueueRecord(
      {required this.id,
      required this.sessionId,
      required this.filePath,
      required this.meta,
      required this.priority,
      required this.bytes,
      required this.state,
      required this.tries,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['file_path'] = Variable<String>(filePath);
    {
      map['meta'] =
          Variable<String>($UploadQueueEntriesTable.$convertermeta.toSql(meta));
    }
    map['priority'] = Variable<int>(priority);
    map['bytes'] = Variable<int>(bytes);
    {
      map['state'] = Variable<String>(
          $UploadQueueEntriesTable.$converterstate.toSql(state));
    }
    map['tries'] = Variable<int>(tries);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  UploadQueueEntriesCompanion toCompanion(bool nullToAbsent) {
    return UploadQueueEntriesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      filePath: Value(filePath),
      meta: Value(meta),
      priority: Value(priority),
      bytes: Value(bytes),
      state: Value(state),
      tries: Value(tries),
      createdAt: Value(createdAt),
    );
  }

  factory UploadQueueRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UploadQueueRecord(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      meta: serializer.fromJson<UploadMetadata>(json['meta']),
      priority: serializer.fromJson<int>(json['priority']),
      bytes: serializer.fromJson<int>(json['bytes']),
      state: $UploadQueueEntriesTable.$converterstate
          .fromJson(serializer.fromJson<String>(json['state'])),
      tries: serializer.fromJson<int>(json['tries']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'filePath': serializer.toJson<String>(filePath),
      'meta': serializer.toJson<UploadMetadata>(meta),
      'priority': serializer.toJson<int>(priority),
      'bytes': serializer.toJson<int>(bytes),
      'state': serializer.toJson<String>(
          $UploadQueueEntriesTable.$converterstate.toJson(state)),
      'tries': serializer.toJson<int>(tries),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  UploadQueueRecord copyWith(
          {String? id,
          String? sessionId,
          String? filePath,
          UploadMetadata? meta,
          int? priority,
          int? bytes,
          UploadState? state,
          int? tries,
          int? createdAt}) =>
      UploadQueueRecord(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        filePath: filePath ?? this.filePath,
        meta: meta ?? this.meta,
        priority: priority ?? this.priority,
        bytes: bytes ?? this.bytes,
        state: state ?? this.state,
        tries: tries ?? this.tries,
        createdAt: createdAt ?? this.createdAt,
      );
  UploadQueueRecord copyWithCompanion(UploadQueueEntriesCompanion data) {
    return UploadQueueRecord(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      meta: data.meta.present ? data.meta.value : this.meta,
      priority: data.priority.present ? data.priority.value : this.priority,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      state: data.state.present ? data.state.value : this.state,
      tries: data.tries.present ? data.tries.value : this.tries,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UploadQueueRecord(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('filePath: $filePath, ')
          ..write('meta: $meta, ')
          ..write('priority: $priority, ')
          ..write('bytes: $bytes, ')
          ..write('state: $state, ')
          ..write('tries: $tries, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, sessionId, filePath, meta, priority, bytes, state, tries, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UploadQueueRecord &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.filePath == this.filePath &&
          other.meta == this.meta &&
          other.priority == this.priority &&
          other.bytes == this.bytes &&
          other.state == this.state &&
          other.tries == this.tries &&
          other.createdAt == this.createdAt);
}

class UploadQueueEntriesCompanion extends UpdateCompanion<UploadQueueRecord> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> filePath;
  final Value<UploadMetadata> meta;
  final Value<int> priority;
  final Value<int> bytes;
  final Value<UploadState> state;
  final Value<int> tries;
  final Value<int> createdAt;
  final Value<int> rowid;
  const UploadQueueEntriesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.meta = const Value.absent(),
    this.priority = const Value.absent(),
    this.bytes = const Value.absent(),
    this.state = const Value.absent(),
    this.tries = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UploadQueueEntriesCompanion.insert({
    required String id,
    required String sessionId,
    required String filePath,
    required UploadMetadata meta,
    required int priority,
    required int bytes,
    required UploadState state,
    required int tries,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sessionId = Value(sessionId),
        filePath = Value(filePath),
        meta = Value(meta),
        priority = Value(priority),
        bytes = Value(bytes),
        state = Value(state),
        tries = Value(tries),
        createdAt = Value(createdAt);
  static Insertable<UploadQueueRecord> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? filePath,
    Expression<String>? meta,
    Expression<int>? priority,
    Expression<int>? bytes,
    Expression<String>? state,
    Expression<int>? tries,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (filePath != null) 'file_path': filePath,
      if (meta != null) 'meta': meta,
      if (priority != null) 'priority': priority,
      if (bytes != null) 'bytes': bytes,
      if (state != null) 'state': state,
      if (tries != null) 'tries': tries,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UploadQueueEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? sessionId,
      Value<String>? filePath,
      Value<UploadMetadata>? meta,
      Value<int>? priority,
      Value<int>? bytes,
      Value<UploadState>? state,
      Value<int>? tries,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return UploadQueueEntriesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      filePath: filePath ?? this.filePath,
      meta: meta ?? this.meta,
      priority: priority ?? this.priority,
      bytes: bytes ?? this.bytes,
      state: state ?? this.state,
      tries: tries ?? this.tries,
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
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (meta.present) {
      map['meta'] = Variable<String>(
          $UploadQueueEntriesTable.$convertermeta.toSql(meta.value));
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
          $UploadQueueEntriesTable.$converterstate.toSql(state.value));
    }
    if (tries.present) {
      map['tries'] = Variable<int>(tries.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UploadQueueEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('filePath: $filePath, ')
          ..write('meta: $meta, ')
          ..write('priority: $priority, ')
          ..write('bytes: $bytes, ')
          ..write('state: $state, ')
          ..write('tries: $tries, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntitlementCacheEntriesTable extends EntitlementCacheEntries
    with TableInfo<$EntitlementCacheEntriesTable, EntitlementCacheRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntitlementCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<EntitlementState, String> state =
      GeneratedColumn<String>('state', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<EntitlementState>(
              $EntitlementCacheEntriesTable.$converterstate);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastVerifiedAtMeta =
      const VerificationMeta('lastVerifiedAt');
  @override
  late final GeneratedColumn<int> lastVerifiedAt = GeneratedColumn<int>(
      'last_verified_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, state, expiresAt, lastVerifiedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entitlement_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<EntitlementCacheRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    if (data.containsKey('last_verified_at')) {
      context.handle(
          _lastVerifiedAtMeta,
          lastVerifiedAt.isAcceptableOrUnknown(
              data['last_verified_at']!, _lastVerifiedAtMeta));
    } else if (isInserting) {
      context.missing(_lastVerifiedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntitlementCacheRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntitlementCacheRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      state: $EntitlementCacheEntriesTable.$converterstate.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.string, data['${effectivePrefix}state'])!),
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expires_at']),
      lastVerifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_verified_at'])!,
    );
  }

  @override
  $EntitlementCacheEntriesTable createAlias(String alias) {
    return $EntitlementCacheEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EntitlementState, String, String> $converterstate =
      const EnumNameConverter<EntitlementState>(EntitlementState.values);
}

class EntitlementCacheRecord extends DataClass
    implements Insertable<EntitlementCacheRecord> {
  final String id;
  final EntitlementState state;
  final int? expiresAt;
  final int lastVerifiedAt;
  const EntitlementCacheRecord(
      {required this.id,
      required this.state,
      this.expiresAt,
      required this.lastVerifiedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['state'] = Variable<String>(
          $EntitlementCacheEntriesTable.$converterstate.toSql(state));
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<int>(expiresAt);
    }
    map['last_verified_at'] = Variable<int>(lastVerifiedAt);
    return map;
  }

  EntitlementCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return EntitlementCacheEntriesCompanion(
      id: Value(id),
      state: Value(state),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      lastVerifiedAt: Value(lastVerifiedAt),
    );
  }

  factory EntitlementCacheRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntitlementCacheRecord(
      id: serializer.fromJson<String>(json['id']),
      state: $EntitlementCacheEntriesTable.$converterstate
          .fromJson(serializer.fromJson<String>(json['state'])),
      expiresAt: serializer.fromJson<int?>(json['expiresAt']),
      lastVerifiedAt: serializer.fromJson<int>(json['lastVerifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'state': serializer.toJson<String>(
          $EntitlementCacheEntriesTable.$converterstate.toJson(state)),
      'expiresAt': serializer.toJson<int?>(expiresAt),
      'lastVerifiedAt': serializer.toJson<int>(lastVerifiedAt),
    };
  }

  EntitlementCacheRecord copyWith(
          {String? id,
          EntitlementState? state,
          Value<int?> expiresAt = const Value.absent(),
          int? lastVerifiedAt}) =>
      EntitlementCacheRecord(
        id: id ?? this.id,
        state: state ?? this.state,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      );
  EntitlementCacheRecord copyWithCompanion(
      EntitlementCacheEntriesCompanion data) {
    return EntitlementCacheRecord(
      id: data.id.present ? data.id.value : this.id,
      state: data.state.present ? data.state.value : this.state,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      lastVerifiedAt: data.lastVerifiedAt.present
          ? data.lastVerifiedAt.value
          : this.lastVerifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntitlementCacheRecord(')
          ..write('id: $id, ')
          ..write('state: $state, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastVerifiedAt: $lastVerifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, state, expiresAt, lastVerifiedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntitlementCacheRecord &&
          other.id == this.id &&
          other.state == this.state &&
          other.expiresAt == this.expiresAt &&
          other.lastVerifiedAt == this.lastVerifiedAt);
}

class EntitlementCacheEntriesCompanion
    extends UpdateCompanion<EntitlementCacheRecord> {
  final Value<String> id;
  final Value<EntitlementState> state;
  final Value<int?> expiresAt;
  final Value<int> lastVerifiedAt;
  final Value<int> rowid;
  const EntitlementCacheEntriesCompanion({
    this.id = const Value.absent(),
    this.state = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntitlementCacheEntriesCompanion.insert({
    required String id,
    required EntitlementState state,
    this.expiresAt = const Value.absent(),
    required int lastVerifiedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        state = Value(state),
        lastVerifiedAt = Value(lastVerifiedAt);
  static Insertable<EntitlementCacheRecord> custom({
    Expression<String>? id,
    Expression<String>? state,
    Expression<int>? expiresAt,
    Expression<int>? lastVerifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (state != null) 'state': state,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntitlementCacheEntriesCompanion copyWith(
      {Value<String>? id,
      Value<EntitlementState>? state,
      Value<int?>? expiresAt,
      Value<int>? lastVerifiedAt,
      Value<int>? rowid}) {
    return EntitlementCacheEntriesCompanion(
      id: id ?? this.id,
      state: state ?? this.state,
      expiresAt: expiresAt ?? this.expiresAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
          $EntitlementCacheEntriesTable.$converterstate.toSql(state.value));
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (lastVerifiedAt.present) {
      map['last_verified_at'] = Variable<int>(lastVerifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntitlementCacheEntriesCompanion(')
          ..write('id: $id, ')
          ..write('state: $state, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FreeUsageEntriesTable extends FreeUsageEntries
    with TableInfo<$FreeUsageEntriesTable, FreeUsageRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FreeUsageEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 10, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _listeningMsMeta =
      const VerificationMeta('listeningMs');
  @override
  late final GeneratedColumn<int> listeningMs = GeneratedColumn<int>(
      'listening_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [date, listeningMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'free_usage';
  @override
  VerificationContext validateIntegrity(Insertable<FreeUsageRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('listening_ms')) {
      context.handle(
          _listeningMsMeta,
          listeningMs.isAcceptableOrUnknown(
              data['listening_ms']!, _listeningMsMeta));
    } else if (isInserting) {
      context.missing(_listeningMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  FreeUsageRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FreeUsageRecord(
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      listeningMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}listening_ms'])!,
    );
  }

  @override
  $FreeUsageEntriesTable createAlias(String alias) {
    return $FreeUsageEntriesTable(attachedDatabase, alias);
  }
}

class FreeUsageRecord extends DataClass implements Insertable<FreeUsageRecord> {
  final String date;
  final int listeningMs;
  const FreeUsageRecord({required this.date, required this.listeningMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['listening_ms'] = Variable<int>(listeningMs);
    return map;
  }

  FreeUsageEntriesCompanion toCompanion(bool nullToAbsent) {
    return FreeUsageEntriesCompanion(
      date: Value(date),
      listeningMs: Value(listeningMs),
    );
  }

  factory FreeUsageRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FreeUsageRecord(
      date: serializer.fromJson<String>(json['date']),
      listeningMs: serializer.fromJson<int>(json['listeningMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'listeningMs': serializer.toJson<int>(listeningMs),
    };
  }

  FreeUsageRecord copyWith({String? date, int? listeningMs}) => FreeUsageRecord(
        date: date ?? this.date,
        listeningMs: listeningMs ?? this.listeningMs,
      );
  FreeUsageRecord copyWithCompanion(FreeUsageEntriesCompanion data) {
    return FreeUsageRecord(
      date: data.date.present ? data.date.value : this.date,
      listeningMs:
          data.listeningMs.present ? data.listeningMs.value : this.listeningMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FreeUsageRecord(')
          ..write('date: $date, ')
          ..write('listeningMs: $listeningMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, listeningMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FreeUsageRecord &&
          other.date == this.date &&
          other.listeningMs == this.listeningMs);
}

class FreeUsageEntriesCompanion extends UpdateCompanion<FreeUsageRecord> {
  final Value<String> date;
  final Value<int> listeningMs;
  final Value<int> rowid;
  const FreeUsageEntriesCompanion({
    this.date = const Value.absent(),
    this.listeningMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FreeUsageEntriesCompanion.insert({
    required String date,
    required int listeningMs,
    this.rowid = const Value.absent(),
  })  : date = Value(date),
        listeningMs = Value(listeningMs);
  static Insertable<FreeUsageRecord> custom({
    Expression<String>? date,
    Expression<int>? listeningMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (listeningMs != null) 'listening_ms': listeningMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FreeUsageEntriesCompanion copyWith(
      {Value<String>? date, Value<int>? listeningMs, Value<int>? rowid}) {
    return FreeUsageEntriesCompanion(
      date: date ?? this.date,
      listeningMs: listeningMs ?? this.listeningMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (listeningMs.present) {
      map['listening_ms'] = Variable<int>(listeningMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FreeUsageEntriesCompanion(')
          ..write('date: $date, ')
          ..write('listeningMs: $listeningMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxEntriesTable extends OutboxEntries
    with TableInfo<$OutboxEntriesTable, OutboxRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 36, maxTextLength: 36),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<JsonObjectData, String> event =
      GeneratedColumn<String>('event', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<JsonObjectData>($OutboxEntriesTable.$converterevent);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, event, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      event: $OutboxEntriesTable.$converterevent.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}event'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $OutboxEntriesTable createAlias(String alias) {
    return $OutboxEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<JsonObjectData, String> $converterevent =
      const JsonObjectConverter();
}

class OutboxRecord extends DataClass implements Insertable<OutboxRecord> {
  final String id;
  final JsonObjectData event;
  final int createdAt;
  const OutboxRecord(
      {required this.id, required this.event, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['event'] =
          Variable<String>($OutboxEntriesTable.$converterevent.toSql(event));
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  OutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntriesCompanion(
      id: Value(id),
      event: Value(event),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRecord(
      id: serializer.fromJson<String>(json['id']),
      event: serializer.fromJson<JsonObjectData>(json['event']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'event': serializer.toJson<JsonObjectData>(event),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  OutboxRecord copyWith({String? id, JsonObjectData? event, int? createdAt}) =>
      OutboxRecord(
        id: id ?? this.id,
        event: event ?? this.event,
        createdAt: createdAt ?? this.createdAt,
      );
  OutboxRecord copyWithCompanion(OutboxEntriesCompanion data) {
    return OutboxRecord(
      id: data.id.present ? data.id.value : this.id,
      event: data.event.present ? data.event.value : this.event,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRecord(')
          ..write('id: $id, ')
          ..write('event: $event, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, event, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRecord &&
          other.id == this.id &&
          other.event == this.event &&
          other.createdAt == this.createdAt);
}

class OutboxEntriesCompanion extends UpdateCompanion<OutboxRecord> {
  final Value<String> id;
  final Value<JsonObjectData> event;
  final Value<int> createdAt;
  final Value<int> rowid;
  const OutboxEntriesCompanion({
    this.id = const Value.absent(),
    this.event = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxEntriesCompanion.insert({
    required String id,
    required JsonObjectData event,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        event = Value(event),
        createdAt = Value(createdAt);
  static Insertable<OutboxRecord> custom({
    Expression<String>? id,
    Expression<String>? event,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (event != null) 'event': event,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxEntriesCompanion copyWith(
      {Value<String>? id,
      Value<JsonObjectData>? event,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return OutboxEntriesCompanion(
      id: id ?? this.id,
      event: event ?? this.event,
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
    if (event.present) {
      map['event'] = Variable<String>(
          $OutboxEntriesTable.$converterevent.toSql(event.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntriesCompanion(')
          ..write('id: $id, ')
          ..write('event: $event, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SudurDatabase extends GeneratedDatabase {
  _$SudurDatabase(QueryExecutor e) : super(e);
  $SudurDatabaseManager get managers => $SudurDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $UnitsTable units = $UnitsTable(this);
  late final $UnitStatesTable unitStates = $UnitStatesTable(this);
  late final $AttemptsTable attempts = $AttemptsTable(this);
  late final $CheckEventsTable checkEvents = $CheckEventsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $DailyPlansTable dailyPlans = $DailyPlansTable(this);
  late final $LessonProgressEntriesTable lessonProgressEntries =
      $LessonProgressEntriesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  late final $SearchKeyCacheEntriesTable searchKeyCacheEntries =
      $SearchKeyCacheEntriesTable(this);
  late final $NgramCacheEntriesTable ngramCacheEntries =
      $NgramCacheEntriesTable(this);
  late final $SavedRecordingsTable savedRecordings =
      $SavedRecordingsTable(this);
  late final $UploadQueueEntriesTable uploadQueueEntries =
      $UploadQueueEntriesTable(this);
  late final $EntitlementCacheEntriesTable entitlementCacheEntries =
      $EntitlementCacheEntriesTable(this);
  late final $FreeUsageEntriesTable freeUsageEntries =
      $FreeUsageEntriesTable(this);
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  late final Index unitProfileKind = Index('unit_profile_kind',
      'CREATE INDEX unit_profile_kind ON unit (profile_id, kind)');
  late final Index unitStateDueAt = Index('unit_state_due_at',
      'CREATE INDEX unit_state_due_at ON unit_state (due_at)');
  late final Index attemptUnitCreated = Index('attempt_unit_created',
      'CREATE INDEX attempt_unit_created ON attempt (unit_id, created_at)');
  late final Index checkEventSession = Index('check_event_session',
      'CREATE INDEX check_event_session ON check_event (session_id)');
  late final Index uploadQueueStatePriority = Index(
      'upload_queue_state_priority',
      'CREATE INDEX upload_queue_state_priority ON upload_queue (state, priority)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        profiles,
        units,
        unitStates,
        attempts,
        checkEvents,
        sessions,
        dailyPlans,
        lessonProgressEntries,
        settings,
        downloads,
        searchKeyCacheEntries,
        ngramCacheEntries,
        savedRecordings,
        uploadQueueEntries,
        entitlementCacheEntries,
        freeUsageEntries,
        outboxEntries,
        unitProfileKind,
        unitStateDueAt,
        attemptUnitCreated,
        checkEventSession,
        uploadQueueStatePriority
      ];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  required String id,
  required int createdAt,
  required UiLanguage uiLanguage,
  required LearningPath path,
  required int dailyMinutes,
  required ReadingBehavior behavior,
  required bool showFirstWord,
  Value<int> rowid,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<UiLanguage> uiLanguage,
  Value<LearningPath> path,
  Value<int> dailyMinutes,
  Value<ReadingBehavior> behavior,
  Value<bool> showFirstWord,
  Value<int> rowid,
});

class $$ProfilesTableFilterComposer
    extends Composer<_$SudurDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<UiLanguage, UiLanguage, String>
      get uiLanguage => $composableBuilder(
          column: $table.uiLanguage,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<LearningPath, LearningPath, String> get path =>
      $composableBuilder(
          column: $table.path,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get dailyMinutes => $composableBuilder(
      column: $table.dailyMinutes, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ReadingBehavior, ReadingBehavior, String>
      get behavior => $composableBuilder(
          column: $table.behavior,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get showFirstWord => $composableBuilder(
      column: $table.showFirstWord, builder: (column) => ColumnFilters(column));
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$SudurDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uiLanguage => $composableBuilder(
      column: $table.uiLanguage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailyMinutes => $composableBuilder(
      column: $table.dailyMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get behavior => $composableBuilder(
      column: $table.behavior, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showFirstWord => $composableBuilder(
      column: $table.showFirstWord,
      builder: (column) => ColumnOrderings(column));
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$SudurDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UiLanguage, String> get uiLanguage =>
      $composableBuilder(
          column: $table.uiLanguage, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LearningPath, String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get dailyMinutes => $composableBuilder(
      column: $table.dailyMinutes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReadingBehavior, String> get behavior =>
      $composableBuilder(column: $table.behavior, builder: (column) => column);

  GeneratedColumn<bool> get showFirstWord => $composableBuilder(
      column: $table.showFirstWord, builder: (column) => column);
}

class $$ProfilesTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $ProfilesTable,
    ProfileRecord,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (
      ProfileRecord,
      BaseReferences<_$SudurDatabase, $ProfilesTable, ProfileRecord>
    ),
    ProfileRecord,
    PrefetchHooks Function()> {
  $$ProfilesTableTableManager(_$SudurDatabase db, $ProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<UiLanguage> uiLanguage = const Value.absent(),
            Value<LearningPath> path = const Value.absent(),
            Value<int> dailyMinutes = const Value.absent(),
            Value<ReadingBehavior> behavior = const Value.absent(),
            Value<bool> showFirstWord = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfilesCompanion(
            id: id,
            createdAt: createdAt,
            uiLanguage: uiLanguage,
            path: path,
            dailyMinutes: dailyMinutes,
            behavior: behavior,
            showFirstWord: showFirstWord,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int createdAt,
            required UiLanguage uiLanguage,
            required LearningPath path,
            required int dailyMinutes,
            required ReadingBehavior behavior,
            required bool showFirstWord,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfilesCompanion.insert(
            id: id,
            createdAt: createdAt,
            uiLanguage: uiLanguage,
            path: path,
            dailyMinutes: dailyMinutes,
            behavior: behavior,
            showFirstWord: showFirstWord,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProfilesTableProcessedTableManager = ProcessedTableManager<
    _$SudurDatabase,
    $ProfilesTable,
    ProfileRecord,
    $$ProfilesTableFilterComposer,
    $$ProfilesTableOrderingComposer,
    $$ProfilesTableAnnotationComposer,
    $$ProfilesTableCreateCompanionBuilder,
    $$ProfilesTableUpdateCompanionBuilder,
    (
      ProfileRecord,
      BaseReferences<_$SudurDatabase, $ProfilesTable, ProfileRecord>
    ),
    ProfileRecord,
    PrefetchHooks Function()>;
typedef $$UnitsTableCreateCompanionBuilder = UnitsCompanion Function({
  required String id,
  required String profileId,
  required UnitKind kind,
  Value<int?> fromWordIndex,
  Value<int?> toWordIndex,
  Value<String?> skillId,
  Value<int?> surah,
  required UnitOrigin origin,
  Value<String?> parentUnitId,
  required int createdAt,
  Value<int> rowid,
});
typedef $$UnitsTableUpdateCompanionBuilder = UnitsCompanion Function({
  Value<String> id,
  Value<String> profileId,
  Value<UnitKind> kind,
  Value<int?> fromWordIndex,
  Value<int?> toWordIndex,
  Value<String?> skillId,
  Value<int?> surah,
  Value<UnitOrigin> origin,
  Value<String?> parentUnitId,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$UnitsTableFilterComposer
    extends Composer<_$SudurDatabase, $UnitsTable> {
  $$UnitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<UnitKind, UnitKind, String> get kind =>
      $composableBuilder(
          column: $table.kind,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get fromWordIndex => $composableBuilder(
      column: $table.fromWordIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get toWordIndex => $composableBuilder(
      column: $table.toWordIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get skillId => $composableBuilder(
      column: $table.skillId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get surah => $composableBuilder(
      column: $table.surah, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<UnitOrigin, UnitOrigin, String> get origin =>
      $composableBuilder(
          column: $table.origin,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get parentUnitId => $composableBuilder(
      column: $table.parentUnitId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$UnitsTableOrderingComposer
    extends Composer<_$SudurDatabase, $UnitsTable> {
  $$UnitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fromWordIndex => $composableBuilder(
      column: $table.fromWordIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get toWordIndex => $composableBuilder(
      column: $table.toWordIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get skillId => $composableBuilder(
      column: $table.skillId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get surah => $composableBuilder(
      column: $table.surah, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get origin => $composableBuilder(
      column: $table.origin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentUnitId => $composableBuilder(
      column: $table.parentUnitId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$UnitsTableAnnotationComposer
    extends Composer<_$SudurDatabase, $UnitsTable> {
  $$UnitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UnitKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get fromWordIndex => $composableBuilder(
      column: $table.fromWordIndex, builder: (column) => column);

  GeneratedColumn<int> get toWordIndex => $composableBuilder(
      column: $table.toWordIndex, builder: (column) => column);

  GeneratedColumn<String> get skillId =>
      $composableBuilder(column: $table.skillId, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UnitOrigin, String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get parentUnitId => $composableBuilder(
      column: $table.parentUnitId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UnitsTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $UnitsTable,
    UnitRecord,
    $$UnitsTableFilterComposer,
    $$UnitsTableOrderingComposer,
    $$UnitsTableAnnotationComposer,
    $$UnitsTableCreateCompanionBuilder,
    $$UnitsTableUpdateCompanionBuilder,
    (UnitRecord, BaseReferences<_$SudurDatabase, $UnitsTable, UnitRecord>),
    UnitRecord,
    PrefetchHooks Function()> {
  $$UnitsTableTableManager(_$SudurDatabase db, $UnitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<UnitKind> kind = const Value.absent(),
            Value<int?> fromWordIndex = const Value.absent(),
            Value<int?> toWordIndex = const Value.absent(),
            Value<String?> skillId = const Value.absent(),
            Value<int?> surah = const Value.absent(),
            Value<UnitOrigin> origin = const Value.absent(),
            Value<String?> parentUnitId = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitsCompanion(
            id: id,
            profileId: profileId,
            kind: kind,
            fromWordIndex: fromWordIndex,
            toWordIndex: toWordIndex,
            skillId: skillId,
            surah: surah,
            origin: origin,
            parentUnitId: parentUnitId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required UnitKind kind,
            Value<int?> fromWordIndex = const Value.absent(),
            Value<int?> toWordIndex = const Value.absent(),
            Value<String?> skillId = const Value.absent(),
            Value<int?> surah = const Value.absent(),
            required UnitOrigin origin,
            Value<String?> parentUnitId = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitsCompanion.insert(
            id: id,
            profileId: profileId,
            kind: kind,
            fromWordIndex: fromWordIndex,
            toWordIndex: toWordIndex,
            skillId: skillId,
            surah: surah,
            origin: origin,
            parentUnitId: parentUnitId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UnitsTableProcessedTableManager = ProcessedTableManager<
    _$SudurDatabase,
    $UnitsTable,
    UnitRecord,
    $$UnitsTableFilterComposer,
    $$UnitsTableOrderingComposer,
    $$UnitsTableAnnotationComposer,
    $$UnitsTableCreateCompanionBuilder,
    $$UnitsTableUpdateCompanionBuilder,
    (UnitRecord, BaseReferences<_$SudurDatabase, $UnitsTable, UnitRecord>),
    UnitRecord,
    PrefetchHooks Function()>;
typedef $$UnitStatesTableCreateCompanionBuilder = UnitStatesCompanion Function({
  required String unitId,
  required UnitQueue queue,
  Value<JsonObjectData?> memoryState,
  Value<JsonObjectData?> fsrsCard,
  Value<int?> dueAt,
  Value<int?> recentSince,
  Value<int?> lastAttemptAt,
  Value<CheckMethod?> lastMethod,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$UnitStatesTableUpdateCompanionBuilder = UnitStatesCompanion Function({
  Value<String> unitId,
  Value<UnitQueue> queue,
  Value<JsonObjectData?> memoryState,
  Value<JsonObjectData?> fsrsCard,
  Value<int?> dueAt,
  Value<int?> recentSince,
  Value<int?> lastAttemptAt,
  Value<CheckMethod?> lastMethod,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$UnitStatesTableFilterComposer
    extends Composer<_$SudurDatabase, $UnitStatesTable> {
  $$UnitStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get unitId => $composableBuilder(
      column: $table.unitId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<UnitQueue, UnitQueue, String> get queue =>
      $composableBuilder(
          column: $table.queue,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<JsonObjectData?, JsonObjectData, String>
      get memoryState => $composableBuilder(
          column: $table.memoryState,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<JsonObjectData?, JsonObjectData, String>
      get fsrsCard => $composableBuilder(
          column: $table.fsrsCard,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get dueAt => $composableBuilder(
      column: $table.dueAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get recentSince => $composableBuilder(
      column: $table.recentSince, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<CheckMethod?, CheckMethod, String>
      get lastMethod => $composableBuilder(
          column: $table.lastMethod,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$UnitStatesTableOrderingComposer
    extends Composer<_$SudurDatabase, $UnitStatesTable> {
  $$UnitStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get unitId => $composableBuilder(
      column: $table.unitId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get queue => $composableBuilder(
      column: $table.queue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memoryState => $composableBuilder(
      column: $table.memoryState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fsrsCard => $composableBuilder(
      column: $table.fsrsCard, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueAt => $composableBuilder(
      column: $table.dueAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recentSince => $composableBuilder(
      column: $table.recentSince, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastMethod => $composableBuilder(
      column: $table.lastMethod, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$UnitStatesTableAnnotationComposer
    extends Composer<_$SudurDatabase, $UnitStatesTable> {
  $$UnitStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UnitQueue, String> get queue =>
      $composableBuilder(column: $table.queue, builder: (column) => column);

  GeneratedColumnWithTypeConverter<JsonObjectData?, String> get memoryState =>
      $composableBuilder(
          column: $table.memoryState, builder: (column) => column);

  GeneratedColumnWithTypeConverter<JsonObjectData?, String> get fsrsCard =>
      $composableBuilder(column: $table.fsrsCard, builder: (column) => column);

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get recentSince => $composableBuilder(
      column: $table.recentSince, builder: (column) => column);

  GeneratedColumn<int> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CheckMethod?, String> get lastMethod =>
      $composableBuilder(
          column: $table.lastMethod, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UnitStatesTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $UnitStatesTable,
    UnitStateRecord,
    $$UnitStatesTableFilterComposer,
    $$UnitStatesTableOrderingComposer,
    $$UnitStatesTableAnnotationComposer,
    $$UnitStatesTableCreateCompanionBuilder,
    $$UnitStatesTableUpdateCompanionBuilder,
    (
      UnitStateRecord,
      BaseReferences<_$SudurDatabase, $UnitStatesTable, UnitStateRecord>
    ),
    UnitStateRecord,
    PrefetchHooks Function()> {
  $$UnitStatesTableTableManager(_$SudurDatabase db, $UnitStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> unitId = const Value.absent(),
            Value<UnitQueue> queue = const Value.absent(),
            Value<JsonObjectData?> memoryState = const Value.absent(),
            Value<JsonObjectData?> fsrsCard = const Value.absent(),
            Value<int?> dueAt = const Value.absent(),
            Value<int?> recentSince = const Value.absent(),
            Value<int?> lastAttemptAt = const Value.absent(),
            Value<CheckMethod?> lastMethod = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitStatesCompanion(
            unitId: unitId,
            queue: queue,
            memoryState: memoryState,
            fsrsCard: fsrsCard,
            dueAt: dueAt,
            recentSince: recentSince,
            lastAttemptAt: lastAttemptAt,
            lastMethod: lastMethod,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String unitId,
            required UnitQueue queue,
            Value<JsonObjectData?> memoryState = const Value.absent(),
            Value<JsonObjectData?> fsrsCard = const Value.absent(),
            Value<int?> dueAt = const Value.absent(),
            Value<int?> recentSince = const Value.absent(),
            Value<int?> lastAttemptAt = const Value.absent(),
            Value<CheckMethod?> lastMethod = const Value.absent(),
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitStatesCompanion.insert(
            unitId: unitId,
            queue: queue,
            memoryState: memoryState,
            fsrsCard: fsrsCard,
            dueAt: dueAt,
            recentSince: recentSince,
            lastAttemptAt: lastAttemptAt,
            lastMethod: lastMethod,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UnitStatesTableProcessedTableManager = ProcessedTableManager<
    _$SudurDatabase,
    $UnitStatesTable,
    UnitStateRecord,
    $$UnitStatesTableFilterComposer,
    $$UnitStatesTableOrderingComposer,
    $$UnitStatesTableAnnotationComposer,
    $$UnitStatesTableCreateCompanionBuilder,
    $$UnitStatesTableUpdateCompanionBuilder,
    (
      UnitStateRecord,
      BaseReferences<_$SudurDatabase, $UnitStatesTable, UnitStateRecord>
    ),
    UnitStateRecord,
    PrefetchHooks Function()>;
typedef $$AttemptsTableCreateCompanionBuilder = AttemptsCompanion Function({
  required String id,
  required String unitId,
  required String sessionId,
  required StoredReadingMode mode,
  required AttemptOutcome outcome,
  required HintCounts hints,
  required ErrorEventIds errorEventIds,
  Value<AttemptRating?> rating,
  required CheckMethod method,
  required int durationMs,
  required int words,
  required String modelId,
  required String modelVersion,
  required String rulesVersion,
  required String textVersion,
  required int createdAt,
  Value<int> rowid,
});
typedef $$AttemptsTableUpdateCompanionBuilder = AttemptsCompanion Function({
  Value<String> id,
  Value<String> unitId,
  Value<String> sessionId,
  Value<StoredReadingMode> mode,
  Value<AttemptOutcome> outcome,
  Value<HintCounts> hints,
  Value<ErrorEventIds> errorEventIds,
  Value<AttemptRating?> rating,
  Value<CheckMethod> method,
  Value<int> durationMs,
  Value<int> words,
  Value<String> modelId,
  Value<String> modelVersion,
  Value<String> rulesVersion,
  Value<String> textVersion,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$AttemptsTableFilterComposer
    extends Composer<_$SudurDatabase, $AttemptsTable> {
  $$AttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitId => $composableBuilder(
      column: $table.unitId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<StoredReadingMode, StoredReadingMode, String>
      get mode => $composableBuilder(
          column: $table.mode,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<AttemptOutcome, AttemptOutcome, String>
      get outcome => $composableBuilder(
          column: $table.outcome,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<HintCounts, HintCounts, String> get hints =>
      $composableBuilder(
          column: $table.hints,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<ErrorEventIds, ErrorEventIds, String>
      get errorEventIds => $composableBuilder(
          column: $table.errorEventIds,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<AttemptRating?, AttemptRating, String>
      get rating => $composableBuilder(
          column: $table.rating,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<CheckMethod, CheckMethod, String> get method =>
      $composableBuilder(
          column: $table.method,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get words => $composableBuilder(
      column: $table.words, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelVersion => $composableBuilder(
      column: $table.modelVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rulesVersion => $composableBuilder(
      column: $table.rulesVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textVersion => $composableBuilder(
      column: $table.textVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AttemptsTableOrderingComposer
    extends Composer<_$SudurDatabase, $AttemptsTable> {
  $$AttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitId => $composableBuilder(
      column: $table.unitId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get outcome => $composableBuilder(
      column: $table.outcome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hints => $composableBuilder(
      column: $table.hints, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorEventIds => $composableBuilder(
      column: $table.errorEventIds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get words => $composableBuilder(
      column: $table.words, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelVersion => $composableBuilder(
      column: $table.modelVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rulesVersion => $composableBuilder(
      column: $table.rulesVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textVersion => $composableBuilder(
      column: $table.textVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AttemptsTableAnnotationComposer
    extends Composer<_$SudurDatabase, $AttemptsTable> {
  $$AttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get unitId =>
      $composableBuilder(column: $table.unitId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<StoredReadingMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AttemptOutcome, String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HintCounts, String> get hints =>
      $composableBuilder(column: $table.hints, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ErrorEventIds, String> get errorEventIds =>
      $composableBuilder(
          column: $table.errorEventIds, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AttemptRating?, String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CheckMethod, String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<int> get words =>
      $composableBuilder(column: $table.words, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<String> get modelVersion => $composableBuilder(
      column: $table.modelVersion, builder: (column) => column);

  GeneratedColumn<String> get rulesVersion => $composableBuilder(
      column: $table.rulesVersion, builder: (column) => column);

  GeneratedColumn<String> get textVersion => $composableBuilder(
      column: $table.textVersion, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AttemptsTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $AttemptsTable,
    AttemptRecord,
    $$AttemptsTableFilterComposer,
    $$AttemptsTableOrderingComposer,
    $$AttemptsTableAnnotationComposer,
    $$AttemptsTableCreateCompanionBuilder,
    $$AttemptsTableUpdateCompanionBuilder,
    (
      AttemptRecord,
      BaseReferences<_$SudurDatabase, $AttemptsTable, AttemptRecord>
    ),
    AttemptRecord,
    PrefetchHooks Function()> {
  $$AttemptsTableTableManager(_$SudurDatabase db, $AttemptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> unitId = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<StoredReadingMode> mode = const Value.absent(),
            Value<AttemptOutcome> outcome = const Value.absent(),
            Value<HintCounts> hints = const Value.absent(),
            Value<ErrorEventIds> errorEventIds = const Value.absent(),
            Value<AttemptRating?> rating = const Value.absent(),
            Value<CheckMethod> method = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<int> words = const Value.absent(),
            Value<String> modelId = const Value.absent(),
            Value<String> modelVersion = const Value.absent(),
            Value<String> rulesVersion = const Value.absent(),
            Value<String> textVersion = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttemptsCompanion(
            id: id,
            unitId: unitId,
            sessionId: sessionId,
            mode: mode,
            outcome: outcome,
            hints: hints,
            errorEventIds: errorEventIds,
            rating: rating,
            method: method,
            durationMs: durationMs,
            words: words,
            modelId: modelId,
            modelVersion: modelVersion,
            rulesVersion: rulesVersion,
            textVersion: textVersion,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String unitId,
            required String sessionId,
            required StoredReadingMode mode,
            required AttemptOutcome outcome,
            required HintCounts hints,
            required ErrorEventIds errorEventIds,
            Value<AttemptRating?> rating = const Value.absent(),
            required CheckMethod method,
            required int durationMs,
            required int words,
            required String modelId,
            required String modelVersion,
            required String rulesVersion,
            required String textVersion,
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AttemptsCompanion.insert(
            id: id,
            unitId: unitId,
            sessionId: sessionId,
            mode: mode,
            outcome: outcome,
            hints: hints,
            errorEventIds: errorEventIds,
            rating: rating,
            method: method,
            durationMs: durationMs,
            words: words,
            modelId: modelId,
            modelVersion: modelVersion,
            rulesVersion: rulesVersion,
            textVersion: textVersion,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AttemptsTableProcessedTableManager = ProcessedTableManager<
    _$SudurDatabase,
    $AttemptsTable,
    AttemptRecord,
    $$AttemptsTableFilterComposer,
    $$AttemptsTableOrderingComposer,
    $$AttemptsTableAnnotationComposer,
    $$AttemptsTableCreateCompanionBuilder,
    $$AttemptsTableUpdateCompanionBuilder,
    (
      AttemptRecord,
      BaseReferences<_$SudurDatabase, $AttemptsTable, AttemptRecord>
    ),
    AttemptRecord,
    PrefetchHooks Function()>;
typedef $$CheckEventsTableCreateCompanionBuilder = CheckEventsCompanion
    Function({
  required String id,
  required String sessionId,
  required CheckKind kind,
  required CheckState state,
  required WordIndexes wordIndexes,
  required String expectedText,
  required String heardText,
  Value<int?> jumpFromWordIndex,
  Value<int?> jumpToWordIndex,
  required int audioStartMs,
  required int audioEndMs,
  required ReadingVersions versions,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$CheckEventsTableUpdateCompanionBuilder = CheckEventsCompanion
    Function({
  Value<String> id,
  Value<String> sessionId,
  Value<CheckKind> kind,
  Value<CheckState> state,
  Value<WordIndexes> wordIndexes,
  Value<String> expectedText,
  Value<String> heardText,
  Value<int?> jumpFromWordIndex,
  Value<int?> jumpToWordIndex,
  Value<int> audioStartMs,
  Value<int> audioEndMs,
  Value<ReadingVersions> versions,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$CheckEventsTableFilterComposer
    extends Composer<_$SudurDatabase, $CheckEventsTable> {
  $$CheckEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<CheckKind, CheckKind, String> get kind =>
      $composableBuilder(
          column: $table.kind,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<CheckState, CheckState, String> get state =>
      $composableBuilder(
          column: $table.state,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<WordIndexes, WordIndexes, String>
      get wordIndexes => $composableBuilder(
          column: $table.wordIndexes,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get expectedText => $composableBuilder(
      column: $table.expectedText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get heardText => $composableBuilder(
      column: $table.heardText, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get jumpFromWordIndex => $composableBuilder(
      column: $table.jumpFromWordIndex,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get jumpToWordIndex => $composableBuilder(
      column: $table.jumpToWordIndex,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get audioStartMs => $composableBuilder(
      column: $table.audioStartMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get audioEndMs => $composableBuilder(
      column: $table.audioEndMs, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ReadingVersions, ReadingVersions, String>
      get versions => $composableBuilder(
          column: $table.versions,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CheckEventsTableOrderingComposer
    extends Composer<_$SudurDatabase, $CheckEventsTable> {
  $$CheckEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wordIndexes => $composableBuilder(
      column: $table.wordIndexes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get expectedText => $composableBuilder(
      column: $table.expectedText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get heardText => $composableBuilder(
      column: $table.heardText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get jumpFromWordIndex => $composableBuilder(
      column: $table.jumpFromWordIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get jumpToWordIndex => $composableBuilder(
      column: $table.jumpToWordIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get audioStartMs => $composableBuilder(
      column: $table.audioStartMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get audioEndMs => $composableBuilder(
      column: $table.audioEndMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get versions => $composableBuilder(
      column: $table.versions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CheckEventsTableAnnotationComposer
    extends Composer<_$SudurDatabase, $CheckEventsTable> {
  $$CheckEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CheckKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CheckState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WordIndexes, String> get wordIndexes =>
      $composableBuilder(
          column: $table.wordIndexes, builder: (column) => column);

  GeneratedColumn<String> get expectedText => $composableBuilder(
      column: $table.expectedText, builder: (column) => column);

  GeneratedColumn<String> get heardText =>
      $composableBuilder(column: $table.heardText, builder: (column) => column);

  GeneratedColumn<int> get jumpFromWordIndex => $composableBuilder(
      column: $table.jumpFromWordIndex, builder: (column) => column);

  GeneratedColumn<int> get jumpToWordIndex => $composableBuilder(
      column: $table.jumpToWordIndex, builder: (column) => column);

  GeneratedColumn<int> get audioStartMs => $composableBuilder(
      column: $table.audioStartMs, builder: (column) => column);

  GeneratedColumn<int> get audioEndMs => $composableBuilder(
      column: $table.audioEndMs, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReadingVersions, String> get versions =>
      $composableBuilder(column: $table.versions, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CheckEventsTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $CheckEventsTable,
    CheckEventRecord,
    $$CheckEventsTableFilterComposer,
    $$CheckEventsTableOrderingComposer,
    $$CheckEventsTableAnnotationComposer,
    $$CheckEventsTableCreateCompanionBuilder,
    $$CheckEventsTableUpdateCompanionBuilder,
    (
      CheckEventRecord,
      BaseReferences<_$SudurDatabase, $CheckEventsTable, CheckEventRecord>
    ),
    CheckEventRecord,
    PrefetchHooks Function()> {
  $$CheckEventsTableTableManager(_$SudurDatabase db, $CheckEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<CheckKind> kind = const Value.absent(),
            Value<CheckState> state = const Value.absent(),
            Value<WordIndexes> wordIndexes = const Value.absent(),
            Value<String> expectedText = const Value.absent(),
            Value<String> heardText = const Value.absent(),
            Value<int?> jumpFromWordIndex = const Value.absent(),
            Value<int?> jumpToWordIndex = const Value.absent(),
            Value<int> audioStartMs = const Value.absent(),
            Value<int> audioEndMs = const Value.absent(),
            Value<ReadingVersions> versions = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CheckEventsCompanion(
            id: id,
            sessionId: sessionId,
            kind: kind,
            state: state,
            wordIndexes: wordIndexes,
            expectedText: expectedText,
            heardText: heardText,
            jumpFromWordIndex: jumpFromWordIndex,
            jumpToWordIndex: jumpToWordIndex,
            audioStartMs: audioStartMs,
            audioEndMs: audioEndMs,
            versions: versions,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sessionId,
            required CheckKind kind,
            required CheckState state,
            required WordIndexes wordIndexes,
            required String expectedText,
            required String heardText,
            Value<int?> jumpFromWordIndex = const Value.absent(),
            Value<int?> jumpToWordIndex = const Value.absent(),
            required int audioStartMs,
            required int audioEndMs,
            required ReadingVersions versions,
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CheckEventsCompanion.insert(
            id: id,
            sessionId: sessionId,
            kind: kind,
            state: state,
            wordIndexes: wordIndexes,
            expectedText: expectedText,
            heardText: heardText,
            jumpFromWordIndex: jumpFromWordIndex,
            jumpToWordIndex: jumpToWordIndex,
            audioStartMs: audioStartMs,
            audioEndMs: audioEndMs,
            versions: versions,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CheckEventsTableProcessedTableManager = ProcessedTableManager<
    _$SudurDatabase,
    $CheckEventsTable,
    CheckEventRecord,
    $$CheckEventsTableFilterComposer,
    $$CheckEventsTableOrderingComposer,
    $$CheckEventsTableAnnotationComposer,
    $$CheckEventsTableCreateCompanionBuilder,
    $$CheckEventsTableUpdateCompanionBuilder,
    (
      CheckEventRecord,
      BaseReferences<_$SudurDatabase, $CheckEventsTable, CheckEventRecord>
    ),
    CheckEventRecord,
    PrefetchHooks Function()>;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  required String profileId,
  required int fromWordIndex,
  required int toWordIndex,
  required StoredReadingMode mode,
  required ReadingBehavior behavior,
  required int startedAt,
  Value<int?> endedAt,
  required int listeningMs,
  Value<double?> signalOkRatio,
  Value<SessionSummary?> summary,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<String> profileId,
  Value<int> fromWordIndex,
  Value<int> toWordIndex,
  Value<StoredReadingMode> mode,
  Value<ReadingBehavior> behavior,
  Value<int> startedAt,
  Value<int?> endedAt,
  Value<int> listeningMs,
  Value<double?> signalOkRatio,
  Value<SessionSummary?> summary,
  Value<int> rowid,
});

class $$SessionsTableFilterComposer
    extends Composer<_$SudurDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fromWordIndex => $composableBuilder(
      column: $table.fromWordIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get toWordIndex => $composableBuilder(
      column: $table.toWordIndex, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<StoredReadingMode, StoredReadingMode, String>
      get mode => $composableBuilder(
          column: $table.mode,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<ReadingBehavior, ReadingBehavior, String>
      get behavior => $composableBuilder(
          column: $table.behavior,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get listeningMs => $composableBuilder(
      column: $table.listeningMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get signalOkRatio => $composableBuilder(
      column: $table.signalOkRatio, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SessionSummary?, SessionSummary, String>
      get summary => $composableBuilder(
          column: $table.summary,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$SessionsTableOrderingComposer
    extends Composer<_$SudurDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fromWordIndex => $composableBuilder(
      column: $table.fromWordIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get toWordIndex => $composableBuilder(
      column: $table.toWordIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get behavior => $composableBuilder(
      column: $table.behavior, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get listeningMs => $composableBuilder(
      column: $table.listeningMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get signalOkRatio => $composableBuilder(
      column: $table.signalOkRatio,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$SudurDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<int> get fromWordIndex => $composableBuilder(
      column: $table.fromWordIndex, builder: (column) => column);

  GeneratedColumn<int> get toWordIndex => $composableBuilder(
      column: $table.toWordIndex, builder: (column) => column);

  GeneratedColumnWithTypeConverter<StoredReadingMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReadingBehavior, String> get behavior =>
      $composableBuilder(column: $table.behavior, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get listeningMs => $composableBuilder(
      column: $table.listeningMs, builder: (column) => column);

  GeneratedColumn<double> get signalOkRatio => $composableBuilder(
      column: $table.signalOkRatio, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionSummary?, String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);
}

class $$SessionsTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $SessionsTable,
    SessionRecord,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (
      SessionRecord,
      BaseReferences<_$SudurDatabase, $SessionsTable, SessionRecord>
    ),
    SessionRecord,
    PrefetchHooks Function()> {
  $$SessionsTableTableManager(_$SudurDatabase db, $SessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<int> fromWordIndex = const Value.absent(),
            Value<int> toWordIndex = const Value.absent(),
            Value<StoredReadingMode> mode = const Value.absent(),
            Value<ReadingBehavior> behavior = const Value.absent(),
            Value<int> startedAt = const Value.absent(),
            Value<int?> endedAt = const Value.absent(),
            Value<int> listeningMs = const Value.absent(),
            Value<double?> signalOkRatio = const Value.absent(),
            Value<SessionSummary?> summary = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionsCompanion(
            id: id,
            profileId: profileId,
            fromWordIndex: fromWordIndex,
            toWordIndex: toWordIndex,
            mode: mode,
            behavior: behavior,
            startedAt: startedAt,
            endedAt: endedAt,
            listeningMs: listeningMs,
            signalOkRatio: signalOkRatio,
            summary: summary,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String profileId,
            required int fromWordIndex,
            required int toWordIndex,
            required StoredReadingMode mode,
            required ReadingBehavior behavior,
            required int startedAt,
            Value<int?> endedAt = const Value.absent(),
            required int listeningMs,
            Value<double?> signalOkRatio = const Value.absent(),
            Value<SessionSummary?> summary = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionsCompanion.insert(
            id: id,
            profileId: profileId,
            fromWordIndex: fromWordIndex,
            toWordIndex: toWordIndex,
            mode: mode,
            behavior: behavior,
            startedAt: startedAt,
            endedAt: endedAt,
            listeningMs: listeningMs,
            signalOkRatio: signalOkRatio,
            summary: summary,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SessionsTableProcessedTableManager = ProcessedTableManager<
    _$SudurDatabase,
    $SessionsTable,
    SessionRecord,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (
      SessionRecord,
      BaseReferences<_$SudurDatabase, $SessionsTable, SessionRecord>
    ),
    SessionRecord,
    PrefetchHooks Function()>;
typedef $$DailyPlansTableCreateCompanionBuilder = DailyPlansCompanion Function({
  required String date,
  required DailyPlanItems items,
  required int createdAt,
  Value<int> rowid,
});
typedef $$DailyPlansTableUpdateCompanionBuilder = DailyPlansCompanion Function({
  Value<String> date,
  Value<DailyPlanItems> items,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$DailyPlansTableFilterComposer
    extends Composer<_$SudurDatabase, $DailyPlansTable> {
  $$DailyPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DailyPlanItems, DailyPlanItems, String>
      get items => $composableBuilder(
          column: $table.items,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$DailyPlansTableOrderingComposer
    extends Composer<_$SudurDatabase, $DailyPlansTable> {
  $$DailyPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get items => $composableBuilder(
      column: $table.items, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$DailyPlansTableAnnotationComposer
    extends Composer<_$SudurDatabase, $DailyPlansTable> {
  $$DailyPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DailyPlanItems, String> get items =>
      $composableBuilder(column: $table.items, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DailyPlansTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $DailyPlansTable,
    DailyPlanRecord,
    $$DailyPlansTableFilterComposer,
    $$DailyPlansTableOrderingComposer,
    $$DailyPlansTableAnnotationComposer,
    $$DailyPlansTableCreateCompanionBuilder,
    $$DailyPlansTableUpdateCompanionBuilder,
    (
      DailyPlanRecord,
      BaseReferences<_$SudurDatabase, $DailyPlansTable, DailyPlanRecord>
    ),
    DailyPlanRecord,
    PrefetchHooks Function()> {
  $$DailyPlansTableTableManager(_$SudurDatabase db, $DailyPlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> date = const Value.absent(),
            Value<DailyPlanItems> items = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyPlansCompanion(
            date: date,
            items: items,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String date,
            required DailyPlanItems items,
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyPlansCompanion.insert(
            date: date,
            items: items,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyPlansTableProcessedTableManager = ProcessedTableManager<
    _$SudurDatabase,
    $DailyPlansTable,
    DailyPlanRecord,
    $$DailyPlansTableFilterComposer,
    $$DailyPlansTableOrderingComposer,
    $$DailyPlansTableAnnotationComposer,
    $$DailyPlansTableCreateCompanionBuilder,
    $$DailyPlansTableUpdateCompanionBuilder,
    (
      DailyPlanRecord,
      BaseReferences<_$SudurDatabase, $DailyPlansTable, DailyPlanRecord>
    ),
    DailyPlanRecord,
    PrefetchHooks Function()>;
typedef $$LessonProgressEntriesTableCreateCompanionBuilder
    = LessonProgressEntriesCompanion Function({
  required String lessonId,
  required LessonState state,
  required int stepIndex,
  required int quizPercent,
  required String contentVersion,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$LessonProgressEntriesTableUpdateCompanionBuilder
    = LessonProgressEntriesCompanion Function({
  Value<String> lessonId,
  Value<LessonState> state,
  Value<int> stepIndex,
  Value<int> quizPercent,
  Value<String> contentVersion,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$LessonProgressEntriesTableFilterComposer
    extends Composer<_$SudurDatabase, $LessonProgressEntriesTable> {
  $$LessonProgressEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lessonId => $composableBuilder(
      column: $table.lessonId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<LessonState, LessonState, String> get state =>
      $composableBuilder(
          column: $table.state,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get stepIndex => $composableBuilder(
      column: $table.stepIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quizPercent => $composableBuilder(
      column: $table.quizPercent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LessonProgressEntriesTableOrderingComposer
    extends Composer<_$SudurDatabase, $LessonProgressEntriesTable> {
  $$LessonProgressEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lessonId => $composableBuilder(
      column: $table.lessonId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stepIndex => $composableBuilder(
      column: $table.stepIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quizPercent => $composableBuilder(
      column: $table.quizPercent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LessonProgressEntriesTableAnnotationComposer
    extends Composer<_$SudurDatabase, $LessonProgressEntriesTable> {
  $$LessonProgressEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LessonState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get stepIndex =>
      $composableBuilder(column: $table.stepIndex, builder: (column) => column);

  GeneratedColumn<int> get quizPercent => $composableBuilder(
      column: $table.quizPercent, builder: (column) => column);

  GeneratedColumn<String> get contentVersion => $composableBuilder(
      column: $table.contentVersion, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LessonProgressEntriesTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $LessonProgressEntriesTable,
    LessonProgressRecord,
    $$LessonProgressEntriesTableFilterComposer,
    $$LessonProgressEntriesTableOrderingComposer,
    $$LessonProgressEntriesTableAnnotationComposer,
    $$LessonProgressEntriesTableCreateCompanionBuilder,
    $$LessonProgressEntriesTableUpdateCompanionBuilder,
    (
      LessonProgressRecord,
      BaseReferences<_$SudurDatabase, $LessonProgressEntriesTable,
          LessonProgressRecord>
    ),
    LessonProgressRecord,
    PrefetchHooks Function()> {
  $$LessonProgressEntriesTableTableManager(
      _$SudurDatabase db, $LessonProgressEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonProgressEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonProgressEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonProgressEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> lessonId = const Value.absent(),
            Value<LessonState> state = const Value.absent(),
            Value<int> stepIndex = const Value.absent(),
            Value<int> quizPercent = const Value.absent(),
            Value<String> contentVersion = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonProgressEntriesCompanion(
            lessonId: lessonId,
            state: state,
            stepIndex: stepIndex,
            quizPercent: quizPercent,
            contentVersion: contentVersion,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String lessonId,
            required LessonState state,
            required int stepIndex,
            required int quizPercent,
            required String contentVersion,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonProgressEntriesCompanion.insert(
            lessonId: lessonId,
            state: state,
            stepIndex: stepIndex,
            quizPercent: quizPercent,
            contentVersion: contentVersion,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LessonProgressEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$SudurDatabase,
        $LessonProgressEntriesTable,
        LessonProgressRecord,
        $$LessonProgressEntriesTableFilterComposer,
        $$LessonProgressEntriesTableOrderingComposer,
        $$LessonProgressEntriesTableAnnotationComposer,
        $$LessonProgressEntriesTableCreateCompanionBuilder,
        $$LessonProgressEntriesTableUpdateCompanionBuilder,
        (
          LessonProgressRecord,
          BaseReferences<_$SudurDatabase, $LessonProgressEntriesTable,
              LessonProgressRecord>
        ),
        LessonProgressRecord,
        PrefetchHooks Function()>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required JsonValueData value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<JsonValueData> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$SudurDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<JsonValueData, JsonValueData, String>
      get value => $composableBuilder(
          column: $table.value,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$SudurDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$SudurDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumnWithTypeConverter<JsonValueData, String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $SettingsTable,
    SettingRecord,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (
      SettingRecord,
      BaseReferences<_$SudurDatabase, $SettingsTable, SettingRecord>
    ),
    SettingRecord,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$SudurDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<JsonValueData> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required JsonValueData value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$SudurDatabase,
    $SettingsTable,
    SettingRecord,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (
      SettingRecord,
      BaseReferences<_$SudurDatabase, $SettingsTable, SettingRecord>
    ),
    SettingRecord,
    PrefetchHooks Function()>;
typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  required String packageId,
  required DownloadKind kind,
  Value<String?> activeVersion,
  Value<String?> pendingVersion,
  required DownloadState state,
  required int bytesTotal,
  required int bytesDone,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<String> packageId,
  Value<DownloadKind> kind,
  Value<String?> activeVersion,
  Value<String?> pendingVersion,
  Value<DownloadState> state,
  Value<int> bytesTotal,
  Value<int> bytesDone,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$DownloadsTableFilterComposer
    extends Composer<_$SudurDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get packageId => $composableBuilder(
      column: $table.packageId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DownloadKind, DownloadKind, String> get kind =>
      $composableBuilder(
          column: $table.kind,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get activeVersion => $composableBuilder(
      column: $table.activeVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pendingVersion => $composableBuilder(
      column: $table.pendingVersion,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DownloadState, DownloadState, String>
      get state => $composableBuilder(
          column: $table.state,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get bytesTotal => $composableBuilder(
      column: $table.bytesTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bytesDone => $composableBuilder(
      column: $table.bytesDone, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DownloadsTableOrderingComposer
    extends Composer<_$SudurDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get packageId => $composableBuilder(
      column: $table.packageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activeVersion => $composableBuilder(
      column: $table.activeVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pendingVersion => $composableBuilder(
      column: $table.pendingVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bytesTotal => $composableBuilder(
      column: $table.bytesTotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bytesDone => $composableBuilder(
      column: $table.bytesDone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DownloadsTableAnnotationComposer
    extends Composer<_$SudurDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get packageId =>
      $composableBuilder(column: $table.packageId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DownloadKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get activeVersion => $composableBuilder(
      column: $table.activeVersion, builder: (column) => column);

  GeneratedColumn<String> get pendingVersion => $composableBuilder(
      column: $table.pendingVersion, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DownloadState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get bytesTotal => $composableBuilder(
      column: $table.bytesTotal, builder: (column) => column);

  GeneratedColumn<int> get bytesDone =>
      $composableBuilder(column: $table.bytesDone, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DownloadsTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $DownloadsTable,
    DownloadRecord,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableAnnotationComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (
      DownloadRecord,
      BaseReferences<_$SudurDatabase, $DownloadsTable, DownloadRecord>
    ),
    DownloadRecord,
    PrefetchHooks Function()> {
  $$DownloadsTableTableManager(_$SudurDatabase db, $DownloadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> packageId = const Value.absent(),
            Value<DownloadKind> kind = const Value.absent(),
            Value<String?> activeVersion = const Value.absent(),
            Value<String?> pendingVersion = const Value.absent(),
            Value<DownloadState> state = const Value.absent(),
            Value<int> bytesTotal = const Value.absent(),
            Value<int> bytesDone = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadsCompanion(
            packageId: packageId,
            kind: kind,
            activeVersion: activeVersion,
            pendingVersion: pendingVersion,
            state: state,
            bytesTotal: bytesTotal,
            bytesDone: bytesDone,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String packageId,
            required DownloadKind kind,
            Value<String?> activeVersion = const Value.absent(),
            Value<String?> pendingVersion = const Value.absent(),
            required DownloadState state,
            required int bytesTotal,
            required int bytesDone,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DownloadsCompanion.insert(
            packageId: packageId,
            kind: kind,
            activeVersion: activeVersion,
            pendingVersion: pendingVersion,
            state: state,
            bytesTotal: bytesTotal,
            bytesDone: bytesDone,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DownloadsTableProcessedTableManager = ProcessedTableManager<
    _$SudurDatabase,
    $DownloadsTable,
    DownloadRecord,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableAnnotationComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (
      DownloadRecord,
      BaseReferences<_$SudurDatabase, $DownloadsTable, DownloadRecord>
    ),
    DownloadRecord,
    PrefetchHooks Function()>;
typedef $$SearchKeyCacheEntriesTableCreateCompanionBuilder
    = SearchKeyCacheEntriesCompanion Function({
  required String normalizerId,
  required int wordIndex,
  required String key,
  Value<int> rowid,
});
typedef $$SearchKeyCacheEntriesTableUpdateCompanionBuilder
    = SearchKeyCacheEntriesCompanion Function({
  Value<String> normalizerId,
  Value<int> wordIndex,
  Value<String> key,
  Value<int> rowid,
});

class $$SearchKeyCacheEntriesTableFilterComposer
    extends Composer<_$SudurDatabase, $SearchKeyCacheEntriesTable> {
  $$SearchKeyCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get normalizerId => $composableBuilder(
      column: $table.normalizerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get wordIndex => $composableBuilder(
      column: $table.wordIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));
}

class $$SearchKeyCacheEntriesTableOrderingComposer
    extends Composer<_$SudurDatabase, $SearchKeyCacheEntriesTable> {
  $$SearchKeyCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get normalizerId => $composableBuilder(
      column: $table.normalizerId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get wordIndex => $composableBuilder(
      column: $table.wordIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));
}

class $$SearchKeyCacheEntriesTableAnnotationComposer
    extends Composer<_$SudurDatabase, $SearchKeyCacheEntriesTable> {
  $$SearchKeyCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get normalizerId => $composableBuilder(
      column: $table.normalizerId, builder: (column) => column);

  GeneratedColumn<int> get wordIndex =>
      $composableBuilder(column: $table.wordIndex, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);
}

class $$SearchKeyCacheEntriesTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $SearchKeyCacheEntriesTable,
    SearchKeyCacheRecord,
    $$SearchKeyCacheEntriesTableFilterComposer,
    $$SearchKeyCacheEntriesTableOrderingComposer,
    $$SearchKeyCacheEntriesTableAnnotationComposer,
    $$SearchKeyCacheEntriesTableCreateCompanionBuilder,
    $$SearchKeyCacheEntriesTableUpdateCompanionBuilder,
    (
      SearchKeyCacheRecord,
      BaseReferences<_$SudurDatabase, $SearchKeyCacheEntriesTable,
          SearchKeyCacheRecord>
    ),
    SearchKeyCacheRecord,
    PrefetchHooks Function()> {
  $$SearchKeyCacheEntriesTableTableManager(
      _$SudurDatabase db, $SearchKeyCacheEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchKeyCacheEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchKeyCacheEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchKeyCacheEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> normalizerId = const Value.absent(),
            Value<int> wordIndex = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SearchKeyCacheEntriesCompanion(
            normalizerId: normalizerId,
            wordIndex: wordIndex,
            key: key,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String normalizerId,
            required int wordIndex,
            required String key,
            Value<int> rowid = const Value.absent(),
          }) =>
              SearchKeyCacheEntriesCompanion.insert(
            normalizerId: normalizerId,
            wordIndex: wordIndex,
            key: key,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SearchKeyCacheEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$SudurDatabase,
        $SearchKeyCacheEntriesTable,
        SearchKeyCacheRecord,
        $$SearchKeyCacheEntriesTableFilterComposer,
        $$SearchKeyCacheEntriesTableOrderingComposer,
        $$SearchKeyCacheEntriesTableAnnotationComposer,
        $$SearchKeyCacheEntriesTableCreateCompanionBuilder,
        $$SearchKeyCacheEntriesTableUpdateCompanionBuilder,
        (
          SearchKeyCacheRecord,
          BaseReferences<_$SudurDatabase, $SearchKeyCacheEntriesTable,
              SearchKeyCacheRecord>
        ),
        SearchKeyCacheRecord,
        PrefetchHooks Function()>;
typedef $$NgramCacheEntriesTableCreateCompanionBuilder
    = NgramCacheEntriesCompanion Function({
  required String normalizerId,
  required String ngram,
  required WordIndexes wordIndexes,
  Value<int> rowid,
});
typedef $$NgramCacheEntriesTableUpdateCompanionBuilder
    = NgramCacheEntriesCompanion Function({
  Value<String> normalizerId,
  Value<String> ngram,
  Value<WordIndexes> wordIndexes,
  Value<int> rowid,
});

class $$NgramCacheEntriesTableFilterComposer
    extends Composer<_$SudurDatabase, $NgramCacheEntriesTable> {
  $$NgramCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get normalizerId => $composableBuilder(
      column: $table.normalizerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ngram => $composableBuilder(
      column: $table.ngram, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<WordIndexes, WordIndexes, String>
      get wordIndexes => $composableBuilder(
          column: $table.wordIndexes,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$NgramCacheEntriesTableOrderingComposer
    extends Composer<_$SudurDatabase, $NgramCacheEntriesTable> {
  $$NgramCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get normalizerId => $composableBuilder(
      column: $table.normalizerId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ngram => $composableBuilder(
      column: $table.ngram, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wordIndexes => $composableBuilder(
      column: $table.wordIndexes, builder: (column) => ColumnOrderings(column));
}

class $$NgramCacheEntriesTableAnnotationComposer
    extends Composer<_$SudurDatabase, $NgramCacheEntriesTable> {
  $$NgramCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get normalizerId => $composableBuilder(
      column: $table.normalizerId, builder: (column) => column);

  GeneratedColumn<String> get ngram =>
      $composableBuilder(column: $table.ngram, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WordIndexes, String> get wordIndexes =>
      $composableBuilder(
          column: $table.wordIndexes, builder: (column) => column);
}

class $$NgramCacheEntriesTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $NgramCacheEntriesTable,
    NgramCacheRecord,
    $$NgramCacheEntriesTableFilterComposer,
    $$NgramCacheEntriesTableOrderingComposer,
    $$NgramCacheEntriesTableAnnotationComposer,
    $$NgramCacheEntriesTableCreateCompanionBuilder,
    $$NgramCacheEntriesTableUpdateCompanionBuilder,
    (
      NgramCacheRecord,
      BaseReferences<_$SudurDatabase, $NgramCacheEntriesTable, NgramCacheRecord>
    ),
    NgramCacheRecord,
    PrefetchHooks Function()> {
  $$NgramCacheEntriesTableTableManager(
      _$SudurDatabase db, $NgramCacheEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NgramCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NgramCacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NgramCacheEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> normalizerId = const Value.absent(),
            Value<String> ngram = const Value.absent(),
            Value<WordIndexes> wordIndexes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NgramCacheEntriesCompanion(
            normalizerId: normalizerId,
            ngram: ngram,
            wordIndexes: wordIndexes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String normalizerId,
            required String ngram,
            required WordIndexes wordIndexes,
            Value<int> rowid = const Value.absent(),
          }) =>
              NgramCacheEntriesCompanion.insert(
            normalizerId: normalizerId,
            ngram: ngram,
            wordIndexes: wordIndexes,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NgramCacheEntriesTableProcessedTableManager = ProcessedTableManager<
    _$SudurDatabase,
    $NgramCacheEntriesTable,
    NgramCacheRecord,
    $$NgramCacheEntriesTableFilterComposer,
    $$NgramCacheEntriesTableOrderingComposer,
    $$NgramCacheEntriesTableAnnotationComposer,
    $$NgramCacheEntriesTableCreateCompanionBuilder,
    $$NgramCacheEntriesTableUpdateCompanionBuilder,
    (
      NgramCacheRecord,
      BaseReferences<_$SudurDatabase, $NgramCacheEntriesTable, NgramCacheRecord>
    ),
    NgramCacheRecord,
    PrefetchHooks Function()>;
typedef $$SavedRecordingsTableCreateCompanionBuilder = SavedRecordingsCompanion
    Function({
  required String id,
  required String sessionId,
  required String path,
  required int durationMs,
  required int createdAt,
  Value<int> rowid,
});
typedef $$SavedRecordingsTableUpdateCompanionBuilder = SavedRecordingsCompanion
    Function({
  Value<String> id,
  Value<String> sessionId,
  Value<String> path,
  Value<int> durationMs,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$SavedRecordingsTableFilterComposer
    extends Composer<_$SudurDatabase, $SavedRecordingsTable> {
  $$SavedRecordingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SavedRecordingsTableOrderingComposer
    extends Composer<_$SudurDatabase, $SavedRecordingsTable> {
  $$SavedRecordingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SavedRecordingsTableAnnotationComposer
    extends Composer<_$SudurDatabase, $SavedRecordingsTable> {
  $$SavedRecordingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SavedRecordingsTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $SavedRecordingsTable,
    SavedRecordingRecord,
    $$SavedRecordingsTableFilterComposer,
    $$SavedRecordingsTableOrderingComposer,
    $$SavedRecordingsTableAnnotationComposer,
    $$SavedRecordingsTableCreateCompanionBuilder,
    $$SavedRecordingsTableUpdateCompanionBuilder,
    (
      SavedRecordingRecord,
      BaseReferences<_$SudurDatabase, $SavedRecordingsTable,
          SavedRecordingRecord>
    ),
    SavedRecordingRecord,
    PrefetchHooks Function()> {
  $$SavedRecordingsTableTableManager(
      _$SudurDatabase db, $SavedRecordingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedRecordingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedRecordingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedRecordingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SavedRecordingsCompanion(
            id: id,
            sessionId: sessionId,
            path: path,
            durationMs: durationMs,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sessionId,
            required String path,
            required int durationMs,
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SavedRecordingsCompanion.insert(
            id: id,
            sessionId: sessionId,
            path: path,
            durationMs: durationMs,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SavedRecordingsTableProcessedTableManager = ProcessedTableManager<
    _$SudurDatabase,
    $SavedRecordingsTable,
    SavedRecordingRecord,
    $$SavedRecordingsTableFilterComposer,
    $$SavedRecordingsTableOrderingComposer,
    $$SavedRecordingsTableAnnotationComposer,
    $$SavedRecordingsTableCreateCompanionBuilder,
    $$SavedRecordingsTableUpdateCompanionBuilder,
    (
      SavedRecordingRecord,
      BaseReferences<_$SudurDatabase, $SavedRecordingsTable,
          SavedRecordingRecord>
    ),
    SavedRecordingRecord,
    PrefetchHooks Function()>;
typedef $$UploadQueueEntriesTableCreateCompanionBuilder
    = UploadQueueEntriesCompanion Function({
  required String id,
  required String sessionId,
  required String filePath,
  required UploadMetadata meta,
  required int priority,
  required int bytes,
  required UploadState state,
  required int tries,
  required int createdAt,
  Value<int> rowid,
});
typedef $$UploadQueueEntriesTableUpdateCompanionBuilder
    = UploadQueueEntriesCompanion Function({
  Value<String> id,
  Value<String> sessionId,
  Value<String> filePath,
  Value<UploadMetadata> meta,
  Value<int> priority,
  Value<int> bytes,
  Value<UploadState> state,
  Value<int> tries,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$UploadQueueEntriesTableFilterComposer
    extends Composer<_$SudurDatabase, $UploadQueueEntriesTable> {
  $$UploadQueueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<UploadMetadata, UploadMetadata, String>
      get meta => $composableBuilder(
          column: $table.meta,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bytes => $composableBuilder(
      column: $table.bytes, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<UploadState, UploadState, String> get state =>
      $composableBuilder(
          column: $table.state,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get tries => $composableBuilder(
      column: $table.tries, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$UploadQueueEntriesTableOrderingComposer
    extends Composer<_$SudurDatabase, $UploadQueueEntriesTable> {
  $$UploadQueueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meta => $composableBuilder(
      column: $table.meta, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bytes => $composableBuilder(
      column: $table.bytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tries => $composableBuilder(
      column: $table.tries, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$UploadQueueEntriesTableAnnotationComposer
    extends Composer<_$SudurDatabase, $UploadQueueEntriesTable> {
  $$UploadQueueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UploadMetadata, String> get meta =>
      $composableBuilder(column: $table.meta, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UploadState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get tries =>
      $composableBuilder(column: $table.tries, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UploadQueueEntriesTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $UploadQueueEntriesTable,
    UploadQueueRecord,
    $$UploadQueueEntriesTableFilterComposer,
    $$UploadQueueEntriesTableOrderingComposer,
    $$UploadQueueEntriesTableAnnotationComposer,
    $$UploadQueueEntriesTableCreateCompanionBuilder,
    $$UploadQueueEntriesTableUpdateCompanionBuilder,
    (
      UploadQueueRecord,
      BaseReferences<_$SudurDatabase, $UploadQueueEntriesTable,
          UploadQueueRecord>
    ),
    UploadQueueRecord,
    PrefetchHooks Function()> {
  $$UploadQueueEntriesTableTableManager(
      _$SudurDatabase db, $UploadQueueEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UploadQueueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UploadQueueEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UploadQueueEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<UploadMetadata> meta = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<int> bytes = const Value.absent(),
            Value<UploadState> state = const Value.absent(),
            Value<int> tries = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UploadQueueEntriesCompanion(
            id: id,
            sessionId: sessionId,
            filePath: filePath,
            meta: meta,
            priority: priority,
            bytes: bytes,
            state: state,
            tries: tries,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sessionId,
            required String filePath,
            required UploadMetadata meta,
            required int priority,
            required int bytes,
            required UploadState state,
            required int tries,
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              UploadQueueEntriesCompanion.insert(
            id: id,
            sessionId: sessionId,
            filePath: filePath,
            meta: meta,
            priority: priority,
            bytes: bytes,
            state: state,
            tries: tries,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UploadQueueEntriesTableProcessedTableManager = ProcessedTableManager<
    _$SudurDatabase,
    $UploadQueueEntriesTable,
    UploadQueueRecord,
    $$UploadQueueEntriesTableFilterComposer,
    $$UploadQueueEntriesTableOrderingComposer,
    $$UploadQueueEntriesTableAnnotationComposer,
    $$UploadQueueEntriesTableCreateCompanionBuilder,
    $$UploadQueueEntriesTableUpdateCompanionBuilder,
    (
      UploadQueueRecord,
      BaseReferences<_$SudurDatabase, $UploadQueueEntriesTable,
          UploadQueueRecord>
    ),
    UploadQueueRecord,
    PrefetchHooks Function()>;
typedef $$EntitlementCacheEntriesTableCreateCompanionBuilder
    = EntitlementCacheEntriesCompanion Function({
  required String id,
  required EntitlementState state,
  Value<int?> expiresAt,
  required int lastVerifiedAt,
  Value<int> rowid,
});
typedef $$EntitlementCacheEntriesTableUpdateCompanionBuilder
    = EntitlementCacheEntriesCompanion Function({
  Value<String> id,
  Value<EntitlementState> state,
  Value<int?> expiresAt,
  Value<int> lastVerifiedAt,
  Value<int> rowid,
});

class $$EntitlementCacheEntriesTableFilterComposer
    extends Composer<_$SudurDatabase, $EntitlementCacheEntriesTable> {
  $$EntitlementCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<EntitlementState, EntitlementState, String>
      get state => $composableBuilder(
          column: $table.state,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastVerifiedAt => $composableBuilder(
      column: $table.lastVerifiedAt,
      builder: (column) => ColumnFilters(column));
}

class $$EntitlementCacheEntriesTableOrderingComposer
    extends Composer<_$SudurDatabase, $EntitlementCacheEntriesTable> {
  $$EntitlementCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastVerifiedAt => $composableBuilder(
      column: $table.lastVerifiedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$EntitlementCacheEntriesTableAnnotationComposer
    extends Composer<_$SudurDatabase, $EntitlementCacheEntriesTable> {
  $$EntitlementCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EntitlementState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<int> get lastVerifiedAt => $composableBuilder(
      column: $table.lastVerifiedAt, builder: (column) => column);
}

class $$EntitlementCacheEntriesTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $EntitlementCacheEntriesTable,
    EntitlementCacheRecord,
    $$EntitlementCacheEntriesTableFilterComposer,
    $$EntitlementCacheEntriesTableOrderingComposer,
    $$EntitlementCacheEntriesTableAnnotationComposer,
    $$EntitlementCacheEntriesTableCreateCompanionBuilder,
    $$EntitlementCacheEntriesTableUpdateCompanionBuilder,
    (
      EntitlementCacheRecord,
      BaseReferences<_$SudurDatabase, $EntitlementCacheEntriesTable,
          EntitlementCacheRecord>
    ),
    EntitlementCacheRecord,
    PrefetchHooks Function()> {
  $$EntitlementCacheEntriesTableTableManager(
      _$SudurDatabase db, $EntitlementCacheEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntitlementCacheEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$EntitlementCacheEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntitlementCacheEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<EntitlementState> state = const Value.absent(),
            Value<int?> expiresAt = const Value.absent(),
            Value<int> lastVerifiedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EntitlementCacheEntriesCompanion(
            id: id,
            state: state,
            expiresAt: expiresAt,
            lastVerifiedAt: lastVerifiedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required EntitlementState state,
            Value<int?> expiresAt = const Value.absent(),
            required int lastVerifiedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              EntitlementCacheEntriesCompanion.insert(
            id: id,
            state: state,
            expiresAt: expiresAt,
            lastVerifiedAt: lastVerifiedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EntitlementCacheEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$SudurDatabase,
        $EntitlementCacheEntriesTable,
        EntitlementCacheRecord,
        $$EntitlementCacheEntriesTableFilterComposer,
        $$EntitlementCacheEntriesTableOrderingComposer,
        $$EntitlementCacheEntriesTableAnnotationComposer,
        $$EntitlementCacheEntriesTableCreateCompanionBuilder,
        $$EntitlementCacheEntriesTableUpdateCompanionBuilder,
        (
          EntitlementCacheRecord,
          BaseReferences<_$SudurDatabase, $EntitlementCacheEntriesTable,
              EntitlementCacheRecord>
        ),
        EntitlementCacheRecord,
        PrefetchHooks Function()>;
typedef $$FreeUsageEntriesTableCreateCompanionBuilder
    = FreeUsageEntriesCompanion Function({
  required String date,
  required int listeningMs,
  Value<int> rowid,
});
typedef $$FreeUsageEntriesTableUpdateCompanionBuilder
    = FreeUsageEntriesCompanion Function({
  Value<String> date,
  Value<int> listeningMs,
  Value<int> rowid,
});

class $$FreeUsageEntriesTableFilterComposer
    extends Composer<_$SudurDatabase, $FreeUsageEntriesTable> {
  $$FreeUsageEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get listeningMs => $composableBuilder(
      column: $table.listeningMs, builder: (column) => ColumnFilters(column));
}

class $$FreeUsageEntriesTableOrderingComposer
    extends Composer<_$SudurDatabase, $FreeUsageEntriesTable> {
  $$FreeUsageEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get listeningMs => $composableBuilder(
      column: $table.listeningMs, builder: (column) => ColumnOrderings(column));
}

class $$FreeUsageEntriesTableAnnotationComposer
    extends Composer<_$SudurDatabase, $FreeUsageEntriesTable> {
  $$FreeUsageEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get listeningMs => $composableBuilder(
      column: $table.listeningMs, builder: (column) => column);
}

class $$FreeUsageEntriesTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $FreeUsageEntriesTable,
    FreeUsageRecord,
    $$FreeUsageEntriesTableFilterComposer,
    $$FreeUsageEntriesTableOrderingComposer,
    $$FreeUsageEntriesTableAnnotationComposer,
    $$FreeUsageEntriesTableCreateCompanionBuilder,
    $$FreeUsageEntriesTableUpdateCompanionBuilder,
    (
      FreeUsageRecord,
      BaseReferences<_$SudurDatabase, $FreeUsageEntriesTable, FreeUsageRecord>
    ),
    FreeUsageRecord,
    PrefetchHooks Function()> {
  $$FreeUsageEntriesTableTableManager(
      _$SudurDatabase db, $FreeUsageEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FreeUsageEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FreeUsageEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FreeUsageEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> date = const Value.absent(),
            Value<int> listeningMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FreeUsageEntriesCompanion(
            date: date,
            listeningMs: listeningMs,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String date,
            required int listeningMs,
            Value<int> rowid = const Value.absent(),
          }) =>
              FreeUsageEntriesCompanion.insert(
            date: date,
            listeningMs: listeningMs,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FreeUsageEntriesTableProcessedTableManager = ProcessedTableManager<
    _$SudurDatabase,
    $FreeUsageEntriesTable,
    FreeUsageRecord,
    $$FreeUsageEntriesTableFilterComposer,
    $$FreeUsageEntriesTableOrderingComposer,
    $$FreeUsageEntriesTableAnnotationComposer,
    $$FreeUsageEntriesTableCreateCompanionBuilder,
    $$FreeUsageEntriesTableUpdateCompanionBuilder,
    (
      FreeUsageRecord,
      BaseReferences<_$SudurDatabase, $FreeUsageEntriesTable, FreeUsageRecord>
    ),
    FreeUsageRecord,
    PrefetchHooks Function()>;
typedef $$OutboxEntriesTableCreateCompanionBuilder = OutboxEntriesCompanion
    Function({
  required String id,
  required JsonObjectData event,
  required int createdAt,
  Value<int> rowid,
});
typedef $$OutboxEntriesTableUpdateCompanionBuilder = OutboxEntriesCompanion
    Function({
  Value<String> id,
  Value<JsonObjectData> event,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$OutboxEntriesTableFilterComposer
    extends Composer<_$SudurDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<JsonObjectData, JsonObjectData, String>
      get event => $composableBuilder(
          column: $table.event,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$OutboxEntriesTableOrderingComposer
    extends Composer<_$SudurDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get event => $composableBuilder(
      column: $table.event, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$OutboxEntriesTableAnnotationComposer
    extends Composer<_$SudurDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<JsonObjectData, String> get event =>
      $composableBuilder(column: $table.event, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxEntriesTableTableManager extends RootTableManager<
    _$SudurDatabase,
    $OutboxEntriesTable,
    OutboxRecord,
    $$OutboxEntriesTableFilterComposer,
    $$OutboxEntriesTableOrderingComposer,
    $$OutboxEntriesTableAnnotationComposer,
    $$OutboxEntriesTableCreateCompanionBuilder,
    $$OutboxEntriesTableUpdateCompanionBuilder,
    (
      OutboxRecord,
      BaseReferences<_$SudurDatabase, $OutboxEntriesTable, OutboxRecord>
    ),
    OutboxRecord,
    PrefetchHooks Function()> {
  $$OutboxEntriesTableTableManager(
      _$SudurDatabase db, $OutboxEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<JsonObjectData> event = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxEntriesCompanion(
            id: id,
            event: event,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required JsonObjectData event,
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              OutboxEntriesCompanion.insert(
            id: id,
            event: event,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OutboxEntriesTableProcessedTableManager = ProcessedTableManager<
    _$SudurDatabase,
    $OutboxEntriesTable,
    OutboxRecord,
    $$OutboxEntriesTableFilterComposer,
    $$OutboxEntriesTableOrderingComposer,
    $$OutboxEntriesTableAnnotationComposer,
    $$OutboxEntriesTableCreateCompanionBuilder,
    $$OutboxEntriesTableUpdateCompanionBuilder,
    (
      OutboxRecord,
      BaseReferences<_$SudurDatabase, $OutboxEntriesTable, OutboxRecord>
    ),
    OutboxRecord,
    PrefetchHooks Function()>;

class $SudurDatabaseManager {
  final _$SudurDatabase _db;
  $SudurDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db, _db.units);
  $$UnitStatesTableTableManager get unitStates =>
      $$UnitStatesTableTableManager(_db, _db.unitStates);
  $$AttemptsTableTableManager get attempts =>
      $$AttemptsTableTableManager(_db, _db.attempts);
  $$CheckEventsTableTableManager get checkEvents =>
      $$CheckEventsTableTableManager(_db, _db.checkEvents);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$DailyPlansTableTableManager get dailyPlans =>
      $$DailyPlansTableTableManager(_db, _db.dailyPlans);
  $$LessonProgressEntriesTableTableManager get lessonProgressEntries =>
      $$LessonProgressEntriesTableTableManager(_db, _db.lessonProgressEntries);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
  $$SearchKeyCacheEntriesTableTableManager get searchKeyCacheEntries =>
      $$SearchKeyCacheEntriesTableTableManager(_db, _db.searchKeyCacheEntries);
  $$NgramCacheEntriesTableTableManager get ngramCacheEntries =>
      $$NgramCacheEntriesTableTableManager(_db, _db.ngramCacheEntries);
  $$SavedRecordingsTableTableManager get savedRecordings =>
      $$SavedRecordingsTableTableManager(_db, _db.savedRecordings);
  $$UploadQueueEntriesTableTableManager get uploadQueueEntries =>
      $$UploadQueueEntriesTableTableManager(_db, _db.uploadQueueEntries);
  $$EntitlementCacheEntriesTableTableManager get entitlementCacheEntries =>
      $$EntitlementCacheEntriesTableTableManager(
          _db, _db.entitlementCacheEntries);
  $$FreeUsageEntriesTableTableManager get freeUsageEntries =>
      $$FreeUsageEntriesTableTableManager(_db, _db.freeUsageEntries);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
}
