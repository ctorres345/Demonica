#!/usr/bin/env bash
# Publishes the version in pubspec.yaml: runs every check, builds the Android
# APK (and an unsigned iOS IPA on a Mac), tags vX.Y.Z, creates the GitHub
# Release with the CHANGELOG notes and the files attached, and deploys the web
# app to GitHub Pages. Runs on your machine; no GitHub Actions minutes needed.
#
# Before running: bump the version and move the CHANGELOG lines (see
# CONTRIBUTING.md, "Releasing a version") in a PR. After it is merged, run
# `git checkout main && git pull`: the script needs main to match origin/main.
#
# Usage: tool/release.sh [--dry-run] [--skip-web] [--skip-android] [--skip-ios]
#                        [--allow-debug-key]
#   --dry-run       build everything, but do not tag, push, release or deploy
#   --skip-web      do not deploy the web app
#   --skip-android  do not build or attach the APK
#   --skip-ios      do not build or attach the unsigned IPA
#   --allow-debug-key  publish an APK signed with the debug key (not for real
#                   releases: users could not update it to a properly signed one)
set -euo pipefail
cd "$(dirname "$0")/.."

dry_run=false
web=true
android=true
ios=true
allow_debug_key=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --skip-web) web=false ;;
    --skip-android) android=false ;;
    --skip-ios) ios=false ;;
    --allow-debug-key) allow_debug_key=true ;;
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
if $android && [[ ! -f android/key.properties ]]; then
  # The first published APK fixes the signing key for good: an APK signed
  # with another key cannot update it.
  if $dry_run || $allow_debug_key; then
    warn "android/key.properties missing: the APK is signed with the debug key"
  else
    fail "android/key.properties missing (RUNBOOK.md, 'Android signing'), or pass --allow-debug-key"
  fi
fi
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
# Blank lines at the start and end of the section are dropped.
awk -v v="$version" '
  $0 ~ "^## " v " \\(" { on = 1; next }
  on && /^## / { exit }
  on && !NF { blank++; next }
  on { if (seen) for (i = 0; i < blank; i++) print ""; blank = 0; seen = 1; print }
' CHANGELOG.md >"$out/notes.md"
cat >>"$out/notes.md" <<EOF

**Install:** Android: download the APK below and open it (allow installs from your browser when asked). iPhone and desktop: use the web app and add it to your home screen, see the README.
EOF

if $android; then
  step 'android apk'
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

# gh creates the tag on GitHub together with the release, so a failed
# upload leaves no tag behind to clean up.
step "github release $tag"
gh release create "$tag" ${assets[@]+"${assets[@]}"} --target "$(git rev-parse HEAD)" \
  --title "Demonica $version" --notes-file "$out/notes.md"
git fetch -q origin --tags

if $web; then
  step 'web deploy'
  tool/deploy_web.sh
fi

printf '\nReleased %s.\n' "$tag"
