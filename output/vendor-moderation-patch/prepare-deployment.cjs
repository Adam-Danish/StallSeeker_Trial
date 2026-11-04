const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const indexFile = path.join(root, 'firestore.indexes.json');
const local = JSON.parse(fs.readFileSync(indexFile, 'utf8'));
const live = JSON.parse(fs.readFileSync(path.join(__dirname, 'deployment-backup/cloud/index-config.json'), 'utf8')).result;
if (!Array.isArray(live.indexes)) throw new Error('Live index backup is invalid.');
function definition(index) {
  return {collectionGroup: index.collectionGroup, queryScope: index.queryScope,
    fields: index.fields.filter((field) => field.fieldPath !== '__name__')};
}
const signature = (index) => JSON.stringify(definition(index));
const known = new Set(local.indexes.map(signature));
let added = 0;
for (const index of live.indexes) {
  if (!known.has(signature(index))) {
    local.indexes.push(definition(index)); known.add(signature(index)); added++;
  }
}
let fieldOverrides = 0;
for (const field of live.fieldOverrides || []) {
  const existing = local.fieldOverrides.find((entry) => entry.collectionGroup === field.collectionGroup && entry.fieldPath === field.fieldPath);
  if (!existing) { local.fieldOverrides.push(field); fieldOverrides++; }
  else {
    for (const index of field.indexes || []) {
      if (!(existing.indexes || []).some((entry) => JSON.stringify(entry) === JSON.stringify(index))) {
        (existing.indexes ||= []).push(index);
      }
    }
    if (field.ttl) existing.ttl = field.ttl;
  }
}
fs.writeFileSync(indexFile, JSON.stringify(local, null, 2) + '\n');
fs.writeFileSync(path.join(__dirname, 'deployment-emulators.json'), JSON.stringify({
  firestore: {rules: path.join(root, 'firestore.rules'), indexes: indexFile},
  storage: {rules: path.join(root, 'storage.rules')},
  emulators: {firestore: {port: 8280}, storage: {port: 9299}, ui: {enabled: false}, singleProjectMode: false},
}, null, 2));
console.log(JSON.stringify({preservedAdditionalLiveIndexes: added, preservedAdditionalFieldOverrides: fieldOverrides,
  totalIndexes: local.indexes.length}));
