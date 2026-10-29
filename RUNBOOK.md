# Runbook

## Prerequisites

Flutter stable 3.47 or newer (3.47.8 was used on 2026-10-29) (`flutter --version`). Chrome for the web target. Android Studio or an emulator for Android. Xcode for iOS.

## Develop

```sh
flutter pub get
(cd packages/fusion_core && dart pub get)   # needed once, or analyze reports errors in the engine tests
flutter run -d chrome                 # web, hot reload
flutter run -d <device>               # phone or emulator
tool/check.sh                         # every pre-push check: format, analyze, tests, web build
```

Engine speed check after touching the fusion rules:

```sh
(cd packages/fusion_core && dart run benchmark/recipes_benchmark.dart)
```

## Refresh the game data

```sh
dart run tool/import_smt4.dart                      # downloads the pinned upstream commit
dart run tool/import_smt4.dart --from ../megaten-fusion-tool   # or a local clone
(cd packages/fusion_core && dart test)              # golden recipes must still pass
```

To move to a newer upstream commit, change `upstreamCommit` in `tool/import_smt4.dart`, re-run, and review the diff in `assets/data/smt4/`.

## Build

```sh
flutter build web --release --no-web-resources-cdn --base-href /Demonica/   # GitHub Pages
flutter build apk --release                                                 # Android
flutter build ipa --release                                                 # iOS (needs signing)
```

The web build must copy `index.html` to `404.html` so deep links such as `/smt4/demon/lilith` load on GitHub Pages. The deploy workflow does this.

## Deploy to GitHub Pages

`.github/workflows/deploy-web.yml` builds and publishes when run by hand from the Actions tab (GitHub Actions minutes are limited on the free tier, so nothing runs automatically). One-time setup in the repository: Settings → Pages → Source: "GitHub Actions".

Before every push, run `tool/check.sh` (format, `flutter analyze`, `dart analyze` and `dart test` in `packages/fusion_core`, `flutter test`, `flutter build web --release --no-web-resources-cdn`). The CI workflow does the same and can be run by hand.

## Known limits

- iOS without a paid Apple developer account: install the web app from Safari ("Add to Home Screen"); it works offline after the first load.
- The existing tool's website is blocked from the cloud build environment, so recipe cross-checks are against an independent port of its code plus in-browser spot checks.
