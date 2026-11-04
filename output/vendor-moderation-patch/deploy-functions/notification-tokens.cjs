'use strict';

// Retain the legacy phone token while supporting separate browser/device tokens.
function notificationTokens(profile) {
  if (!profile || profile.notificationsEnabled === false) return [];
  return [...new Set([
    profile.fcmToken,
    ...(Array.isArray(profile.fcmTokens) ? profile.fcmTokens.slice(-20) : []),
  ].filter(token => typeof token === 'string' && token.trim()))];
}

module.exports = {notificationTokens};
