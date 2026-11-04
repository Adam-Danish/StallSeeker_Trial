const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const admin = path.resolve(root, '../StallSeeker-Admin');
const scratch = 'C:/Users/adama/.codex/visualizations/2026/11/04/01a1a518-bf8f-7e01-bc05-ddceb50f9eef/reporting-release-patch-build';
if (fs.existsSync(scratch)) throw new Error('Scratch path already exists.');
fs.mkdirSync(scratch, {recursive: true});
const manifest = JSON.parse(fs.readFileSync(path.join(__dirname, 'deployment-backup/manifest.json'), 'utf8'));
const patchManifest = JSON.parse(fs.readFileSync(path.join(__dirname, 'patch-manifest.json'), 'utf8'));
function git(cwd, args) {
  const result = spawnSync('git', args, {cwd, encoding: 'utf8', windowsHide: true, maxBuffer: 10 * 1024 * 1024});
  if (result.status !== 0) throw new Error(result.stderr);
  return result.stdout;
}
for (const [project, current] of [['app', root], ['admin', admin]]) {
  const directory = path.join(scratch, project); fs.mkdirSync(directory);
  git(directory, ['init', '--quiet']); git(directory, ['config', 'core.autocrlf', 'true']);
  git(directory, ['config', 'core.safecrlf', 'false']);
  const records = manifest.filter((record) => record.project === project);
  for (const record of records.filter((entry) => entry.existed)) {
    const destination = path.join(directory, record.file); fs.mkdirSync(path.dirname(destination), {recursive: true});
    fs.copyFileSync(path.join(__dirname, 'deployment-backup', project, record.backupFile || record.file), destination);
    git(directory, ['add', '--', record.file]);
  }
  for (const record of records) {
    const destination = path.join(directory, record.file); fs.mkdirSync(path.dirname(destination), {recursive: true});
    fs.copyFileSync(path.join(current, record.file), destination);
    if (!record.existed) git(directory, ['add', '--intent-to-add', '--', record.file]);
  }
  const patch = git(directory, ['diff', '--binary', '--no-ext-diff', '--no-color']);
  const output = path.join(__dirname, project === 'app' ? 'app-backend.patch' : 'admin.patch');
  fs.writeFileSync(output, patch);
  patchManifest[project].bytes = Buffer.byteLength(patch);
  patchManifest[project].stat = git(directory, ['diff', '--stat']);
  patchManifest[project].note = 'Release patch includes existing-admin compatibility and preserves all live index definitions. Already applied and deployed; do not apply again.';
  for (const record of records.filter((entry) => !entry.existed)) {
    git(directory, ['rm', '--cached', '--force', '--quiet', '--', record.file]); fs.unlinkSync(path.join(directory, record.file));
  }
  git(directory, ['checkout', '--', '.']); git(directory, ['apply', '--check', output]);
  console.log(project + ' release patch passes a clean application check.');
}
fs.writeFileSync(path.join(__dirname, 'patch-manifest.json'), JSON.stringify(patchManifest, null, 2));
const allowed = path.resolve('C:/Users/adama/.codex/visualizations/2026/11/04/01a1a518-bf8f-7e01-bc05-ddceb50f9eef');
const target = path.resolve(scratch);
if (path.dirname(target) !== allowed || fs.realpathSync(target) !== target) throw new Error('Unsafe scratch cleanup path.');
fs.rmSync(target, {recursive: true, force: true});
