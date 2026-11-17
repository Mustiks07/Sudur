# AGENTS.md — Sudur

Sudur is a Flutter app (Android + iOS) for learning to read the Quran from zero and memorizing it, with on-device recitation checking. The full specification is in `docs/tz/` (in Russian). This file is the short, binding version for coding agents. If this file and `docs/tz/` disagree, `docs/tz/` wins; tell the owner.

The owner speaks Russian. Write code, identifiers and code comments in English; write task reports, ADRs and docs in Russian.

## Team, branches, tasks

- Agents: **Opus** (logic and data), **GPT-A** (app and UI), **GPT-B** (audio and recognition), **Astra** (integrator: reviews, merges, keeps `main` green, owns root files, `packages/contracts`, `docs/`, `.github/`).
- Your task file is in `docs/tasks/`. It lists your branch, the paths you may change, the spec sections, and what "done" means. Read it first.
- Branch per task: `<agent>/<task-id>-<short>`, e.g. `opus/p06-follow`. Never push to `main`.
- Before opening a PR: `git fetch origin && git rebase origin/main`, then format, analyze and tests must pass.
- PR to `main`, title `[P06] follow v0`. Astra reviews and gives a verdict; the owner merges with "Create a merge commit" (not squash).
- Full process: `docs/WORKFLOW.md`.
- **No GitHub write access in your environment?** (`could not read Username`, API `401`) — do not retry. Bundle your branches (`git bundle create /tmp/sudur-<agent>.bundle <branches> ^origin/main`), verify it, and report commit hashes, SHA-256 and size; the owner delivers it. See `docs/WORKFLOW.md`.

## Non-negotiable rules

1. **Never modify, generate or "fix" Quran text.** Canonical text comes only from the content package built by `tools/content_build` from licensed sources. Never write Arabic text, translations, tafsir, tajweed rules, dua texts or lesson content yourself — put `TODO_CONTENT` and leave it for a human.
2. **Never substitute expected text for what was heard.** Recognition results are stored and shown as recognized (spec ПО-13).
3. **Audio never touches disk** unless the user explicitly saved a recording. No audio or recognized text in logs, crash reports or analytics.
4. **No secrets in the repo.** Only the Supabase publishable key and the RevenueCat public SDK key may ship in the app. Secret keys live only in server/CI secrets.
5. **No magic numbers.** Thresholds and tunables come from config (spec section 12.4) or the model package.
6. **Stay in your package.** One task = one package or one screen. Do not edit other packages. Never change `packages/contracts` without an ADR approved by the owner.
7. **Do not add dependencies** without a one-line justification and a license check in the PR description.

## Repository layout

```
app/                 Flutter app: lib/ui/<feature>/{views,view_models}, lib/ui/core, lib/data/repositories, lib/routing, lib/config
packages/
  contracts/         immutable domain models, events, repository/service interfaces   (pure Dart)
  quran_text/        canonical text access, search keys, n-gram index                   (pure Dart)
  follow/            reading-position following                                         (pure Dart)
  check/             mistake detection                                                  (pure Dart)
  session/           reading session orchestration                                      (pure Dart)
  planner/           plan, FSRS, today's session                                        (pure Dart)
  lessons/           lesson engine and lesson package format                            (pure Dart)
  audio_capture/     microphone, ring buffer, VAD, signal quality                       (service)
  asr_sherpa/        sherpa-onnx recognizer                                             (service)
  storage/           drift database                                                     (service)
  content/           manifest, downloads, package install                               (service)
  entitlements/      RevenueCat                                                         (service)
  sync/              Supabase sync                                                      (service)
  testing/           shared fakes for tests
tools/eval/          offline evaluation on recorded corpus
tools/content_build/ builds content packages from licensed sources
docs/tz/             specification (Russian)
docs/adr/            architecture decision records
```

## Architecture (official Flutter architecture guide)

