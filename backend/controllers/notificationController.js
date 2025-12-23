const Notification = require('../models/Notification');
const User = require('../models/User');
const { admin, messaging } = require('../config/firebase');

// @desc    Get user's notifications
// @route   GET /api/notifications
// @access  Private
exports.getNotifications = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id;
    const { read, limit = 7 } = req.query;

    const filter = { userId };
    if (read !== undefined) {
      filter.read = read === 'true';
    }

    // Auto-cleanup: Delete notifications older than 1 day
    const oneDayAgo = new Date();
    oneDayAgo.setDate(oneDayAgo.getDate() - 1);
    await Notification.deleteMany({
      userId,
      createdAt: { $lt: oneDayAgo },
    });

    // Auto-cleanup: Keep only last 15 notifications
    const totalCount = await Notification.countDocuments({ userId });
    if (totalCount > 15) {
      const notificationsToKeep = await Notification.find({ userId })
        .sort({ createdAt: -1 })
        .limit(15)
        .select('_id');
      
      const idsToKeep = notificationsToKeep.map(n => n._id);
      await Notification.deleteMany({
        userId,
        _id: { $nin: idsToKeep },
      });
    }

    const notifications = await Notification.find(filter)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit));

    res.json({
      success: true,
      count: notifications.length,
      notifications,
    });
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @desc    Get unread notification count
// @route   GET /api/notifications/unread-count
// @access  Private
exports.getUnreadCount = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id;

    const count = await Notification.countDocuments({
      userId,
      read: false,
    });

    res.json({
      success: true,
      count,
    });
  } catch (error) {
    console.error('Error fetching unread count:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @desc    Mark notification as read
// @route   PATCH /api/notifications/:id/read
// @access  Private
exports.markAsRead = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id;
    const { id } = req.params;

    const notification = await Notification.findOne({
      _id: id,
      userId,
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
      });
    }

    notification.read = true;
    await notification.save();

    res.json({
      success: true,
      message: 'Notification marked as read',
      notification,
    });
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @desc    Mark all notifications as read
// @route   PATCH /api/notifications/mark-all-read
// @access  Private
exports.markAllAsRead = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id;

    await Notification.updateMany(
      { userId, read: false },
      { read: true }
    );

    res.json({
      success: true,
      message: 'All notifications marked as read',
    });
  } catch (error) {
    console.error('Error marking all as read:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @desc    Delete notification
// @route   DELETE /api/notifications/:id
// @access  Private
exports.deleteNotification = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id;
    const { id } = req.params;

    const notification = await Notification.findOneAndDelete({
      _id: id,
      userId,
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
      });
    }

    res.json({
      success: true,
      message: 'Notification deleted',
    });
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @desc    Delete all notifications
// @route   DELETE /api/notifications
// @access  Private
exports.deleteAllNotifications = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id;

    const result = await Notification.deleteMany({ userId });

    res.json({
      success: true,
      message: `${result.deletedCount} notifications deleted`,
      deletedCount: result.deletedCount,
    });
  } catch (error) {
    console.error('Error deleting all notifications:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @desc    Send FCM notification to user
// @access  Internal use only (called from other controllers)
exports.sendNotificationToUser = async (userId, notificationData) => {
  try {
    console.log(`🔔 sendNotificationToUser called for userId: ${userId}`);
    
    // Find user and get FCM token
    const user = await User.findById(userId);
    
    if (!user) {
      console.log(`⚠️ User not found: ${userId}`);
      return { success: false, message: 'User not found' };
    }
    
    console.log(`👤 User found: ${user.email}`);
    console.log(`📱 FCM Token: ${user.fcmToken ? 'EXISTS' : 'NOT FOUND'}`);
    
    if (!user.fcmToken) {
      console.log(`⚠️ No FCM token for user ${userId} (${user.email})`);
      // Still save notification to database even if no FCM token
      // Determine notification type from data or default to 'general'
      const notificationType = notificationData.data?.appointmentId ? 'appointment' : 'general';
      
      await Notification.create({
        userId,
        title: notificationData.title,
        message: notificationData.body,
        type: notificationType,
        data: notificationData.data || {},
        read: false,
      });
      console.log(`💾 Notification saved to DB (type: ${notificationType})`);
      return { success: false, message: 'User has no FCM token (notification saved to DB)' };
    }

    const { title, body, data } = notificationData;

    // Prepare FCM message
    const message = {
      token: user.fcmToken,
      notification: {
        title,
        body,
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          channelId: data?.type === 'new_appointment' ? 'appointment_alerts' : 'high_importance_channel',
          sound: 'default',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    console.log(`📨 Sending FCM message:`, { title, body, type: data?.type });

    // Send FCM notification
    const response = await messaging.send(message);
    console.log(`✅ FCM notification sent successfully to user ${userId}:`, response);

    // Save notification to database
    // Determine notification type from data or default to 'general'
    const notificationType = data?.appointmentId ? 'appointment' : 
                            data?.orderId ? 'order' : 
                            data?.reminderType ? 'reminder' : 'general';
    
    await Notification.create({
      userId,
      title,
      message: body,
      type: notificationType,
      data: data || {},
      read: false,
    });
    console.log(`💾 Notification saved to DB (type: ${notificationType})`);

    return { success: true, messageId: response };
  } catch (error) {
    console.error('❌ Error sending FCM notification:', error.message);
    console.error('Error details:', error);
    
    // If token is invalid, clear it from user
    if (error.code === 'messaging/invalid-registration-token' || 
        error.code === 'messaging/registration-token-not-registered') {
      await User.findByIdAndUpdate(userId, { fcmToken: null });
      console.log(`🔄 Cleared invalid FCM token for user ${userId}`);
    }
    
    // Still save notification to database
    try {
      await Notification.create({
        userId,
        title: notificationData.title,
        message: notificationData.body,
        type: notificationData.data?.type || 'general',
        data: notificationData.data || {},
        read: false,
      });
      console.log('💾 Notification saved to database despite FCM error');
    } catch (dbError) {
      console.error('❌ Failed to save notification to DB:', dbError);
    }
    
    return { success: false, error: error.message };
  }
};
