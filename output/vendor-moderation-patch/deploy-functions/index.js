require('firebase-admin/app').initializeApp();
Object.assign(exports, require('./moderation.cjs'));
exports.createBooking = require('./bookings.cjs').createBooking;
exports.notifyFollowersOnDishAvailable = require('./dish-notifications.cjs').notifyFollowersOnDishAvailable;
