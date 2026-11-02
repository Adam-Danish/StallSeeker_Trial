// Load Google Maps once for both maps and Places, before Flutter creates a map.
window.initMap = function () {
  const flutterScript = document.createElement('script');
  flutterScript.src = 'flutter_bootstrap.js';
  document.body.appendChild(flutterScript);
};
window.addEventListener('flutter-first-frame', function () {
  document.getElementById('web-startup')?.remove();
});
const mapsScript = document.createElement('script');
mapsScript.id = 'flutter_google_places_sdk_web_script_id';
mapsScript.src = 'https://maps.googleapis.com/maps/api/js?key=' +
    encodeURIComponent(window.stallSeekerMapsKey) +
    '&libraries=places,marker&v=quarterly&loading=async&callback=initMap';
mapsScript.onerror = function () {
  const status = document.getElementById('web-startup');
  status.textContent = 'StallSeeker could not load. Check your connection and ';
  const retry = document.createElement('button');
  retry.textContent = 'Retry';
  retry.onclick = function () { window.location.reload(); };
  status.appendChild(retry);
};
document.head.appendChild(mapsScript);
