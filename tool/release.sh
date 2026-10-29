#!/usr/bin/env bash
# Publishes the version in pubspec.yaml: runs every check, builds the Android
# APK (and an unsigned iOS IPA on a Mac), tags vX.Y.Z, creates the GitHub
# Release with the CHANGELOG notes and the files attached, and deploys the web
# app to GitHub Pages. Runs on your machine; no GitHub Actions minutes needed.
#
# Before running: bump the version and move the CHANGELOG lines (see
# CONTRIBUTING.md, "Releasing a version"), commit, and push main.
#
# Usage: tool/release.sh [--dry-run] [--skip-web] [--skip-android] [--skip-ios]
#   --dry-run       build everything, but do not tag, push, release or deploy
#   --skip-web      do not deploy the web app
#   --skip-android  do not build or attach the APK
#   --skip-ios      do not build or attach the unsigned IPA
set -euo pipefail
cd "$(dirname "$0")/.."

dry_run=false
web=true
android=true
ios=true
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --skip-web) web=false ;;
    --skip-android) android=false ;;
    --skip-ios) ios=false ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done
[[ "$(uname)" == Darwin ]] || ios=false

step() { printf '\n== %s\n' "$1"; }
fail() { printf '\nRelease stopped: %s\n' "$1" >&2; exit 1; }
warn() { printf 'Warning: %s\n' "$1" >&2; }

version=$(sed -nE 's/^version:[[:space:]]*([0-9.]+).*/\1/p' pubspec.yaml)
tag="v$version"
out="build/release"

step "preflight for $tag"
[[ -n "$version" ]] || fail "no version in pubspec.yaml"
[[ "$(git rev-parse --abbrev-ref HEAD)" == main ]] || fail "not on main"
[[ -z "$(git status --porcelain)" ]] || fail "uncommitted changes (commit or stash them first)"
git fetch -q origin main --tags
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || fail "main is not the same as origin/main (push or pull first)"
git rev-parse -q --verify "refs/tags/$tag" >/dev/null && fail "tag $tag already exists (bump the version)"
grep -q "^## $version (" CHANGELOG.md || fail "CHANGELOG.md has no '## $version (date)' heading"
if ! $dry_run; then
  command -v gh >/dev/null || fail "GitHub CLI not found (brew install gh)"
  gh auth status >/dev/null 2>&1 || fail "GitHub CLI is not signed in (gh auth login)"
fi

step 'checks'
tool/check.sh

rm -rf "$out"
mkdir -p "$out"
assets=()

# Release notes: the CHANGELOG section for this version.
awk -v v="$version" '
  $0 ~ "^## " v " \\(" { on = 1; next }
  on && /^## / { exit }
  on { print }
' CHANGELOG.md | sed -e '/./,$!d' >"$out/notes.md"
cat >>"$out/notes.md" <<EOF

**Install:** Android: download the APK below and open it (allow installs from your browser when asked). iPhone and desktop: use the web app and add it to your home screen, see the README.
EOF

if $android; then
  step 'android apk'
  [[ -f android/key.properties ]] || warn "android/key.properties missing: the APK is signed with the debug key, so it cannot update an APK signed with your release key (RUNBOOK.md, 'Android signing')"
  flutter build apk --release
  cp build/app/outputs/flutter-apk/app-release.apk "$out/demonica-$version.apk"
  assets+=("$out/demonica-$version.apk")
fi

if $ios; then
  step 'ios ipa (unsigned, best effort)'
  # Without a paid Apple account the IPA cannot be installed directly; it is
  # attached for people who re-sign apps themselves (AltStore, Sideloadly).
  if flutter build ios --release --no-codesign; then
    rm -rf "$out/Payload"
    mkdir -p "$out/Payload"
    cp -R build/ios/iphoneos/Runner.app "$out/Payload/"
    (cd "$out" && zip -qr "demonica-$version-unsigned.ipa" Payload && rm -rf Payload)
    assets+=("$out/demonica-$version-unsigned.ipa")
  else
    warn "iOS build failed, continuing without the IPA"
  fi
fi

if $dry_run; then
  step 'dry run: nothing published'
  echo "Would tag $tag at $(git rev-parse --short HEAD) and create the release with:"
  printf '  %s\n' "${assets[@]:-"(no files)"}"
  echo "Notes: $out/notes.md"
  $web && tool/deploy_web.sh --dry-run
  exit 0
fi

step "tag $tag"
git tag -a "$tag" -m "Demonica $version"
git push -q origin "$tag"

step 'github release'
gh release create "$tag" ${assets[@]+"${assets[@]}"} --title "Demonica $version" --notes-file "$out/notes.md"

if $web; then
  step 'web deploy'
  tool/deploy_web.sh
fi

printf '\nReleased %s.\n' "$tag"
