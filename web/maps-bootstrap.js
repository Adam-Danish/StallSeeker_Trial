(() => {
  const release = encodeURIComponent(window.stallSeekerRelease || Date.now());
  function loadScript(src, {id, optional = false, callback} = {}) {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = src;
      if (id) script.id = id;
      script.stallSeekerOptional = optional;
      const timeout = optional ? setTimeout(fail, 15000) : null;
      function fail() {
        if (timeout !== null) clearTimeout(timeout);
        if (callback) delete window[callback];
        script.remove();
        reject(new Error('Could not load ' + src.split('?')[0]));
      }
      const finish = () => {
        if (timeout !== null) clearTimeout(timeout);
        resolve();
      };
      if (callback) window[callback] = finish;
      else script.onload = finish;
      script.onerror = fail;
      document.head.appendChild(script);
    });
  }

  let maps;
  let clusters;
  let attempt = 0;
  window.stallSeekerLoadMaps = () => {
    maps ??= loadScript('maps-config.js?v=' + release, {optional: true}).then(() => {
      const callback = 'stallSeekerMapsLoaded' + ++attempt;
      return loadScript('https://maps.googleapis.com/maps/api/js?key=' +
        encodeURIComponent(window.stallSeekerMapsKey) +
        '&libraries=places,marker&v=quarterly&loading=async&callback=' + callback,
        {id: 'flutter_google_places_sdk_web_script_id', optional: true, callback});
    }).catch(error => {
      maps = undefined;
      throw error;
    });
    clusters ??= loadScript('vendor/markerclusterer-2.5.3.min.js', {optional: true})
      .catch(error => {
        clusters = undefined;
        throw error;
      });
    return Promise.all([maps, clusters]);
  };
  // Start both downloads immediately. The map widgets handle loading and retry.
  window.stallSeekerLoadMaps().catch(() => {});
  loadScript('flutter_bootstrap.js?v=' + release).catch(() =>
    window.stallSeekerStartup.fail('StallSeeker could not load. Check your connection and retry.'));
})();
