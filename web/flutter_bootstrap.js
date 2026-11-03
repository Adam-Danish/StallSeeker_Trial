{{flutter_js}}
{{flutter_build_config}}

// A previously cached main.dart.js may still have a long cache lifetime from
// an older deployment. Give every build its own entrypoint URL so refreshing
// an existing browser tab loads the release that belongs to this bootstrap.
for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath && window.stallSeekerRelease) {
    build.mainJsPath += '?v=' + encodeURIComponent(window.stallSeekerRelease);
  }
}
// Serve the rendering engine with the app instead of waiting on another CDN.
const config = {canvasKitBaseUrl: 'canvaskit/'};
_flutter.loader.load({
  config,
  onEntrypointLoaded: async function (engineInitializer) {
    try {
      const [appRunner] = await Promise.all([
        engineInitializer.initializeEngine(config),
        window.stallSeekerMapsReady,
      ]);
      await appRunner.runApp();
    } catch (error) {
      console.error('StallSeeker startup failed:', error);
      window.stallSeekerStartup.fail('StallSeeker could not start. Check your connection and retry.');
    }
  },
}).catch((error) => {
  console.error('StallSeeker loader failed:', error);
  window.stallSeekerStartup.fail('StallSeeker could not load. Check your connection and retry.');
});
