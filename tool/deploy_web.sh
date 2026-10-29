#!/usr/bin/env bash
# Builds the web app and publishes it to the gh-pages branch, which GitHub
# Pages serves (Settings > Pages > Source: "Deploy from a branch", gh-pages).
# No GitHub Actions minutes are used. tool/release.sh calls this script.
#
# Usage: tool/deploy_web.sh [--dry-run]
#   --dry-run  build and prepare the branch, but do not push
set -euo pipefail
cd "$(dirname "$0")/.."

dry_run=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

remote_url=$(git remote get-url origin)
# Works for https://github.com/owner/repo(.git) and git@github.com:owner/repo.git
owner=$(sed -E 's#(\.git)?/*$##; s#.*[:/]([^/]+)/[^/]+$#\1#' <<<"$remote_url")
repo_name=$(sed -E 's#(\.git)?/*$##; s#.*/##' <<<"$remote_url")
author_name=$(git config user.name || echo Demonica)
author_email=$(git config user.email || echo demonica@localhost)
commit=$(git rev-parse --short HEAD)
version=$(sed -nE 's/^version:[[:space:]]*([0-9.]+).*/\1/p' pubspec.yaml)

printf '\n== web build (base href /%s/)\n' "$repo_name"
flutter build web --release --no-web-resources-cdn --base-href "/$repo_name/"
# GitHub Pages has no SPA fallback: serving index.html as 404.html makes deep
# links such as /smt4/demon/lilith load. .nojekyll stops Jekyll from hiding
# files that start with an underscore.
cp build/web/index.html build/web/404.html
touch build/web/.nojekyll

printf '\n== gh-pages branch\n'
staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT
cp -R build/web/. "$staging"
(
  cd "$staging"
  git init -q -b gh-pages
  git add -A
  git -c user.name="$author_name" -c user.email="$author_email" commit -q -m "Deploy web $version ($commit)"
  # The branch only holds the latest build, so it is replaced each time.
  if $dry_run; then
    echo "Dry run: would force-push $(git rev-parse --short HEAD) to gh-pages on $remote_url"
  else
    git push -q --force "$remote_url" gh-pages:gh-pages
    echo "Pushed. Live in a minute or two at https://$owner.github.io/$repo_name/"
  fi
)
