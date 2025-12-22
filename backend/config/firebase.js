// Firebase Admin SDK Configuration
// IMPORTANT: Download firebase-service-account.json from Firebase Console first!

let admin, messaging;

try {
  admin = require('firebase-admin');
  
  // Try to load service account
  try {
    const serviceAccount = require('./firebase-service-account.json');
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    
    messaging = admin.messaging();
    console.log('✅ Firebase Admin SDK initialized successfully');
  } catch (error) {
    console.warn('⚠️  Firebase service account not found. Please add firebase-service-account.json');
    console.warn('   Download from: Firebase Console → Project Settings → Service Accounts');
    
    // Mock messaging for development
    messaging = {
      send: async () => {
        console.log('📨 Mock notification sent (Firebase not configured)');
        return { messageId: 'mock-' + Date.now() };
      },
      sendMulticast: async () => {
        console.log('📨 Mock notifications sent (Firebase not configured)');
        return { successCount: 0, failureCount: 0 };
      }
    };
  }
} catch (error) {
  console.error('❌ Error initializing Firebase:', error.message);
}

module.exports = { admin, messaging };
