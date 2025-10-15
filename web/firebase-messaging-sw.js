/* eslint-disable no-undef */
// Firebase Messaging service worker for web push

importScripts(
  "https://www.gstatic.com/firebasejs/10.13.1/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.13.1/firebase-messaging-compat.js"
);

firebase.initializeApp({
  apiKey: "AIzaSyAF4Tmn8QhhBL8CSVYMlYjxlqVkSSeNl-U",
  appId: "1:369859180116:web:419ce894e1fea1620adfc1",
  messagingSenderId: "369859180116",
  projectId: "fluttertutom2",
  authDomain: "fluttertutom2.firebaseapp.com",
  storageBucket: "fluttertutom2.firebasestorage.app",
  measurementId: "G-PRYD8C8X92",
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title || "Nouveau message";
  const notificationOptions = {
    body: payload.notification?.body || "",
    icon: "/icons/Icon-192.png",
    data: payload.data || {},
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
