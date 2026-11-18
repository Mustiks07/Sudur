"use strict";

const AUDIO_EXTENSIONS = [".wav", ".m4a", ".mp3", ".ogg", ".opus"];
const STATUS_LABELS = {
  correct: "Верно",
  omitted: "Пропуск",
  substituted: "Замена",
  selfCorrected: "Самоисправление",
  repeated: "Повтор",
  unclear: "Неразборчиво",
};
const {
  annotationValueErrors,
  optionalNonNegativeInteger,
  validSpan,
} = globalThis.AnnotationValidation;

const state = {
  directoryHandle: null,
  files: new Map(),
  recordings: [],
  annotations: new Map(),
  contentWords: [],
  contentByKey: new Map(),
  currentRecording: null,
  currentAnnotation: null,
  currentWordIndex: 0,
  undoStack: [],
  audioUrl: null,
  fallbackMode: false,
};

const element = (id) => document.getElementById(id);
const ui = {
  folderButton: element("folderButton"),
  fallbackFolderButton: element("fallbackFolderButton"),
  fallbackFolderInput: element("fallbackFolderInput"),
  contentButton: element("contentButton"),
  contentInput: element("contentInput"),
  message: element("message"),
  recordingCount: element("recordingCount"),
  recordingSearch: element("recordingSearch"),
  recordingList: element("recordingList"),
  welcome: element("welcome"),
  editor: element("editor"),
  recordingTitle: element("recordingTitle"),
  recordingMeta: element("recordingMeta"),
  saveDraftButton: element("saveDraftButton"),
  saveReadyButton: element("saveReadyButton"),
  audio: element("audio"),
  speed: element("speed"),
  speedValue: element("speedValue"),
  backButton: element("backButton"),
  playButton: element("playButton"),
  forwardButton: element("forwardButton"),
  undoButton: element("undoButton"),
  speakerId: element("speakerId"),
  nativeLanguage: element("nativeLanguage"),
  otherLanguageLabel: element("otherLanguageLabel"),
  otherLanguage: element("otherLanguage"),
  gender: element("gender"),
  ageGroup: element("ageGroup"),
  device: element("device"),
  noise: element("noise"),
  annotators: element("annotators"),
  rangeFrom: element("rangeFrom"),
  rangeTo: element("rangeTo"),
  rangeSummary: element("rangeSummary"),
  applyRangeButton: element("applyRangeButton"),
  asrCard: element("asrCard"),
  asrTitle: element("asrTitle"),
  asrText: element("asrText"),
  asrTokens: element("asrTokens"),
  wordProgress: element("wordProgress"),
  wordList: element("wordList"),
  endWordButton: element("endWordButton"),
  currentWordKey: element("currentWordKey"),
  currentWordText: element("currentWordText"),
  currentStatus: element("currentStatus"),
  wordStart: element("wordStart"),
  wordEnd: element("wordEnd"),
  heardLabel: element("heardLabel"),
  heard: element("heard"),
  correctionFields: element("correctionFields"),
  correctionAfterMs: element("correctionAfterMs"),
  correctionAfterWords: element("correctionAfterWords"),
  confirmationState: element("confirmationState"),
  confirmDetailsButton: element("confirmDetailsButton"),
  addInsertionButton: element("addInsertionButton"),
  addJumpButton: element("addJumpButton"),
  spanList: element("spanList"),
  insertionDialog: element("insertionDialog"),
  insertionForm: element("insertionForm"),
  insertionHeard: element("insertionHeard"),
  insertionStart: element("insertionStart"),
  insertionEnd: element("insertionEnd"),
  confirmInsertionButton: element("confirmInsertionButton"),
  jumpDialog: element("jumpDialog"),
  jumpForm: element("jumpForm"),
  jumpTo: element("jumpTo"),
  jumpStart: element("jumpStart"),
  jumpEnd: element("jumpEnd"),
  confirmJumpButton: element("confirmJumpButton"),
};

function showMessage(text, type = "info") {
  ui.message.textContent = text;
  ui.message.className = `message ${type}`;
}

function fileExtension(name) {
  const position = name.lastIndexOf(".");
  return position < 0 ? "" : name.slice(position).toLowerCase();
}

function recordingId(name) {
  const extension = fileExtension(name);
  return name.slice(0, name.length - extension.length);
}

function isAudio(name) {
  return AUDIO_EXTENSIONS.includes(fileExtension(name));
}

async function fileFromEntry(entry) {
  if (entry instanceof File) return entry;
  return entry.getFile();
}

async function readText(entry) {
  return (await fileFromEntry(entry)).text();
}

