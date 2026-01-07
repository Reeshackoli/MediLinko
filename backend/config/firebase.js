// Firebase Admin SDK Configuration
// Works with both local JSON file and environment variables (for production)

let admin, messaging;

try {
  admin = require('firebase-admin');
  
  // Try environment variables first (for Render.com deployment)
  if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
    console.log('🔧 Using Firebase credentials from environment variables');
    
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      }),
    });
    
    messaging = admin.messaging();
    console.log('✅ Firebase Admin SDK initialized successfully (from env vars)');
  } 
  // Fallback to local JSON file (for local development)
  else {
    try {
      const serviceAccount = require('./firebase-service-account.json');
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      
      messaging = admin.messaging();
      console.log('✅ Firebase Admin SDK initialized successfully (from JSON file)');
    } catch (error) {
      console.warn('⚠️  Firebase service account not found. Please add firebase-service-account.json or set environment variables');
      console.warn('   Required env vars: FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL');
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
  }
} catch (error) {
  console.error('❌ Error initializing Firebase:', error.message);
}

module.exports = { admin, messaging };