| Layer | Component | May depend on |
|---|---|---|
| UI | View (widget) — no logic except show/hide, animation, layout, simple navigation | its one ViewModel |
| UI | ViewModel (`ChangeNotifier`) — UI state + commands | repositories, domain packages (via constructor, private fields) |
| Domain | pure-Dart packages above | `contracts`, `quran_text` |
| Data | Repository (abstract class + impls) — single source of truth, caching, retries, errors | services only; never another repository |
| Data | Service — stateless wrapper of one external source | nothing in the app |

- Unidirectional data flow: event → ViewModel command → repository → new data → ViewModel state → View rebuild.
- Views listen with `ListenableBuilder`. DI with `provider`. Navigation with `go_router`.
- Cross-layer errors use a `Result` type (`Ok` / `Error`); services catch library exceptions and return `Result.error`. No empty `catch`.
- Domain models are immutable (`freezed` or hand-written immutable classes).
- Separate storage/API models from domain models: drift row classes and Supabase JSON never leave `storage` / `sync`; their public API returns plain immutable models.
- Pure-Dart packages must not import Flutter. Never import another package's `src/`.
- Reference implementation: Flutter's Compass sample app.

## Code rules

- `very_good_analysis` + `strict-casts`, `strict-inference`, `strict-raw-types`. Zero analyzer warnings.
- No `dynamic`. No `!` without a comment explaining why the value is non-null.
- No `print`; use `package:logging`. Release builds log warnings and errors only.
- No global mutable state or hand-rolled singletons. Inject `Clock` and `Random`.
- UI strings only via ARB localization (ru, kk, uz, en).
- Names by role: `ReadingScreen`, `ReadingViewModel`, `SessionRepository`, `AsrService`.

## Performance

- Frame budget: ~16 ms at 60 Hz, <8 ms at 120 Hz. Measure in `--profile` on the weakest reference Android phone.
- Keep `build()` cheap; rebuild the smallest subtree; lazy lists only.
- No `Opacity` for text/shapes — draw with a translucent color (hidden mushaf words). Avoid clips and `saveLayer`.
- Each mushaf page in its own `RepaintBoundary`.
- Anything longer than a frame runs off the UI isolate. The reading session runs in a long-lived isolate (request ids, explicit errors, close ports). One-off heavy work: `Isolate.run`.
- Heavy resources (ASR model) load lazily, never at startup.

## Security

- Tokens only in `flutter_secure_storage`. Exclude its file from Android backup; keep the user DB in backup.
- HTTPS only. Verify the content manifest signature (Ed25519) and SHA-256 of every package.
- Unzip safely: reject any archive entry whose normalized path leaves the target directory (zip-slip).
- Validate everything from outside: packages, server responses, deep links.
- Supabase: RLS on every exposed table; one policy per operation `to authenticated`; `(select auth.uid()) = user_id`; index policy columns; pgTAP tests for policies.
- Release builds: `--obfuscate --split-debug-info`.

## Commands

Exact commands are defined in task P01 and must be kept up to date here.

```
fvm flutter pub get
dart format --set-exit-if-changed .
fvm flutter analyze
for dir in packages/*/ tools/*/ app/; do
  [ -d "${dir}test" ] || continue
  if grep -q "sdk: flutter" "${dir}pubspec.yaml"; then
    (cd "$dir" && fvm flutter test)
  else
    (cd "$dir" && fvm dart test)
  fi
done
bash tools/check_deps.sh
(cd app && fvm flutter build apk --debug --target lib/main_dev.dart)
dart run tools/eval         # when follow/check/quran_text changed
```

## Definition of done

- Requirement IDs from the task are implemented and their acceptance criteria are checked.
- Tests added: ViewModels with fake repositories, repositories with fake services, widget tests for screens.
- Format, analyze, tests and dependency-rule check are green.
- Package README updated; ADR written if a decision was made.
- New UI strings exist in all four ARB files or are marked for translation.
- Audio/recognition/UI changes: checked on an emulator, and the PR says "needs owner device check" with what to check on a real phone (cloud agents have no phone).
- PR description: requirement IDs, how it was tested, screenshots for UI changes.

## When unsure

Stop and ask the owner. If a decision is needed, draft an ADR in `docs/adr/` and wait for approval.
