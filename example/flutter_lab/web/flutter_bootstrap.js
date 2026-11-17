{{flutter_js}}
{{flutter_build_config}}

// Retire only this app's deprecated Flutter worker, never another engine's scope.
// The versioned script URL reaches this migration even for previously cached apps.
(async () => {
  if ('serviceWorker' in navigator) {
    try {
      const ownScope = new URL('./', document.baseURI).href;
      const registrations = await navigator.serviceWorker.getRegistrations();
      const own = registrations.filter((entry) => entry.scope === ownScope);
      if (own.length) {
        await Promise.all(own.map((entry) => entry.unregister()));
        window.location.reload();
        return;
      }
    } catch (_) {
      // Storage restrictions must not prevent the laboratory from starting.
    }
  }
  _flutter.loader.load();
})();
