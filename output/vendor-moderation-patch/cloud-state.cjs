const fs = require('node:fs');
const path = require('node:path');
const cli = 'C:/Users/adama/AppData/Roaming/npm/node_modules/firebase-tools/lib';
const root = path.resolve(__dirname, '../..');
const project = 'stallseeker-c2ffe';
const {getProjectDefaultAccount, setActiveAccount} = require(path.join(cli, 'auth'));
const {requireAuth} = require(path.join(cli, 'requireAuth'));
const {Client} = require(path.join(cli, 'apiv2'));
const rules = require(path.join(cli, 'gcp/rules'));
const hosting = require(path.join(cli, 'hosting/api'));
const output = path.join(__dirname, 'deployment-backup/cloud');
async function setup() {
  const options = {project, projectId: project, nonInteractive: true};
  const account = getProjectDefaultAccount(root);
  if (account) setActiveAccount(options, account);
  await requireAuth(options);
  return new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1', auth: true});
}
async function readIndexes(client) {
  const indexes = [];
  let pageToken;
  do {
    const {body} = await client.get(`/projects/${project}/databases/(default)/collectionGroups/-/indexes`, {queryParams: {...(pageToken ? {pageToken} : {})}});
    indexes.push(...(body.indexes || []));
    pageToken = body.nextPageToken;
  } while (pageToken);
  return indexes;
}
(async () => {
  const client = await setup();
  if (process.argv[2] === 'indexes') {
    const indexes = await readIndexes(client);
    const moderation = indexes.filter((index) => /collectionGroups\/(vendorReports|moderationCases)\//.test(index.name));
    console.log(JSON.stringify(moderation.map(({name, state}) => ({name, state})), null, 2));
    fs.writeFileSync(path.join(__dirname, 'deployed-index-states.json'), JSON.stringify(moderation, null, 2));
    process.exitCode = moderation.length >= 7 && moderation.every((index) => index.state === 'READY') ? 0 : 2;
    return;
  }
  fs.mkdirSync(output, {recursive: true});
  const database = (await client.get(`/projects/${project}/databases/(default)`)).body;
  fs.writeFileSync(path.join(output, 'database.json'), JSON.stringify(database, null, 2));
  const releases = await rules.listAllReleases(project);
  const release = releases.find((entry) => entry.name === `projects/${project}/releases/cloud.firestore`);
  if (!release) throw new Error('Live Firestore rules release not found.');
  const files = await rules.getRulesetContent(release.rulesetName);
  fs.writeFileSync(path.join(output, 'rules-release.json'), JSON.stringify(release, null, 2));
  for (const file of files) fs.writeFileSync(path.join(output, path.basename(file.name)), file.content);
  const previous = fs.readFileSync(path.join(__dirname, 'deployment-backup/app/firestore.rules'), 'utf8').replace(/\r\n/g, '\n');
  const liveRules = files.find((entry) => entry.name.endsWith('.rules'))?.content.replace(/\r\n/g, '\n');
  const indexes = await readIndexes(client);
  fs.writeFileSync(path.join(output, 'indexes.json'), JSON.stringify(indexes, null, 2));
  for (const site of ['stallseeker-c2ffe', 'stallseeker-admin']) {
    const channel = await hosting.getChannel(project, site, 'live');
    fs.writeFileSync(path.join(output, `${site}-hosting.json`), JSON.stringify(channel, null, 2));
  }
  console.log(JSON.stringify({databaseEdition: database.databaseEdition, location: database.locationId,
    liveRulesMatchPrePatch: previous.trim() === liveRules?.trim(), liveIndexes: indexes.length,
    hostingBackupsSaved: true}));
})().catch((error) => { console.error(error.message); process.exitCode = 1; });