async function pickDirectory() {
  if (!("showDirectoryPicker" in window)) {
    showMessage(
      "Этот режим выбора папки недоступен. Нажмите «Открыть без доступа к папке» — при сохранении Chrome скачает JSON.",
      "error",
    );
    return;
  }
  try {
    const handle = await window.showDirectoryPicker({ mode: "readwrite" });
    state.directoryHandle = handle;
    state.fallbackMode = false;
    state.files.clear();
    for await (const [name, child] of handle.entries()) {
      if (child.kind === "file") state.files.set(name, child);
    }
    await loadFolderEntries();
    showMessage(`Папка «${handle.name}» открыта. Теперь выберите content.json.`, "success");
  } catch (error) {
    if (error && error.name === "AbortError") return;
    showMessage(`Не удалось открыть папку: ${error.message || error}`, "error");
  }
}

async function loadFallbackFolder(fileList) {
  state.directoryHandle = null;
  state.fallbackMode = true;
  state.files.clear();
  for (const file of fileList) state.files.set(file.name, file);
  await loadFolderEntries();
  showMessage(
    "Папка открыта в резервном режиме. При сохранении JSON попадёт в «Загрузки» — перенесите его к записи.",
    "info",
  );
}

async function loadFolderEntries() {
  state.recordings = [];
  state.annotations.clear();
  for (const [name, entry] of state.files) {
    if (isAudio(name)) {
      state.recordings.push({ id: recordingId(name), name, entry });
    }
  }
  state.recordings.sort((left, right) => left.name.localeCompare(right.name));

  for (const recording of state.recordings) {
    const annotationName = `${recording.id}.ann.json`;
    const entry = state.files.get(annotationName);
    if (!entry) continue;
    try {
      const annotation = JSON.parse(await readText(entry));
      state.annotations.set(recording.id, annotation);
    } catch (error) {
      state.annotations.set(recording.id, { _loadError: String(error) });
    }
  }
  renderRecordingList();
  if (state.recordings.length === 0) {
    showMessage("В выбранной папке нет поддерживаемых аудиофайлов.", "error");
  }
}

function annotationState(id) {
  const annotation = state.annotations.get(id);
  if (!annotation) return { key: "none", label: "Нет разметки" };
  if (annotation._loadError) return { key: "error", label: "Ошибка JSON" };
  if (annotationValueErrors(annotation).length > 0) {
    return { key: "error", label: "Ошибка значений" };
  }
  if (isStoredAnnotationReady(annotation)) return { key: "ready", label: "Готово" };
  return { key: "draft", label: "Черновик" };
}

function isStoredAnnotationReady(annotation) {
  if (annotationValueErrors(annotation).length > 0) return false;
  const hasMetadata =
    typeof annotation.speaker?.id === "string" && annotation.speaker.id.length > 0 &&
    typeof annotation.speaker?.nativeLanguage === "string" && annotation.speaker.nativeLanguage.length > 0 &&
    ["m", "f"].includes(annotation.speaker?.gender) &&
    typeof annotation.conditions?.device === "string" && annotation.conditions.device.length > 0 &&
    typeof annotation.conditions?.noise === "string" && annotation.conditions.noise.length > 0;
  const words = Array.isArray(annotation.words) ? annotation.words : [];
  const hasRange =
    typeof annotation.expected?.from === "string" &&
    typeof annotation.expected?.to === "string" &&
    words.length > 0 &&
    words[0].wordKey === annotation.expected.from &&
    words[words.length - 1].wordKey === annotation.expected.to;
  return hasMetadata && hasRange && words.every((word) => {
    if (word.status === "omitted") return true;
    const hasTimes = validSpan(word.startMs, word.endMs);
    if (word.status === "substituted") return hasTimes && typeof word.heard === "string" && word.heard.length > 0;
    if (word.status === "selfCorrected") return hasTimes && Number.isInteger(word.correction?.afterMs);
    return hasTimes;
  });
}

function renderRecordingList() {
  const query = ui.recordingSearch.value.trim().toLowerCase();
  const recordings = state.recordings.filter((item) => item.name.toLowerCase().includes(query));
  ui.recordingCount.textContent = String(state.recordings.length);
  ui.recordingList.replaceChildren();
  if (recordings.length === 0) {
    const empty = document.createElement("p");
    empty.className = "empty-small";
    empty.textContent = state.recordings.length === 0 ? "В папке нет записей." : "Ничего не найдено.";
    ui.recordingList.append(empty);
    return;
  }
  for (const recording of recordings) {
    const status = annotationState(recording.id);
    const button = document.createElement("button");
    button.type = "button";
    button.className = `recording-item${state.currentRecording?.id === recording.id ? " active" : ""}`;
    const name = document.createElement("span");
    name.textContent = recording.id;
    const pill = document.createElement("span");
    pill.className = `status-pill ${status.key}`;
    pill.textContent = status.label;
    const extension = document.createElement("small");
    extension.textContent = fileExtension(recording.name).slice(1).toUpperCase();
    button.append(name, pill, extension);
    button.addEventListener("click", () => openRecording(recording));
    ui.recordingList.append(button);
  }
}

