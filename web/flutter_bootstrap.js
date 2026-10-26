{{flutter_js}}
{{flutter_build_config}}

// `flutter run` serves CanvasKit through Flutter's CDN; only release builds
// include a local canvaskit/ directory in the generated web bundle.
const releaseBuild = _flutter.buildConfig.builds.some(
  (build) => build.compileTarget === 'dart2js' || build.compileTarget === 'dart2wasm'
);

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  },
  config: releaseBuild ? { canvasKitBaseUrl: 'canvaskit/' } : {}
});
