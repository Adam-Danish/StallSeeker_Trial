const fs = require('node:fs');
const path = require('node:path');
const cli = 'C:/Users/adama/AppData/Roaming/npm/node_modules/firebase-tools/lib';
const root = path.resolve(__dirname, '../..');
const {getProjectDefaultAccount, setActiveAccount} = require(path.join(cli, 'auth'));
const {requireAuth} = require(path.join(cli, 'requireAuth'));
const {Client} = require(path.join(cli, 'apiv2'));
(async () => {
  const options = {project: 'stallseeker-c2ffe', projectId: 'stallseeker-c2ffe', nonInteractive: true};
  setActiveAccount(options, getProjectDefaultAccount(root)); await requireAuth(options);
  const firestore = new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1', auth: true});
  const auth = new Client({urlPrefix: 'https://identitytoolkit.googleapis.com', apiVersion: 'v1', auth: true});
  const filters = ['role', 'userRole', 'type'].flatMap((fieldPath) => ['admin', 'Admin', 'ADMIN'].map((value) => ({fieldFilter: {
    field: {fieldPath}, op: 'EQUAL', value: {stringValue: value},
  }})));
  const response = await firestore.post('/projects/stallseeker-c2ffe/databases/(default)/documents:runQuery', {
    structuredQuery: {select: {fields: [{fieldPath: 'role'}, {fieldPath: 'userRole'}, {fieldPath: 'type'}]},
      from: [{collectionId: 'users'}], where: {compositeFilter: {op: 'OR', filters}}, limit: 20},
  });
  const ids = [...new Set(response.body.filter((entry) => entry.document).map((entry) => entry.document.name.split('/').pop()))];
  if (!ids.length) { console.log(JSON.stringify({adminProfiles: 0})); return; }
  const users = (await auth.post('/projects/stallseeker-c2ffe/accounts:lookup', {localId: ids})).body.users || [];
  const report = {adminProfiles: ids.length, adminAuthAccounts: users.length,
    verifiedAdminAccounts: users.filter((user) => user.emailVerified).length,
    enabledUnverifiedAdminAccounts: users.filter((user) => !user.emailVerified && !user.disabled).length};
  fs.writeFileSync(path.join(__dirname, 'admin-access-check.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report));
})().catch((error) => {console.error(error.message); process.exitCode = 1;});
