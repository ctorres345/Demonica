{{flutter_js}}
{{flutter_build_config}}

// Flutter's own service worker no longer caches anything, so Demonica
// registers sw.js (network first, cached copy when offline) instead. The URL
// is resolved against <base href> so deep links register the same worker.
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register(new URL('sw.js', document.baseURI));
  });
}

_flutter.loader.load();
