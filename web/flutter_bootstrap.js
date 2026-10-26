{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  },
  config: {
    // Keep the renderer on the same origin as the application.
    canvasKitBaseUrl: 'canvaskit/'
  }
});
