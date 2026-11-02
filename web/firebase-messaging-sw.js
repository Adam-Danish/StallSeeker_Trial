// Install click handling before Firebase's default notification handler.
self.addEventListener('notificationclick', function (event) {
  const data = event.notification.data?.FCM_MSG?.data || event.notification.data || {};
  const url = new URL(self.location.origin);
  for (const key of ['bookingId', 'recipientId', 'role', 'vendorId', 'itemId']) {
    if (typeof data[key] === 'string') url.searchParams.set(key, data[key]);
  }
  event.notification.close();
  event.stopImmediatePropagation();
  event.waitUntil(self.clients.matchAll({type: 'window', includeUncontrolled: true})
      .then(async function (clients) {
        const existing = clients.find(client => new URL(client.url).origin === url.origin);
        if (existing) {
          await existing.navigate(url.href);
          return existing.focus();
        }
        return self.clients.openWindow(url.href);
      }));
});

// Keep in step with firebase_core_web's supported Firebase JS SDK version.
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-messaging-compat.js');
firebase.initializeApp({
  apiKey: 'AIzaSyBPTOZDnYDXxe9VNSzYLXPvso5nIiHTsPc',
  appId: '1:793011933510:web:e9cb5587fb777961911547',
  messagingSenderId: '793011933510',
  projectId: 'stallseeker-c2ffe',
  authDomain: 'stallseeker-c2ffe.firebaseapp.com',
  storageBucket: 'stallseeker-c2ffe.firebasestorage.app'
});
firebase.messaging();
