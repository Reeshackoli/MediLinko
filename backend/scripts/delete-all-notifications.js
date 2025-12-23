const mongoose = require('mongoose');
const Notification = require('../models/Notification');

// MongoDB connection string - update this to match your config
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/medilinko';

async function deleteAllNotifications() {
  try {
    // Connect to MongoDB
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Delete all notifications
    const result = await Notification.deleteMany({});
    
    console.log(`🗑️  Deleted ${result.deletedCount} notifications`);
    console.log('✅ All notifications cleared successfully!');

    // Close connection
    await mongoose.connection.close();
    console.log('👋 Connection closed');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error deleting notifications:', error);
    process.exit(1);
  }
}

// Run the script
deleteAllNotifications();