async function loadContent(file) {
  try {
    const root = JSON.parse(await file.text());
    if (root.format !== 1 || !Array.isArray(root.words)) {
      throw new Error("ожидался content.json формата 1 с массивом words");
    }
    const words = root.words.map((row, index) => {
      if (
        !Number.isInteger(row.surah) || !Number.isInteger(row.ayah) ||
        !Number.isInteger(row.position) || typeof row.textUthmani !== "string" ||
        row.textUthmani.length === 0
      ) {
        throw new Error(`неверная запись words[${index}]`);
      }
      return {
        key: `${row.surah}:${row.ayah}:${row.position}`,
        text: row.textUthmani,
        index,
      };
    });
    const byKey = new Map(words.map((word) => [word.key, word]));
    if (byKey.size !== words.length) throw new Error("в content.json повторяются ключи слов");
    state.contentWords = words;
    state.contentByKey = byKey;
    showMessage(`Содержание загружено: ${words.length} слов. Текст показывается без изменений.`, "success");
    if (state.currentAnnotation) {
      const expected = state.currentAnnotation.expected;
      if (expected?.from && expected?.to) applyRange(expected.from, expected.to, true);
    }
  } catch (error) {
    showMessage(`Не удалось прочитать content.json: ${error.message || error}`, "error");
  }
}

function emptyAnnotation(id) {
  return {
    recordingId: id,
    speaker: { id: "", nativeLanguage: "", gender: "", ageGroup: "" },
    conditions: { device: "", noise: "" },
    expected: { from: "", to: "" },
    words: [],
    insertions: [],
    jumps: [],
    annotators: [],
  };
}

function normalizeLoadedAnnotation(id, source) {
  const annotation = emptyAnnotation(id);
  if (!source || source._loadError) return annotation;
  annotation.recordingId = id;
  annotation.speaker = { ...annotation.speaker, ...(source.speaker || {}) };
  annotation.conditions = { ...annotation.conditions, ...(source.conditions || {}) };
  annotation.expected = { ...annotation.expected, ...(source.expected || {}) };
  annotation.words = Array.isArray(source.words) ? source.words.map((word) => ({ ...word })) : [];
  annotation.insertions = Array.isArray(source.insertions) ? source.insertions.map((span) => ({ ...span })) : [];
  annotation.jumps = Array.isArray(source.jumps) ? source.jumps.map((span) => ({ ...span })) : [];
  annotation.annotators = Array.isArray(source.annotators) ? [...source.annotators] : [];
  return annotation;
}

async function openRecording(recording) {
  state.currentRecording = recording;
  state.currentAnnotation = normalizeLoadedAnnotation(recording.id, state.annotations.get(recording.id));
  state.currentWordIndex = 0;
  state.undoStack = [];
  ui.welcome.classList.add("hidden");
  ui.editor.classList.remove("hidden");
  ui.recordingTitle.textContent = recording.id;
  ui.recordingMeta.textContent = recording.name;
  fillMetadataForm();
  renderRecordingList();
  await loadAudio(recording.entry);
  await loadAsrHint(recording.id);
  const expected = state.currentAnnotation.expected;
  if (expected.from && expected.to && state.contentWords.length > 0) {
    applyRange(expected.from, expected.to, true);
  } else {
    renderWords();
  }
  const loadedErrors = annotationValueErrors(state.currentAnnotation);
  if (loadedErrors.length > 0) {
    showMessage(`В загруженной разметке есть ошибки: ${loadedErrors.join("; ")}.`, "error");
  }
}

async function loadAudio(entry) {
  if (state.audioUrl) URL.revokeObjectURL(state.audioUrl);
  const file = await fileFromEntry(entry);
  state.audioUrl = URL.createObjectURL(file);
  ui.audio.src = state.audioUrl;
  ui.audio.load();
  ui.audio.onloadedmetadata = () => {
    const duration = Number.isFinite(ui.audio.duration) ? `${ui.audio.duration.toFixed(1)} с` : "длительность неизвестна";
    ui.recordingMeta.textContent = `${file.name} · ${duration}`;
  };
}

