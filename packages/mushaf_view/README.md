# mushaf_view

Отрисовка 15-строчных страниц мусхафа, скрытые слова, состояния слов,
нажатия и доступность.

- **Владелец:** GPT-A
- **Задача:** [P07](../../docs/tasks/P07-mushaf-view.md)
- **ТЗ:** 2.2, 11.3, 16.12

Публичный интерфейс — только `lib/mushaf_view.dart`; внутренности — в
`lib/src/`.

## Использование

Приложение передаёт `MushafPageData` через реализацию `MushafLayoutSource`.
Визуальные `glyph` берутся из разметки страницы, а `canonicalText` для
экранного диктора — только из канонической базы. Пакет намеренно не пытается
преобразовать служебные знаки шрифта в арабский текст.

`PageFontLoader` загружает шрифт текущей страницы первым, затем во время
простоя — соседние страницы в окне `pageFontWindow` (по умолчанию ±3). Папку
со шрифтами передаёт приложение; сами шрифты в репозитории отсутствуют.

```dart
final loader = PageFontLoader(fontDirectoryPath: downloadedFontsPath);
await loader.ensureWindow(page.pageNumber);

MushafPage(
  data: page,
  fontFamily: loader.familyForPage(page.pageNumber),
  semanticsLabelBuilder: (ayah) => l10n.mushafAyahSemantics(
    ayah.surah,
    ayah.ayah,
    ayah.canonicalText,
  ),
  wordStates: states,
  onWordTap: openWordMenu,
);
```

Пример в `example/lib/main.dart` показывает страницы 582–583 на фиктивной
латинской разметке. `TODO_CONTENT` там не является текстом Корана и должен
быть заменён адаптером канонического содержания после слияния P03/P02.

Правила проекта: [`AGENTS.md`](../../AGENTS.md).
