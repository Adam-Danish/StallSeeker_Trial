const { setGlobalOptions } = require("firebase-functions/v2");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Set global options (e.g., max instances)
setGlobalOptions({ maxInstances: 10 });

// Export your HTTP Cloud Function
exports.helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", { structuredData: true });
  response.send("Hello from StallSeeker Firebase!");
});