async function loadAsrHint(id) {
  const prefix = `${id}.`;
  const candidates = [...state.files.keys()]
    .filter((name) => name.startsWith(prefix) && name.endsWith(".asr.jsonl"))
    .sort();
  ui.asrCard.classList.add("hidden");
  if (candidates.length === 0) return;
  const name = candidates[0];
  try {
    const lines = (await readText(state.files.get(name))).split(/\r?\n/).filter((line) => line.trim());
    const entries = lines.map((line, index) => {
      try {
        return JSON.parse(line);
      } catch (_) {
        throw new Error(`ошибка JSON в строке ${index + 1}`);
      }
    });
    const finals = entries.filter((entry) => entry.isFinal === true);
    const visible = finals.length > 0 ? finals : entries;
    ui.asrTitle.textContent = name;
    ui.asrText.textContent = visible.map((entry) => typeof entry.text === "string" ? entry.text : "").join(" ");
    ui.asrTokens.replaceChildren();
    for (const entry of visible) {
      if (!Array.isArray(entry.tokens)) continue;
      for (const token of entry.tokens) {
        const item = document.createElement("span");
        item.className = "asr-token";
        const text = document.createElement("span");
        text.textContent = typeof token.text === "string" ? token.text : "";
        const time = document.createElement("time");
        time.textContent = Number.isInteger(token.startMs) ? ` ${token.startMs} мс` : " —";
        item.append(text, time);
        ui.asrTokens.append(item);
      }
    }
    ui.asrCard.classList.remove("hidden");
  } catch (error) {
    showMessage(`ASR-подсказка ${name} не прочитана: ${error.message || error}`, "error");
  }
}

function fillMetadataForm() {
  const annotation = state.currentAnnotation;
  ui.speakerId.value = annotation.speaker.id || "";
  const language = annotation.speaker.nativeLanguage || "";
  const known = ["", "ru", "kk", "uz"].includes(language);
  ui.nativeLanguage.value = known ? language : "other";
  ui.otherLanguage.value = known ? "" : language;
  ui.otherLanguageLabel.classList.toggle("hidden", ui.nativeLanguage.value !== "other");
  ui.gender.value = annotation.speaker.gender || "";
  ui.ageGroup.value = annotation.speaker.ageGroup || "";
  ui.device.value = annotation.conditions.device || "";
  ui.noise.value = annotation.conditions.noise || "";
  ui.annotators.value = annotation.annotators.join(", ");
  ui.rangeFrom.value = annotation.expected.from || "";
  ui.rangeTo.value = annotation.expected.to || "";
}

function collectMetadata() {
  if (!state.currentAnnotation) return;
  const language = ui.nativeLanguage.value === "other" ? ui.otherLanguage.value.trim() : ui.nativeLanguage.value;
  state.currentAnnotation.speaker = {
    id: ui.speakerId.value.trim(),
    nativeLanguage: language,
    gender: ui.gender.value,
  };
  if (ui.ageGroup.value) state.currentAnnotation.speaker.ageGroup = ui.ageGroup.value;
  state.currentAnnotation.conditions = {
    device: ui.device.value,
    noise: ui.noise.value,
  };
  state.currentAnnotation.annotators = ui.annotators.value
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
}

function applyRange(from = ui.rangeFrom.value.trim(), to = ui.rangeTo.value.trim(), preserve = false) {
  if (!state.currentAnnotation) return;
  if (state.contentWords.length === 0) {
    showMessage("Сначала выберите content.json.", "error");
    return;
  }
  const first = state.contentByKey.get(from);
  const last = state.contentByKey.get(to);
  if (!first || !last) {
    showMessage("Ключ «От» или «До» не найден в content.json.", "error");
    return;
  }
  if (first.index > last.index) {
    showMessage("Начало диапазона должно быть раньше конца.", "error");
    return;
  }
  pushUndo();
  const previous = new Map(state.currentAnnotation.words.map((word) => [word.wordKey, word]));
  const words = state.contentWords.slice(first.index, last.index + 1).map((contentWord) => {
    if (preserve && previous.has(contentWord.key)) return { ...previous.get(contentWord.key) };
    if (previous.has(contentWord.key)) return { ...previous.get(contentWord.key) };
    return { wordKey: contentWord.key, status: "correct", _confirmed: false };
  });
  state.currentAnnotation.expected = { from, to };
  state.currentAnnotation.words = words;
  ui.rangeFrom.value = from;
  ui.rangeTo.value = to;
  ui.rangeSummary.textContent = `${words.length} слов; текст взят из content.json без изменений.`;
  state.currentWordIndex = Math.min(state.currentWordIndex, Math.max(0, words.length - 1));
  renderWords();
  showMessage(`Диапазон ${from}–${to}: ${words.length} слов.`, "success");
}

function inferredConfirmed(word) {
  if (word._confirmed === true) return true;
  if (word.status === "omitted") return true;
  return validSpan(word.startMs, word.endMs);
}

