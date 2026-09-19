'use strict';

const {onSchedule} = require('firebase-functions/v2/scheduler');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {closeScheduledStalls} = require('./closure-core.cjs');

initializeApp();

// Close the persisted Open switch during a planned break. Reopening remains
// a manual vendor action after the break ends.
exports.closeStallsForScheduledBreaks = onSchedule(
    {schedule: 'every 5 minutes', timeZone: 'Asia/Kuala_Lumpur'},
    async () => {
      await closeScheduledStalls(getFirestore(), Date.now());
    });
