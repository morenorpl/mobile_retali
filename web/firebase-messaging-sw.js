/* web/firebase-messaging-sw.js */
importScripts('https://www.gstatic.com/firebasejs/9.22.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.2/firebase-messaging-compat.js');

// SALIN config dari DefaultFirebaseOptions.web di lib/firebase_options.dart
firebase.initializeApp({
  apiKey: "AIzaSyClGMF7FBoDK3k6fUBEGCULYvum0wfv004",
  authDomain: "project-retali.firebaseapp.com",
  projectId: "project-retali",
  storageBucket: "project-retali.firebasestorage.app",
  messagingSenderId: "323924073046",
  appId: "1:323924073046:web:6003630d8d61377ef739f7"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = (payload.notification && payload.notification.title) || 'Notifikasi';
  const body  = (payload.notification && payload.notification.body)  || '';
  self.registration.showNotification(title, { body });
});
