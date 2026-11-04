const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '../..');
const hash = (bytes) => crypto.createHash('sha256').update(bytes).digest('hex');
const admin = path.resolve(root, '../StallSeeker-Admin/dist');
const adminHtml = fs.readFileSync(path.join(admin, 'index.html'), 'utf8');
const script = adminHtml.match(/src="([^"]+\.js)"/)[1];
const checks = [];
for (const origin of ['https://stallseeker.my', 'https://stallseeker-c2ffe.web.app']) {
  for (const file of ['index.html', 'main.dart.js', 'firebase-messaging-sw.js']) {
    checks.push({url: `${origin}/${file}`, file: path.join(root, 'build/web', file)});
  }
}
for (const origin of ['https://admin.stallseeker.my', 'https://stallseeker-admin.web.app']) {
  checks.push({url: origin + '/index.html', file: path.join(admin, 'index.html')});
  checks.push({url: origin + script, file: path.join(admin, script)});
}
(async () => {
  const results = await Promise.all(checks.map(async (check) => {
    try {
      const response = await fetch(check.url + '?deployment-verification=' + Date.now(), {signal: AbortSignal.timeout(30000)});
      const bytes = Buffer.from(await response.arrayBuffer());
      return {url: check.url, status: response.status, matchesBuild: hash(bytes) === hash(fs.readFileSync(check.file))};
    } catch (error) {
      return {url: check.url, error: error.message, cause: error.cause?.code || error.cause?.message};
    }
  }));
  fs.writeFileSync(path.join(__dirname, 'live-website-verification.json'), JSON.stringify(results, null, 2));
  console.log(JSON.stringify(results, null, 2));
  if (results.some((result) => result.status !== 200 || !result.matchesBuild)) process.exitCode = 1;
})().catch((error) => { console.error(error.message); process.exitCode = 1; });
