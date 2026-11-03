const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const {resolve} = require('node:path');
const {test} = require('node:test');
const vm = require('node:vm');

const source = name => readFileSync(resolve(__dirname, '../web', name), 'utf8');
const flush = () => new Promise(resolve => setImmediate(resolve));
function browser() {
  class Element {
    children = [];
    style = {};
    append(...children) { this.children.push(...children); }
    appendChild(child) { this.append(child); }
    replaceChildren(...children) { this.children = children; }
    remove() { this.removed = true; }
  }
  class Script extends Element {}
  const status = new Element();
  const head = new Element();
  const events = {};
  const timers = new Map();
  const failures = [];
  const context = vm.createContext({
    document: {head, body: new Element(), getElementById: () => status,
      createElement: tag => tag === 'script' ? new Script() : new Element()},
    HTMLScriptElement: Script, console: {error() {}}, encodeURIComponent,
    setTimeout: (callback, delay) => {timers.set(1, {callback, delay}); return 1;},
    clearTimeout: id => timers.delete(id),
    addEventListener: (name, callback) => events[name] = callback,
    location: {reload() { context.reloaded = true; }},
    stallSeekerRelease: 'test-release',
    stallSeekerStartup: {fail: message => failures.push(message)},
  });
  context.window = context;
  return {context, status, head, events, timers, failures,
    run: script => vm.runInContext(script, context)};
}
const indexScript = () => source('index.html').match(/<script>([\s\S]*?)<\/script>/)[1]
  .replace('{{flutter_service_worker_version}}', '"test-release"');
const bootstrap = () => source('flutter_bootstrap.js')
  .replace('{{flutter_js}}', '').replace('{{flutter_build_config}}', '');

test('startup timeout offers a working retry instead of an endless loader', () => {
  const b = browser();
  b.run(indexScript());
  assert.equal(b.timers.get(1).delay, 45000);
  b.timers.get(1).callback();
  assert.match(b.status.children[0].textContent, /longer than expected/);
  const retry = b.status.children[1];
  assert.equal(retry.textContent, 'Retry');
  retry.onclick();
  assert.equal(b.context.reloaded, true);
});

test('the first frame removes the loader and cancels the timeout', () => {
  const b = browser();
  b.run(indexScript());
  b.events['flutter-first-frame']();
  assert.equal(b.status.removed, true);
  assert.equal(b.timers.size, 0);
  b.events.unhandledrejection();
  assert.equal(b.status.children.length, 0);
});

test('failure to download the initial loader immediately offers retry', () => {
  const b = browser();
  b.run(indexScript());
  const script = b.context.document.createElement('script');
  b.events.error({target: script});
  assert.match(b.status.children[0].textContent, /could not download/);
  assert.equal(b.status.children[1].textContent, 'Retry');
});

test('Flutter downloads alongside Maps; map readiness waits for its callback', async () => {
  const b = browser();
  b.run(source('maps-bootstrap.js'));
  const scripts = b.head.children;
  assert.equal(scripts.length, 3);
  assert.match(scripts[0].src, /^maps-config.js\?v=test-release/);
  assert.match(scripts[1].src, /^vendor\//);
  assert.match(scripts[2].src, /^flutter_bootstrap.js\?v=test-release/);
  let ready = false;
  b.context.stallSeekerMapsReady.then(() => ready = true);
  scripts[0].onload();
  scripts[1].onload();
  await flush();
  const maps = scripts[3];
  assert.equal(maps.id, 'flutter_google_places_sdk_web_script_id');
  maps.onload();
  await flush();
  assert.equal(ready, false);
  b.context.initMap();
  await flush();
  assert.equal(ready, true);
  b.context.initMap();
  assert.equal(scripts.length, 4);
});

test('a blocked Maps request reports failure even before Flutter downloads', async () => {
  const b = browser();
  b.run(source('maps-bootstrap.js'));
  b.head.children[0].onload();
  await flush();
  b.head.children[3].onerror();
  await flush();
  assert.match(b.failures[0], /could not load the map/);
});

test('engine initializes in parallel but Dart starts only after Maps is ready', async () => {
  const b = browser();
  let options, resolveMaps;
  b.context._flutter = {buildConfig: {builds: [{mainJsPath: 'main.dart.js'}]},
    loader: {load: opts => {options = opts; return Promise.resolve();}}};
  b.context.stallSeekerMapsReady = new Promise(resolve => resolveMaps = resolve);
  b.run(bootstrap());
  assert.equal(options.config.canvasKitBaseUrl, 'canvaskit/');
  assert.equal(b.context._flutter.buildConfig.builds[0].mainJsPath, 'main.dart.js?v=test-release');
  let initialized = false, started = false;
  const loading = options.onEntrypointLoaded({initializeEngine: async () => {
    initialized = true;
    return {runApp: async () => started = true};
  }});
  await flush();
  assert.equal(initialized, true);
  assert.equal(started, false);
  resolveMaps();
  await loading;
  assert.equal(started, true);
});

test('engine initialization errors reach the recovery screen', async () => {
  const b = browser();
  let options;
  b.context._flutter = {buildConfig: {builds: []},
    loader: {load: opts => {options = opts; return Promise.resolve();}}};
  b.context.stallSeekerMapsReady = Promise.resolve();
  b.run(bootstrap());
  await options.onEntrypointLoaded({initializeEngine: async () => {throw Error('Blocked engine');}});
  assert.match(b.failures[0], /could not start/);
});
