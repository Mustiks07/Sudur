import 'dart:io';

import 'package:content_build/src/content_model.dart';
import 'package:sqlite3/sqlite3.dart';

/// Schema of the read-only content database (docs/tz section 12.2).
///
/// Additions to 12.2, needed by the page renderer: `ayah.end_*` (place and
/// glyph of the ayah-end marker) and `line.surah` (surah of a header line).
const List<String> contentSchema = [
  '''
CREATE TABLE surah (
  number INTEGER PRIMARY KEY,
  name_ar TEXT NOT NULL,
  name_ru TEXT,
  name_kk TEXT,
  name_uz TEXT,
  ayah_count INTEGER NOT NULL,
  revelation TEXT NOT NULL
)''',
  '''
CREATE TABLE ayah (
  surah INTEGER NOT NULL,
  ayah INTEGER NOT NULL,
  first_word_index INTEGER NOT NULL,
  word_count INTEGER NOT NULL,
  page INTEGER NOT NULL,
  juz INTEGER NOT NULL,
  hizb INTEGER NOT NULL,
  sajda INTEGER NOT NULL,
  end_page INTEGER NOT NULL,
  end_line INTEGER NOT NULL,
  end_line_position INTEGER NOT NULL,
  end_glyph_code TEXT NOT NULL,
  PRIMARY KEY (surah, ayah)
)''',
  '''
CREATE TABLE word (
  word_index INTEGER PRIMARY KEY,
  surah INTEGER NOT NULL,
  ayah INTEGER NOT NULL,
  position INTEGER NOT NULL,
  text_uthmani TEXT NOT NULL,
  page INTEGER NOT NULL,
  line INTEGER NOT NULL,
  line_position INTEGER NOT NULL,
  glyph_code TEXT NOT NULL,
  UNIQUE (surah, ayah, position)
)''',
  'CREATE INDEX word_page ON word (page, line)',
  '''
CREATE TABLE page (
  number INTEGER PRIMARY KEY,
  layout_id TEXT NOT NULL,
  first_word_index INTEGER NOT NULL,
  last_word_index INTEGER NOT NULL
)''',
  '''
CREATE TABLE line (
  page INTEGER NOT NULL,
  line INTEGER NOT NULL,
  kind TEXT NOT NULL,
  first_word_index INTEGER,
  last_word_index INTEGER,
  centered INTEGER NOT NULL,
  surah INTEGER,
  PRIMARY KEY (page, line)
)''',
  '''
CREATE TABLE content_version (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)''',
];

/// Writes [data] to a new SQLite file at [path], replacing any old file.
void writeContentSqlite(ContentData data, String path) {
  final file = File(path);
  if (file.existsSync()) file.deleteSync();
  final db = sqlite3.open(path);
  try {
    contentSchema.forEach(db.execute);
    db.execute('BEGIN');
    _insertAll(
      db,
      'INSERT INTO surah VALUES (?, ?, NULL, NULL, NULL, ?, ?)',
      [
        for (final s in data.surahs)
          [s.number, s.nameAr, s.ayahCount, s.revelation],
      ],
    );
    _insertAll(
      db,
      'INSERT INTO ayah VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        for (final a in data.ayahs)
          [
            a.surah,
            a.ayah,
            a.firstWordIndex,
            a.wordCount,
            a.page,
            a.juz,
            a.hizb,
            if (a.sajda) 1 else 0,
            a.end.page,
            a.end.line,
            a.end.linePosition,
            a.end.glyphCode,
          ],
      ],
    );
    _insertAll(db, 'INSERT INTO word VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', [
      for (final w in data.words)
        [
          w.wordIndex,
          w.surah,
          w.ayah,
          w.position,
          w.textUthmani,
          w.place.page,
          w.place.line,
          w.place.linePosition,
          w.place.glyphCode,
        ],
    ]);
    _insertAll(db, 'INSERT INTO page VALUES (?, ?, ?, ?)', [
      for (final p in data.pages)
        [p.number, p.layoutId, p.firstWordIndex, p.lastWordIndex],
    ]);
    _insertAll(db, 'INSERT INTO line VALUES (?, ?, ?, ?, ?, ?, ?)', [
      for (final l in data.lines)
        [
          l.page,
          l.line,
          l.kind.name,
          l.firstWordIndex,
          l.lastWordIndex,
          if (l.centered) 1 else 0,
          l.surah,
        ],
    ]);
    _insertAll(db, 'INSERT INTO content_version VALUES (?, ?)', [
      for (final e in data.version.entries) [e.key, e.value],
    ]);
    db.execute('COMMIT');
  } finally {
    db.dispose();
  }
}

void _insertAll(Database db, String sql, List<List<Object?>> rows) {
  final statement = db.prepare(sql);
  try {
    rows.forEach(statement.execute);
  } finally {
    statement.dispose();
  }
}
