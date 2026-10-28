{{flutter_js}}
{{flutter_build_config}}

// `flutter run` serves CanvasKit through Flutter's CDN; only release builds
// include a local canvaskit/ directory in the generated web bundle.
const releaseBuild = _flutter.buildConfig.builds.some(
  (build) => build.compileTarget === 'dart2js' || build.compileTarget === 'dart2wasm'
);

// Retire Flutter's old offline cache before loading authenticated app code.
// Release assets have versioned URLs; a previous deployment's service worker
// must not mix its cached main bundle with this deployment's deferred code.
async function startApp() {
  try {
    if ('serviceWorker' in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.filter((registration) =>
        [registration.active, registration.waiting, registration.installing]
          .some((worker) => worker && new URL(worker.scriptURL).pathname.endsWith('/flutter_service_worker.js'))
      ).map((registration) => registration.unregister()));
    }
    if ('caches' in window) {
      await Promise.all(['flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest']
        .map((name) => caches.delete(name)));
    }
  } catch (_) {
    // Storage may be unavailable in private browsing; startup can continue.
  }
  _flutter.loader.load({
    config: releaseBuild ? { canvasKitBaseUrl: 'canvaskit/' } : {}
  });
}
startApp();