function renderWords() {
  ui.wordList.replaceChildren();
  const annotation = state.currentAnnotation;
  if (!annotation || annotation.words.length === 0) {
    const empty = document.createElement("p");
    empty.className = "empty-small";
    empty.textContent = state.contentWords.length === 0 ? "Выберите content.json и задайте диапазон." : "Задайте диапазон слов.";
    ui.wordList.append(empty);
    ui.wordProgress.textContent = "0 / 0";
    renderCurrentWord();
    return;
  }
  let confirmed = 0;
  annotation.words.forEach((word, index) => {
    const isConfirmed = inferredConfirmed(word);
    if (isConfirmed) confirmed += 1;
    const contentWord = state.contentByKey.get(word.wordKey);
    const button = document.createElement("button");
    button.type = "button";
    button.className = `word-row${index === state.currentWordIndex ? " current" : ""}${isConfirmed ? " confirmed" : ""}`;
    const number = document.createElement("span");
    number.className = "word-number";
    number.textContent = String(index + 1);
    const text = document.createElement("span");
    text.className = "word-text";
    text.dir = "rtl";
    text.textContent = contentWord ? contentWord.text : "[нет в content.json]";
    const status = document.createElement("span");
    status.className = "word-status";
    status.textContent = STATUS_LABELS[word.status] || word.status;
    const timing = document.createElement("span");
    timing.className = "word-time";
    timing.textContent = Number.isInteger(word.startMs) && Number.isInteger(word.endMs)
      ? `${word.startMs}–${word.endMs}`
      : "—";
    button.append(number, text, status, timing);
    button.addEventListener("click", () => selectWord(index));
    ui.wordList.append(button);
  });
  ui.wordProgress.textContent = `${confirmed} / ${annotation.words.length}`;
  renderCurrentWord();
  const currentRow = ui.wordList.children[state.currentWordIndex];
  if (currentRow) currentRow.scrollIntoView({ block: "nearest" });
}

function currentWord() {
  return state.currentAnnotation?.words[state.currentWordIndex] || null;
}

function selectWord(index) {
  if (!state.currentAnnotation || index < 0 || index >= state.currentAnnotation.words.length) return;
  state.currentWordIndex = index;
  renderWords();
}

function renderCurrentWord() {
  const word = currentWord();
  const disabled = !word;
  for (const control of [
    ui.currentStatus, ui.wordStart, ui.wordEnd, ui.heard, ui.correctionAfterMs,
    ui.correctionAfterWords, ui.confirmDetailsButton, ui.addInsertionButton, ui.addJumpButton,
  ]) control.disabled = disabled;
  if (!word) {
    ui.currentWordKey.textContent = "—";
    ui.currentWordText.textContent = "—";
    ui.currentStatus.value = "correct";
    ui.wordStart.value = "";
    ui.wordEnd.value = "";
    ui.heard.value = "";
    ui.correctionAfterMs.value = "";
    ui.correctionAfterWords.value = "";
    ui.confirmationState.textContent = "Не подтверждено";
    ui.confirmationState.classList.remove("done");
    renderSpans();
    return;
  }
  ui.currentWordKey.textContent = word.wordKey;
  ui.currentWordText.textContent = state.contentByKey.get(word.wordKey)?.text || "[нет в content.json]";
  ui.currentStatus.value = word.status;
  ui.wordStart.value = Number.isInteger(word.startMs) ? String(word.startMs) : "";
  ui.wordEnd.value = Number.isInteger(word.endMs) ? String(word.endMs) : "";
  ui.heard.value = word.heard || "";
  ui.correctionAfterMs.value = Number.isInteger(word.correction?.afterMs) ? String(word.correction.afterMs) : "";
  ui.correctionAfterWords.value = Number.isInteger(word.correction?.afterWords) ? String(word.correction.afterWords) : "";
  toggleStatusFields(word.status);
  const confirmed = inferredConfirmed(word);
  ui.confirmationState.textContent = confirmed ? "Подтверждено человеком" : "Не подтверждено";
  ui.confirmationState.classList.toggle("done", confirmed);
  renderSpans();
}

function toggleStatusFields(status) {
  ui.heardLabel.classList.toggle("hidden", status !== "substituted");
  ui.correctionFields.classList.toggle("hidden", status !== "selfCorrected");
  const omitted = status === "omitted";
  ui.wordStart.disabled = omitted;
  ui.wordEnd.disabled = omitted;
}

function pushUndo() {
  if (!state.currentAnnotation) return;
  state.undoStack.push({
    annotation: JSON.parse(JSON.stringify(state.currentAnnotation)),
    wordIndex: state.currentWordIndex,
  });
  if (state.undoStack.length > 50) state.undoStack.shift();
}

function undo() {
  const previous = state.undoStack.pop();
  if (!previous) {
    showMessage("Отменять нечего.", "info");
    return;
  }
  state.currentAnnotation = previous.annotation;
  state.currentWordIndex = previous.wordIndex;
  fillMetadataForm();
  renderWords();
  showMessage("Последнее изменение отменено.", "success");
}

