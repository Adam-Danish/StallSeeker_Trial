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
  let nextTimer = 0;
  const failures = [];
  const context = vm.createContext({
    document: {head, body: new Element(), getElementById: () => status,
      createElement: tag => tag === 'script' ? new Script() : new Element()},
    HTMLScriptElement: Script, console: {error() {}}, encodeURIComponent,
    setTimeout: (callback, delay) => {
      const id = ++nextTimer;
      timers.set(id, {callback, delay});
      return id;
    },
    clearTimeout: id => timers.delete(id),
    addEventListener: (name, callback) => events[name] = callback,
    removeEventListener: (name, callback) => {
      if (events[name] === callback) delete events[name];
    },
    innerWidth: 390,
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

test('an active tab edge swipe is handled in the app without browser Back', () => {
  const b = browser();
  b.run(indexScript());
  let hasHistory = true;
  let backs = 0;
  let prevented = 0;
  const unregister = b.context.stallSeekerRegisterTabBackGesture(
    fromLeft => fromLeft && hasHistory,
    () => backs++,
  );
  const touch = (clientX, clientY) => ({identifier: 1, clientX, clientY});
  const begin = (x, y) => b.events.touchstart({
    cancelable: true, touches: [touch(x, y)], preventDefault: () => prevented++,
  });
  const end = (x, y) => b.events.touchend({touches: [], changedTouches: [touch(x, y)]});

  begin(40, 200);
  end(150, 200);
  assert.equal(prevented, 0);
  assert.equal(backs, 0);

  begin(5, 200);
  end(8, 300);
  begin(5, 200);
  b.events.touchcancel();
  end(150, 200);
  assert.equal(backs, 0);

  begin(5, 200);
  assert.equal(prevented, 3);
  end(100, 210);
  assert.equal(backs, 1);

  hasHistory = false;
  begin(5, 200);
  end(150, 200);
  assert.equal(prevented, 3);
  assert.equal(backs, 1);
  unregister();
  assert.equal(b.events.touchstart, undefined);
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
  b.context.stallSeekerLoadMaps().then(() => ready = true);
  scripts[0].onload();
  scripts[1].onload();
  await flush();
  const maps = scripts[3];
  assert.equal(maps.id, 'flutter_google_places_sdk_web_script_id');
  await flush();
  assert.equal(ready, false);
  b.context.stallSeekerMapsLoaded1();
  await flush();
  assert.equal(ready, true);
  await b.context.stallSeekerLoadMaps();
  assert.equal(scripts.length, 4);
});

test('a blocked Maps request supports retry while Flutter continues loading', async () => {
  const b = browser();
  b.run(indexScript());
  b.run(source('maps-bootstrap.js'));
  const result = assert.rejects(b.context.stallSeekerLoadMaps(), /Could not load/);
  b.head.children[0].onload();
  await flush();
  const maps = b.head.children[3];
  b.events.error({target: maps});
  maps.onerror();
  await result;
  assert.equal(b.status.children.length, 0);
  assert.equal(maps.removed, true);
  const retried = b.context.stallSeekerLoadMaps();
  b.head.children[4].onload();
  await flush();
  b.head.children[1].onload();
  b.context.stallSeekerMapsLoaded2();
  await retried;
});

test('a Maps script that never responds releases the map loader', async () => {
  const b = browser();
  b.run(source('maps-bootstrap.js'));
  const result = assert.rejects(b.context.stallSeekerLoadMaps(), /Could not load/);
  const [configTimeout] = b.timers.values();
  assert.equal(configTimeout.delay, 15000);
  configTimeout.callback();
  await result;
  assert.equal(b.head.children[0].removed, true);
  assert.equal(b.failures.length, 0);
});

test('Flutter starts while Maps is still pending', async () => {
  const b = browser();
  let options;
  b.context._flutter = {buildConfig: {builds: [{mainJsPath: 'main.dart.js'}]},
    loader: {load: opts => {options = opts; return Promise.resolve();}}};
  b.context.stallSeekerLoadMaps = () => new Promise(() => {});
  b.run(bootstrap());
  assert.equal(options.config.canvasKitBaseUrl, 'canvaskit/');
  assert.equal(b.context._flutter.buildConfig.builds[0].mainJsPath, 'main.dart.js?v=test-release');
  let initialized = false, started = false;
  await options.onEntrypointLoaded({initializeEngine: async () => {
    initialized = true;
    return {runApp: async () => started = true};
  }});
  assert.equal(initialized, true);
  assert.equal(started, true);
});

test('engine initialization errors reach the recovery screen', async () => {
  const b = browser();
  let options;
  b.context._flutter = {buildConfig: {builds: []},
    loader: {load: opts => {options = opts; return Promise.resolve();}}};
  b.run(bootstrap());
  await options.onEntrypointLoaded({initializeEngine: async () => {throw Error('Blocked engine');}});
  assert.match(b.failures[0], /could not start/);
});
