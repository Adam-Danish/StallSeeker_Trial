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
const targets = {
  submitVendorReport: 'asia-southeast1', reviewVendorReport: 'asia-southeast1',
  submitVendorCorrection: 'asia-southeast1', decideVendorModeration: 'asia-southeast1',
  finishResolvedVendorReports: 'asia-southeast1', notifyVendorModeration: 'asia-southeast1',
  notifyFollowersOnDishAvailable: 'asia-southeast1', createBooking: 'us-central1', cleanupDeletedAccount: 'asia-southeast1',
};
(async () => {
  const options = {project, projectId: project, nonInteractive: true};
  setActiveAccount(options, getProjectDefaultAccount(root));
  await requireAuth(options);
  const functions = new Client({urlPrefix: 'https://cloudfunctions.googleapis.com', apiVersion: 'v2', auth: true});
  const results = await Promise.all(Object.entries(targets).map(async ([name, region]) => {
    const {body} = await functions.get(`/projects/${project}/locations/${region}/functions/${name}`);
    return {name, region, state: body.state, updateTime: body.updateTime,
      entryPoint: body.buildConfig?.entryPoint, uri: body.serviceConfig?.uri};
  }));
  const firestore = new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1', auth: true});
  const indexes = (await firestore.get(`/projects/${project}/databases/(default)/collectionGroups/-/indexes`)).body.indexes || [];
  const original = JSON.parse(fs.readFileSync(path.join(__dirname, 'deployment-backup/cloud/indexes.json'), 'utf8'));
  const names = new Set(indexes.map((index) => index.name));
  const preserved = original.every((index) => names.has(index.name));
  const reporting = indexes.filter((index) => /collectionGroups\/(vendorReports|moderationCases)\//.test(index.name));
  const releases = await rules.listAllReleases(project);
  const release = releases.find((entry) => entry.name === `projects/${project}/releases/cloud.firestore`);
  const sources = await rules.getRulesetContent(release.rulesetName);
  const liveRules = sources.find((file) => file.name.endsWith('.rules')).content.replace(/\r\n/g, '\n').trim();
  const localRules = fs.readFileSync(path.join(root, 'firestore.rules'), 'utf8').replace(/\r\n/g, '\n').trim();
  const endpoints = [];
  for (const name of ['submitVendorReport', 'reviewVendorReport', 'submitVendorCorrection', 'decideVendorModeration']) {
    const response = await fetch(`https://asia-southeast1-${project}.cloudfunctions.net/${name}`, {
      method: 'POST', headers: {'Content-Type': 'application/json', Origin: 'https://stallseeker.my'},
      body: JSON.stringify({data: {}}), signal: AbortSignal.timeout(30000),
    });
    const payload = await response.json();
    endpoints.push({name, status: response.status, error: payload.error?.status,
      cors: response.headers.get('access-control-allow-origin')});
  }
  const websites = [];
  if (process.argv[2] !== 'backend') {
    for (const site of ['stallseeker-c2ffe', 'stallseeker-admin']) {
      const channel = await hosting.getChannel(project, site, 'live');
      websites.push({site, url: channel.url, version: channel.release?.version?.name, releaseTime: channel.release?.releaseTime});
    }
  }
  const report = {checkedAt: new Date().toISOString(), functions: results, indexes: {total: indexes.length,
    originalPreserved: preserved, originalCount: original.length,
    reporting: reporting.map(({name, state}) => ({name, state}))},
    rulesMatchLocal: liveRules === localRules, unauthenticatedRequests: endpoints, websites};
  fs.writeFileSync(path.join(__dirname, 'live-deployment-verification.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
  if (!results.every((result) => result.state === 'ACTIVE') || !preserved || reporting.length !== 7 ||
      reporting.some((index) => index.state !== 'READY') || liveRules !== localRules ||
      endpoints.some((endpoint) => endpoint.status !== 401 || endpoint.error !== 'UNAUTHENTICATED')) process.exitCode = 2;
})().catch((error) => { console.error(error.message); process.exitCode = 1; });