function setWordStatus(status) {
  const word = currentWord();
  if (!word) return;
  pushUndo();
  word.status = status;
  word._confirmed = status === "omitted";
  if (status === "omitted") {
    delete word.startMs;
    delete word.endMs;
    delete word.heard;
    delete word.correction;
    advanceWord();
  } else {
    if (status !== "substituted") delete word.heard;
    if (status !== "selfCorrected") delete word.correction;
    renderWords();
    if (status === "substituted") ui.heard.focus();
    if (status === "selfCorrected") ui.correctionAfterMs.focus();
  }
}

function applyCurrentDetails() {
  const word = currentWord();
  if (!word) return;
  const status = ui.currentStatus.value;
  const start = optionalNonNegativeInteger(ui.wordStart.value);
  const end = optionalNonNegativeInteger(ui.wordEnd.value);
  if (status !== "omitted" && (Number.isNaN(start) || Number.isNaN(end))) {
    showMessage("Начало и конец слова должны быть целыми числами не меньше нуля.", "error");
    return;
  }
  if (status !== "omitted" && ((start === null) !== (end === null))) {
    showMessage("Начало и конец слова нужно заполнить вместе.", "error");
    return;
  }
  if (start !== null && end < start) {
    showMessage("Конец слова не может быть раньше начала.", "error");
    return;
  }
  if (status === "substituted" && !ui.heard.value.trim()) {
    showMessage("Для замены укажите, что было услышано.", "error");
    return;
  }
  const correctionAfterMs = optionalNonNegativeInteger(ui.correctionAfterMs.value);
  const correctionAfterWords = optionalNonNegativeInteger(ui.correctionAfterWords.value);
  if (status === "selfCorrected" && (correctionAfterMs === null || Number.isNaN(correctionAfterMs))) {
    showMessage("Для самоисправления укажите время исправления в миллисекундах.", "error");
    return;
  }
  if (status === "selfCorrected" && Number.isNaN(correctionAfterWords)) {
    showMessage("Число слов после исправления должно быть целым числом не меньше нуля.", "error");
    return;
  }
  pushUndo();
  word.status = status;
  if (status === "omitted") {
    delete word.startMs;
    delete word.endMs;
  } else if (start !== null) {
    word.startMs = start;
    word.endMs = end;
  } else {
    delete word.startMs;
    delete word.endMs;
  }
  if (status === "substituted") word.heard = ui.heard.value.trim();
  else delete word.heard;
  if (status === "selfCorrected") {
    word.correction = { afterMs: correctionAfterMs };
    if (correctionAfterWords !== null) word.correction.afterWords = correctionAfterWords;
  } else {
    delete word.correction;
  }
  word._confirmed = status === "omitted" || (start !== null && end !== null);
  renderWords();
  showMessage(`Поля ${word.wordKey} применены.`, "success");
}

function markWordEnd() {
  const word = currentWord();
  if (!word) return;
  const end = Math.max(0, Math.round(ui.audio.currentTime * 1000));
  const previous = state.currentAnnotation.words[state.currentWordIndex - 1];
  const start = Number.isInteger(word.startMs)
    ? word.startMs
    : Number.isInteger(previous?.endMs) ? previous.endMs : 0;
  if (end < start) {
    showMessage("Позиция проигрывателя раньше начала текущего слова.", "error");
    return;
  }
  pushUndo();
  word.startMs = start;
  word.endMs = end;
  word._confirmed = true;
  if (word.status === "substituted" && !word.heard) {
    renderWords();
    showMessage("Время поставлено. Теперь заполните «Что услышано».", "info");
    ui.heard.focus();
    return;
  }
  if (word.status === "selfCorrected" && !Number.isInteger(word.correction?.afterMs)) {
    renderWords();
    showMessage("Время поставлено. Укажите время самоисправления.", "info");
    ui.correctionAfterMs.focus();
    return;
  }
  advanceWord();
}

function advanceWord() {
  if (state.currentWordIndex < state.currentAnnotation.words.length - 1) {
    state.currentWordIndex += 1;
  }
  renderWords();
}

function seek(seconds) {
  if (!Number.isFinite(ui.audio.duration)) return;
  ui.audio.currentTime = Math.min(ui.audio.duration, Math.max(0, ui.audio.currentTime + seconds));
}

function togglePlayback() {
  if (!ui.audio.src) return;
  if (ui.audio.paused) ui.audio.play().catch((error) => showMessage(`Не удалось начать проигрывание: ${error.message}`, "error"));
  else ui.audio.pause();
}

function currentTimeMs() {
  return Math.max(0, Math.round(ui.audio.currentTime * 1000));
}

function openInsertionDialog() {
  if (!currentWord()) return;
  const now = currentTimeMs();
  ui.insertionHeard.value = "";
  ui.insertionStart.value = String(now);
  ui.insertionEnd.value = String(now);
  ui.insertionDialog.showModal();
}

