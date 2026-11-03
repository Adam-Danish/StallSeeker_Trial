(() => {
  const release = encodeURIComponent(window.stallSeekerRelease || Date.now());
  function loadScript(src, id) {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = src;
      if (id) script.id = id;
      script.onload = resolve;
      script.onerror = () => reject(new Error('Could not load ' + src));
      document.head.appendChild(script);
    });
  }

  // Download Maps, clustering and Flutter in parallel. Wait for the Maps
  // callback before running Dart so Places cannot inject a second Maps script.
  const mapsReady = loadScript('maps-config.js?v=' + release).then(() =>
    new Promise((resolve, reject) => {
      window.initMap = resolve;
      loadScript('https://maps.googleapis.com/maps/api/js?key=' +
        encodeURIComponent(window.stallSeekerMapsKey) +
        '&libraries=places,marker&v=quarterly&loading=async&callback=initMap',
        'flutter_google_places_sdk_web_script_id').catch(reject);
    })
  );
  window.stallSeekerMapsReady = Promise.all([
    mapsReady,
    loadScript('vendor/markerclusterer-2.5.3.min.js'),
  ]);
  // Attach recovery immediately, even if the Flutter download is still pending.
  window.stallSeekerMapsReady.catch(() => window.stallSeekerStartup.fail(
    'StallSeeker could not load the map. Check your connection and retry.'));
  loadScript('flutter_bootstrap.js?v=' + release).catch(() =>
    window.stallSeekerStartup.fail('StallSeeker could not load. Check your connection and retry.'));
})();
