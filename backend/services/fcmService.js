const { messaging } = require('../config/firebase');
const User = require('../models/User');

/**
 * Send push notification to a user
 * @param {Object} options - Notification options
 * @param {string} options.userId - User ID to send notification to
 * @param {string} options.title - Notification title
 * @param {string} options.body - Notification body
 * @param {Object} options.data - Additional data payload
 * @returns {Promise<Object>} - Result of the send operation
 */
async function sendPushNotification({ userId, title, body, data = {} }) {
  try {
    // Get user's FCM tokens
    const user = await User.findById(userId).select('fcmToken fcmTokens');
    
    if (!user) {
      console.log(`⚠️  User ${userId} not found for push notification`);
      return { success: false, error: 'User not found' };
    }

    // Collect all valid tokens
    const tokens = [];
    if (user.fcmToken) {
      tokens.push(user.fcmToken);
    }
    if (user.fcmTokens && user.fcmTokens.length > 0) {
      user.fcmTokens.forEach(tokenObj => {
        if (tokenObj.token && !tokens.includes(tokenObj.token)) {
          tokens.push(tokenObj.token);
        }
      });
    }

    if (tokens.length === 0) {
      console.log(`⚠️  No FCM tokens found for user ${userId}`);
      return { success: false, error: 'No FCM tokens' };
    }

    // Prepare notification message
    const message = {
      notification: {
        title,
        body,
      },
      data: {
        ...data,
        timestamp: new Date().toISOString(),
      },
    };

    // Send to all tokens
    const results = await Promise.all(
      tokens.map(async (token) => {
        try {
          const response = await messaging.send({
            ...message,
            token,
          });
          console.log(`✅ Notification sent to token: ${token.substring(0, 20)}...`);
          return { success: true, messageId: response };
        } catch (error) {
          console.error(`❌ Failed to send to token ${token.substring(0, 20)}...:`, error.message);
          // Remove invalid tokens
          if (error.code === 'messaging/invalid-registration-token' || 
              error.code === 'messaging/registration-token-not-registered') {
            await User.findByIdAndUpdate(userId, {
              $pull: { fcmTokens: { token } }
            });
          }
          return { success: false, error: error.message };
        }
      })
    );

    const successCount = results.filter(r => r.success).length;
    console.log(`📨 Sent ${successCount}/${tokens.length} notifications to user ${userId}`);

    return {
      success: successCount > 0,
      successCount,
      totalTokens: tokens.length,
      results,
    };
  } catch (error) {
    console.error('❌ Error sending push notification:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Send push notification to multiple users
 * @param {Object} options - Notification options
 * @param {string[]} options.userIds - Array of user IDs
 * @param {string} options.title - Notification title
 * @param {string} options.body - Notification body
 * @param {Object} options.data - Additional data payload
 * @returns {Promise<Object>} - Results of the send operations
 */
async function sendPushNotificationToMultiple({ userIds, title, body, data = {} }) {
  try {
    const results = await Promise.all(
      userIds.map(userId => 
        sendPushNotification({ userId, title, body, data })
      )
    );

    const successCount = results.filter(r => r.success).length;
    console.log(`📨 Sent notifications to ${successCount}/${userIds.length} users`);

    return {
      success: successCount > 0,
      successCount,
      totalUsers: userIds.length,
      results,
    };
  } catch (error) {
    console.error('❌ Error sending push notifications to multiple users:', error);
    return { success: false, error: error.message };
  }
}

module.exports = {
  sendPushNotification,
  sendPushNotificationToMultiple,
};