function openJumpDialog() {
  if (!currentWord()) return;
  const now = currentTimeMs();
  ui.jumpTo.value = "";
  ui.jumpStart.value = String(now);
  ui.jumpEnd.value = String(now);
  ui.jumpDialog.showModal();
}

function addInsertion(event) {
  event.preventDefault();
  const word = currentWord();
  const start = Number(ui.insertionStart.value);
  const end = Number(ui.insertionEnd.value);
  if (!word || !ui.insertionHeard.value.trim() || !validSpan(start, end)) {
    showMessage("Заполните услышанное слово и корректный диапазон времени.", "error");
    return;
  }
  pushUndo();
  state.currentAnnotation.insertions.push({
    afterWordKey: word.wordKey,
    heard: ui.insertionHeard.value.trim(),
    startMs: start,
    endMs: end,
  });
  ui.insertionDialog.close();
  renderSpans();
}

function addJump(event) {
  event.preventDefault();
  const word = currentWord();
  const start = Number(ui.jumpStart.value);
  const end = Number(ui.jumpEnd.value);
  const to = ui.jumpTo.value.trim();
  if (!word || !state.contentByKey.has(to) || !validSpan(start, end)) {
    showMessage("Укажите существующий ключ назначения и корректный диапазон времени.", "error");
    return;
  }
  pushUndo();
  state.currentAnnotation.jumps.push({
    afterWordKey: word.wordKey,
    to,
    startMs: start,
    endMs: end,
  });
  ui.jumpDialog.close();
  renderSpans();
}

function renderSpans() {
  ui.spanList.replaceChildren();
  if (!state.currentAnnotation) return;
  const entries = [
    ...state.currentAnnotation.insertions.map((span, index) => ({ kind: "insertions", index, span, label: `Лишнее: ${span.heard || "—"}` })),
    ...state.currentAnnotation.jumps.map((span, index) => ({ kind: "jumps", index, span, label: `Перескок → ${span.to || "—"}` })),
  ];
  for (const entry of entries) {
    const item = document.createElement("div");
    item.className = "span-item";
    item.textContent = `${entry.label} · ${entry.span.startMs}–${entry.span.endMs} мс`;
    const remove = document.createElement("button");
    remove.type = "button";
    remove.setAttribute("aria-label", `Удалить: ${entry.label}`);
    remove.textContent = "×";
    remove.addEventListener("click", () => {
      pushUndo();
      state.currentAnnotation[entry.kind].splice(entry.index, 1);
      renderSpans();
    });
    item.append(remove);
    ui.spanList.append(item);
  }
}

function saveErrors(requireComplete) {
  collectMetadata();
  const annotation = state.currentAnnotation;
  const errors = [];
  if (!annotation.speaker.id) errors.push("ID чтеца");
  if (!annotation.speaker.nativeLanguage || annotation.speaker.nativeLanguage === "other") errors.push("родной язык");
  if (!annotation.speaker.gender) errors.push("пол");
  if (!annotation.conditions.device) errors.push("класс телефона");
  if (!annotation.conditions.noise) errors.push("условия записи");
  if (!annotation.expected.from || !annotation.expected.to || annotation.words.length === 0) errors.push("диапазон слов");
  if (!requireComplete) return errors;
  errors.push(...annotationValueErrors(annotation));
  const pending = annotation.words.filter((word) => !inferredConfirmed(word));
  if (pending.length > 0) errors.push(`не подтверждено слов: ${pending.length}`);
  const badSubstitution = annotation.words.find((word) => word.status === "substituted" && !word.heard?.trim());
  if (badSubstitution) errors.push(`нет услышанного текста у ${badSubstitution.wordKey}`);
  const badCorrection = annotation.words.find((word) => word.status === "selfCorrected" && !Number.isInteger(word.correction?.afterMs));
  if (badCorrection) errors.push(`нет времени исправления у ${badCorrection.wordKey}`);
  return errors;
}

function cleanAnnotation() {
  collectMetadata();
  const source = state.currentAnnotation;
  return {
    recordingId: source.recordingId,
    speaker: { ...source.speaker },
    conditions: { ...source.conditions },
    expected: { ...source.expected },
    words: source.words.map((word) => {
      const clean = { wordKey: word.wordKey, status: word.status };
      if (typeof word.heard === "string" && word.heard) clean.heard = word.heard;
      if (Number.isInteger(word.startMs)) clean.startMs = word.startMs;
      if (Number.isInteger(word.endMs)) clean.endMs = word.endMs;
      if (word.status === "selfCorrected" && word.correction) clean.correction = { ...word.correction };
      return clean;
    }),
    insertions: source.insertions.map((span) => ({ ...span })),
    jumps: source.jumps.map((span) => ({ ...span })),
    annotators: [...source.annotators],
  };
}

