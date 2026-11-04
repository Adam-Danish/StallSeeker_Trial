const fs = require('node:fs');
const path = require('node:path');
const cli = 'C:/Users/adama/AppData/Roaming/npm/node_modules/firebase-tools/lib';
const root = path.resolve(__dirname, '../..');
const {getProjectDefaultAccount, setActiveAccount} = require(path.join(cli, 'auth'));
const {requireAuth} = require(path.join(cli, 'requireAuth'));
const {Client} = require(path.join(cli, 'apiv2'));
const project = 'stallseeker-c2ffe';
const backup = path.join(__dirname, 'deployment-backup/cloud');
const original = JSON.parse(fs.readFileSync(path.join(backup, 'indexes.json'), 'utf8'));
const originalNames = new Set(original.map((entry) => entry.name));
const indexFile = path.join(root, 'firestore.indexes.json');
const local = JSON.parse(fs.readFileSync(indexFile, 'utf8'));
const reporting = local.indexes.filter((entry) => ['vendorReports', 'moderationCases'].includes(entry.collectionGroup));
const definition = (entry) => ({collectionGroup: entry.name.split('/')[5], queryScope: entry.queryScope, fields: entry.fields});
// Preserve explicit document-ID ordering. Omitting it changes descending
// directory indexes whose document-ID tie-breaker intentionally sorts ascending.
const desired = [...original.map(definition), ...reporting];
const signature = (entry) => {
  const fields = [...entry.fields];
  if (!fields.some((field) => field.fieldPath === '__name__')) {
    fields.push({fieldPath: '__name__', order: [...fields].reverse().find((field) => field.order)?.order || 'ASCENDING'});
  }
  return JSON.stringify({collectionGroup: entry.collectionGroup, queryScope: entry.queryScope, fields});
};
const wanted = new Set(desired.map(signature));
(async () => {
  const options = {project, projectId: project, nonInteractive: true};
  setActiveAccount(options, getProjectDefaultAccount(root));
  await requireAuth(options);
  const client = new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1', auth: true});
  const current = (await client.get(`/projects/${project}/databases/(default)/collectionGroups/-/indexes`)).body.indexes || [];
  const extras = current.filter((entry) => !originalNames.has(entry.name) && !wanted.has(signature(definition(entry))));
  if (extras.some((entry) => !entry.name.includes('/collectionGroups/adminDirectory/'))) throw new Error('Unexpected extra index collection; no cleanup performed.');
  const plan = {originalIndexesPreserved: original.length, reportingIndexes: reporting.length,
    temporaryDuplicateIndexes: extras.map((entry) => ({name: entry.name, fields: entry.fields})),
    note: 'Only duplicates created during this deployment are eligible for removal. Pre-existing index IDs and all reporting indexes are excluded.'};
  fs.writeFileSync(path.join(__dirname, 'index-preservation-audit.json'), JSON.stringify(plan, null, 2));
  local.indexes = desired;
  fs.writeFileSync(indexFile, JSON.stringify(local, null, 2) + '\n');
  console.log(JSON.stringify({originalIndexesPreserved: original.length, reportingIndexes: reporting.length,
    deploymentCreatedDuplicates: extras.length, action: process.argv[2] === 'clean' ? 'remove-own-duplicates' : 'read-only-audit'}));
  if (process.argv[2] === 'clean') {
    for (const entry of extras) {
      if (originalNames.has(entry.name)) throw new Error('Refusing to remove pre-existing index.');
      await client.delete('/' + entry.name);
    }
    console.log('Removed only the temporary duplicate indexes created by this deployment.');
  }
})().catch((error) => { console.error(error.message); process.exitCode = 1; });
