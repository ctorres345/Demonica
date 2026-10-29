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
flutter build ios --release --no-codesign                                   # iOS, unsigned (Mac only)
```

The web build must copy `index.html` to `404.html` so deep links such as `/smt4/demon/lilith` load on GitHub Pages. `tool/deploy_web.sh` does this.

The web app works offline after the first visit: `web/sw.js` is a small service worker (network first, last good copy when offline), registered from `web/flutter_bootstrap.js`. Flutter's own service worker no longer caches anything.

## Release

Everything runs on your Mac with one script. GitHub Actions is not used (no free minutes left).

1. Bump the version and move the CHANGELOG lines (CONTRIBUTING.md, "Releasing a version"). Commit and push `main`.
2. Try it first: `tool/release.sh --dry-run`. It runs `tool/check.sh`, builds the APK and the unsigned IPA into `build/release/`, writes the release notes, and publishes nothing.
3. Release: `tool/release.sh`. It tags `vX.Y.Z`, creates the GitHub Release with the CHANGELOG section as notes and the APK and IPA attached, then deploys the web app.

Options: `--skip-web`, `--skip-android`, `--skip-ios`. A real release refuses to run without the Android signing key (see "Android signing"); `--allow-debug-key` overrides that for test builds only. The script stops before publishing if you are not on an up-to-date, clean `main`, the tag exists, the CHANGELOG has no heading for the version, or `gh` is not signed in.

Needs: Flutter, the Android SDK (Android Studio), Xcode for the IPA, and the GitHub CLI signed in once (`brew install gh`, then `gh auth login`).

## Deploy to GitHub Pages

`tool/deploy_web.sh` builds the web app with `--base-href /Demonica/` and force-pushes it to the `gh-pages` branch, which only ever holds the latest build. `tool/release.sh` runs it; run it alone to redeploy without a new version. Add `--dry-run` to build without pushing.

Repository setup (done on 2026-10-29; Pages on the free plan needs a public repository): Settings → Pages → Source: "Deploy from a branch", Branch `gh-pages`, folder `/ (root)`.

The app is then at https://ctorres345.github.io/Demonica/ a minute or two after each deploy.

## Android signing

Release APKs are signed with the key described in `android/key.properties`. Without that file, `flutter build apk` signs with the debug key and `tool/release.sh` stops, because an APK signed with one key cannot update an APK signed with another. Create the key once and **back up the `.jks` file and passwords**: losing them means users have to uninstall to update.

```sh
keytool -genkey -v -keystore ~/keys/demonica-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias demonica
```

Then create `android/key.properties` (git ignores it, along with `*.jks`):

```properties
storePassword=<the keystore password>
keyPassword=<the key password>
keyAlias=demonica
storeFile=/Users/<you>/keys/demonica-upload.jks
```

## iOS

Without a paid Apple developer account there is no way to install a native build directly, so iPhone users get the web app: open the Pages URL in Safari, tap Share → "Add to Home Screen". It opens full screen with the Demonica icon and works offline after the first visit. The release also attaches an unsigned IPA for people who re-sign apps themselves (AltStore, Sideloadly).

Before every push, run `tool/check.sh` (format, `flutter analyze`, `dart analyze` and `dart test` in `packages/fusion_core`, `flutter test`, `flutter build web --release --no-web-resources-cdn`). The CI workflow does the same and can be run by hand, but it spends Actions minutes.

## Known limits

- iOS without a paid Apple developer account: install the web app from Safari ("Add to Home Screen"); see "iOS" above.
- Recipe cross-checks are against an independent port of megaten-fusion-tool's code plus in-browser spot checks.
