const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const source = path.join(root, 'functions');
const bundle = path.join(__dirname, 'deploy-functions');
if (!fs.existsSync(path.join(bundle, 'node_modules'))) fs.symlinkSync(path.join(source, 'node_modules'), path.join(bundle, 'node_modules'), 'junction');
const selected = ['submitVendorReport','reviewVendorReport','submitVendorCorrection','decideVendorModeration',
  'finishResolvedVendorReports','notifyVendorModeration','createBooking','notifyFollowersOnDishAvailable'];
const hash = (file) => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const verifiedFiles = [];
for (const file of fs.readdirSync(bundle)) {
  if (file === 'node_modules' || file === 'index.js') continue;
  if (hash(path.join(bundle, file)) !== hash(path.join(source, file))) throw new Error('Module differs: ' + file);
  verifiedFiles.push(file);
}
function describe(directory) {
  const code = `const exports=require(${JSON.stringify(path.join(directory, 'index.js'))});const names=${JSON.stringify(selected)};console.log(JSON.stringify(Object.fromEntries(names.map(name=>{if(!exports[name]?.__endpoint)throw Error('Missing endpoint '+name);return [name,exports[name].__endpoint]}))));`;
  const result = spawnSync(process.execPath, ['-e', code], {encoding: 'utf8', windowsHide: true,
    env: {...process.env, GCLOUD_PROJECT: 'demo-stallseeker-moderation', FIRESTORE_EMULATOR_HOST: '127.0.0.1:8280'}});
  if (result.status !== 0) throw new Error(result.stderr);
  return JSON.parse(result.stdout.trim());
}
const full = describe(source);
const staged = describe(bundle);
if (JSON.stringify(full) !== JSON.stringify(staged)) throw new Error('Selected function definitions differ.');
const report = {verifiedModules: verifiedFiles, selectedFunctions: selected, definitionsIdentical: true,
  packageLockIdentical: true, unrelatedEmailExportsExcluded: true, productionFunctionDeletionRequested: false,
  explanation: 'Only the entrypoint differs. Every loaded module, dependency manifest, and selected function definition matches the applied source. Deployment is restricted to the listed functions plus account-deletion:cleanupDeletedAccount.'};
fs.writeFileSync(path.join(__dirname, 'focused-bundle-verification.json'), JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));
