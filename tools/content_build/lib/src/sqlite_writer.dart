import 'dart:io';

import 'package:content_build/src/content_model.dart';
import 'package:content_build/src/derived_content.dart';
import 'package:content_build/src/text_model.dart';
import 'package:sqlite3/sqlite3.dart';

/// Schema of the read-only content database (docs/tz 12.2, ADR 0004).
///
/// Text and page layout live apart: `surah`, `ayah`, `word` hold the text
/// of the whole Quran; `word_layout`, `ayah_layout`, `page`, `line` hold the
/// layout of the pages that have one, keyed by `layout_id`.
const List<String> contentSchema = [
  '''
CREATE TABLE surah (
  number INTEGER PRIMARY KEY,
  name_ar TEXT NOT NULL,
  name_ru TEXT,
  name_kk TEXT,
  name_uz TEXT,
  ayah_count INTEGER NOT NULL,
  revelation TEXT
)''',
  '''
CREATE TABLE ayah (
  surah INTEGER NOT NULL,
  ayah INTEGER NOT NULL,
  first_word_index INTEGER NOT NULL,
  word_count INTEGER NOT NULL,
  juz INTEGER,
  hizb INTEGER,
  sajda INTEGER,
  PRIMARY KEY (surah, ayah)
)''',
  '''
CREATE TABLE word (
  word_index INTEGER PRIMARY KEY,
  surah INTEGER NOT NULL,
  ayah INTEGER NOT NULL,
  position INTEGER NOT NULL,
  text_uthmani TEXT NOT NULL,
  UNIQUE (surah, ayah, position)
)''',
  '''
CREATE TABLE word_layout (
  layout_id TEXT NOT NULL,
  word_index INTEGER NOT NULL,
  page INTEGER NOT NULL,
  line INTEGER NOT NULL,
  line_position INTEGER NOT NULL,
  glyph_code TEXT NOT NULL,
  PRIMARY KEY (layout_id, word_index)
)''',
  'CREATE INDEX word_layout_page ON word_layout (layout_id, page, line)',
  '''
CREATE TABLE ayah_layout (
  layout_id TEXT NOT NULL,
  surah INTEGER NOT NULL,
  ayah INTEGER NOT NULL,
  page INTEGER NOT NULL,
  end_page INTEGER NOT NULL,
  end_line INTEGER NOT NULL,
  end_line_position INTEGER NOT NULL,
  end_glyph_code TEXT NOT NULL,
  PRIMARY KEY (layout_id, surah, ayah)
)''',
  '''
CREATE TABLE page (
  layout_id TEXT NOT NULL,
  number INTEGER NOT NULL,
  first_word_index INTEGER NOT NULL,
  last_word_index INTEGER NOT NULL,
  PRIMARY KEY (layout_id, number)
)''',
  '''
CREATE TABLE line (
  layout_id TEXT NOT NULL,
  page INTEGER NOT NULL,
  line INTEGER NOT NULL,
  kind TEXT NOT NULL,
  first_word_index INTEGER,
  last_word_index INTEGER,
  centered INTEGER NOT NULL,
  surah INTEGER,
  PRIMARY KEY (layout_id, page, line)
)''',
  '''
CREATE TABLE passage_default (
  id INTEGER PRIMARY KEY,
  from_word_index INTEGER NOT NULL,
  to_word_index INTEGER NOT NULL
)''',
  '''
CREATE TABLE similar_pair (
  id INTEGER PRIMARY KEY,
  a_from INTEGER NOT NULL,
  a_to INTEGER NOT NULL,
  b_from INTEGER NOT NULL,
  b_to INTEGER NOT NULL,
  verified INTEGER NOT NULL DEFAULT 0
)''',
  '''
CREATE TABLE content_version (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)''',
];

/// Writes the text of the whole Quran ([text]), the page layout of the
/// build scope ([layout]) and the [derived] passages and similar places
/// (none verified) to a new SQLite file at [path], replacing any old file.
void writeContentSqlite(
  QuranTextData text,
  ContentData layout,
  String layoutId,
  String path, {
  DerivedContent? derived,
}) {
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
        for (final s in text.surahs)
          [s.number, s.nameAr, s.ayahCount, s.revelation],
      ],
    );
    _insertAll(db, 'INSERT INTO ayah VALUES (?, ?, ?, ?, ?, ?, ?)', [
      for (final a in text.ayahs)
        [
          a.surah,
          a.ayah,
          a.firstWordIndex,
          a.words.length,
          a.juz,
          a.hizb,
          switch (a.sajda) {
            null => null,
            true => 1,
            false => 0,
          },
        ],
    ]);
    _insertAll(db, 'INSERT INTO word VALUES (?, ?, ?, ?, ?)', [
      for (final a in text.ayahs)
        for (var i = 0; i < a.words.length; i++)
          [a.firstWordIndex + i, a.surah, a.ayah, i + 1, a.words[i]],
    ]);
    _insertAll(db, 'INSERT INTO word_layout VALUES (?, ?, ?, ?, ?, ?)', [
      for (final w in layout.words)
        [
          layoutId,
          w.wordIndex,
          w.place.page,
          w.place.line,
          w.place.linePosition,
          w.place.glyphCode,
        ],
    ]);
    _insertAll(
      db,
      'INSERT INTO ayah_layout VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        for (final a in layout.ayahs)
          [
            layoutId,
            a.surah,
            a.ayah,
            a.page,
            a.end.page,
            a.end.line,
            a.end.linePosition,
            a.end.glyphCode,
          ],
      ],
    );
    _insertAll(db, 'INSERT INTO page VALUES (?, ?, ?, ?)', [
      for (final p in layout.pages)
        [p.layoutId, p.number, p.firstWordIndex, p.lastWordIndex],
    ]);
    _insertAll(db, 'INSERT INTO line VALUES (?, ?, ?, ?, ?, ?, ?, ?)', [
      for (final l in layout.lines)
        [
          layoutId,
          l.page,
          l.line,
          l.kind.name,
          l.firstWordIndex,
          l.lastWordIndex,
          if (l.centered) 1 else 0,
          l.surah,
        ],
    ]);
    if (derived != null) {
      _insertAll(db, 'INSERT INTO passage_default VALUES (?, ?, ?)', [
        for (final (i, p) in derived.passages.indexed) [i + 1, p.from, p.to],
      ]);
      _insertAll(db, 'INSERT INTO similar_pair VALUES (?, ?, ?, ?, ?, 0)', [
        for (final (i, p) in derived.pairs.indexed)
          [i + 1, p.aFrom, p.aTo, p.bFrom, p.bTo],
      ]);
    }
    _insertAll(db, 'INSERT INTO content_version VALUES (?, ?)', [
      for (final e in text.version.entries) [e.key, e.value],
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
