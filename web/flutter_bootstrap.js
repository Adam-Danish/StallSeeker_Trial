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
_flutter.loader.load();