async function saveAnnotation(status) {
  if (!state.currentRecording || !state.currentAnnotation) return;
  const errors = saveErrors(status === "ready");
  if (errors.length > 0) {
    const action = status === "ready" ? "отметить готовой" : "сохранить черновик";
    showMessage(`Нельзя ${action}: ${errors.join("; ")}.`, "error");
    return;
  }
  const annotation = cleanAnnotation();
  const name = `${state.currentRecording.id}.ann.json`;
  const json = `${JSON.stringify(annotation, null, 2)}\n`;
  try {
    if (state.directoryHandle) {
      const handle = await state.directoryHandle.getFileHandle(name, { create: true });
      const writable = await handle.createWritable();
      await writable.write(json);
      await writable.close();
      state.files.set(name, handle);
      showMessage(`${name} сохранён в папку с записью.`, "success");
    } else {
      const blob = new Blob([json], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = name;
      link.click();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
      showMessage(`${name} скачан. Перенесите его из «Загрузок» в папку с записью.`, "success");
    }
    state.currentAnnotation = normalizeLoadedAnnotation(state.currentRecording.id, annotation);
    state.annotations.set(state.currentRecording.id, annotation);
    renderRecordingList();
    renderWords();
  } catch (error) {
    showMessage(`Не удалось сохранить ${name}: ${error.message || error}`, "error");
  }
}

function isTypingTarget(target) {
  return target instanceof HTMLInputElement || target instanceof HTMLSelectElement || target instanceof HTMLTextAreaElement;
}

function handleKeydown(event) {
  if (event.ctrlKey && event.key.toLowerCase() === "z") {
    event.preventDefault();
    undo();
    return;
  }
  if (isTypingTarget(event.target) || ui.insertionDialog.open || ui.jumpDialog.open) return;
  const key = event.key.toLowerCase();
  const actions = {
    "1": () => setWordStatus("correct"),
    "2": () => setWordStatus("omitted"),
    "3": () => setWordStatus("substituted"),
    "4": () => setWordStatus("selfCorrected"),
    "5": () => setWordStatus("repeated"),
    "6": () => setWordStatus("unclear"),
    a: () => seek(-2),
    d: () => seek(2),
    i: openInsertionDialog,
    j: openJumpDialog,
    enter: markWordEnd,
    " ": togglePlayback,
  };
  if (actions[key]) {
    event.preventDefault();
    actions[key]();
  }
}

ui.folderButton.addEventListener("click", pickDirectory);
ui.fallbackFolderButton.addEventListener("click", () => ui.fallbackFolderInput.click());
ui.fallbackFolderInput.addEventListener("change", () => loadFallbackFolder(ui.fallbackFolderInput.files));
ui.contentButton.addEventListener("click", () => ui.contentInput.click());
ui.contentInput.addEventListener("change", () => {
  const file = ui.contentInput.files[0];
  if (file) loadContent(file);
});
ui.recordingSearch.addEventListener("input", renderRecordingList);
ui.nativeLanguage.addEventListener("change", () => {
  ui.otherLanguageLabel.classList.toggle("hidden", ui.nativeLanguage.value !== "other");
});
ui.applyRangeButton.addEventListener("click", () => applyRange());
ui.speed.addEventListener("input", () => {
  const speed = Number(ui.speed.value);
  ui.audio.playbackRate = speed;
  ui.speedValue.textContent = `${speed.toFixed(1).replace(".", ",")}×`;
});
ui.backButton.addEventListener("click", () => seek(-2));
ui.forwardButton.addEventListener("click", () => seek(2));
ui.playButton.addEventListener("click", togglePlayback);
ui.undoButton.addEventListener("click", undo);
ui.endWordButton.addEventListener("click", markWordEnd);
document.querySelectorAll("[data-status]").forEach((button) => {
  button.addEventListener("click", () => setWordStatus(button.dataset.status));
});
ui.currentStatus.addEventListener("change", () => toggleStatusFields(ui.currentStatus.value));
ui.confirmDetailsButton.addEventListener("click", applyCurrentDetails);
ui.addInsertionButton.addEventListener("click", openInsertionDialog);
ui.addJumpButton.addEventListener("click", openJumpDialog);
ui.confirmInsertionButton.addEventListener("click", addInsertion);
ui.confirmJumpButton.addEventListener("click", addJump);
ui.saveDraftButton.addEventListener("click", () => saveAnnotation("draft"));
ui.saveReadyButton.addEventListener("click", () => saveAnnotation("ready"));
document.addEventListener("keydown", handleKeydown);

if (!("showDirectoryPicker" in window)) {
  ui.folderButton.disabled = true;
  showMessage(
    "Прямой доступ к папке недоступен в этом режиме Chrome. Используйте «Открыть без доступа к папке»; сохранение будет через скачивание.",
    "info",
  );
}
