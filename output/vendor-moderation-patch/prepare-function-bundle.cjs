const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const source = path.join(root, 'functions');
const destination = path.join(__dirname, 'deploy-functions');
fs.mkdirSync(destination, {recursive: true});
const copied = new Set();
function copyModule(name) {
  if (copied.has(name)) return;
  const file = path.join(source, name);
  const content = fs.readFileSync(file, 'utf8');
  copied.add(name);
  fs.writeFileSync(path.join(destination, name), content);
  for (const match of content.matchAll(/require\(['"]\.\/([^'"]+)['"]\)/g)) {
    let relative = match[1];
    if (!path.extname(relative)) relative += '.js';
    copyModule(relative);
  }
}
for (const name of ['moderation.cjs', 'bookings.cjs', 'dish-notifications.cjs']) copyModule(name);
for (const name of ['package.json', 'package-lock.json']) fs.copyFileSync(path.join(source, name), path.join(destination, name));
fs.writeFileSync(path.join(destination, 'index.js'), [
  "require('firebase-admin/app').initializeApp();",
  "Object.assign(exports, require('./moderation.cjs'));",
  "exports.createBooking = require('./bookings.cjs').createBooking;",
  "exports.notifyFollowersOnDishAvailable = require('./dish-notifications.cjs').notifyFollowersOnDishAvailable;",
  '',
].join('\n'));
const configuration = {functions: [
  {codebase: 'default', source: destination, disallowLegacyRuntimeConfig: true,
    ignore: ['node_modules', '.git', '*.test.cjs', 'firebase-debug*']},
  {codebase: 'account-deletion', source: path.join(root, 'functions-account'), disallowLegacyRuntimeConfig: true,
    ignore: ['node_modules', '.git', '*.test.cjs', 'firebase-debug*']},
]};
fs.writeFileSync(path.join(__dirname, 'functions-deploy.json'), JSON.stringify(configuration, null, 2));
console.log('Prepared focused deployment bundle with ' + copied.size + ' shared modules.');
