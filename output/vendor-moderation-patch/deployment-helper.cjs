const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const admin = path.resolve(root, '../StallSeeker-Admin');
const backup = path.join(__dirname, 'deployment-backup');
if (fs.existsSync(backup)) throw new Error('Deployment backup already exists; do not overwrite it.');
const manifest = JSON.parse(fs.readFileSync(path.join(__dirname, 'patch-manifest.json'), 'utf8'));
const entries = [];
for (const [name, directory] of [['app', root], ['admin', admin]]) {
  for (const file of manifest[name].files) {
    const source = path.join(directory, file);
    entries.push({project: name, file, existed: fs.existsSync(source)});
    if (fs.existsSync(source)) {
      const destination = path.join(backup, name, file);
      fs.mkdirSync(path.dirname(destination), {recursive: true});
      fs.copyFileSync(source, destination);
    }
  }
}
fs.writeFileSync(path.join(backup, 'manifest.json'), JSON.stringify(entries, null, 2));
console.log('Saved pre-deployment source backups for both projects.');
