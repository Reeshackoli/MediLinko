const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const User = require('../models/User');

// @route   POST /api/fcm/save-token
// @desc    Save FCM token for logged-in user
// @access  Private
router.post('/save-token', protect, async (req, res) => {
  try {
    const { token, device } = req.body;
    
    console.log('📥 FCM Token Save Request:', {
      userId: req.user._id,
      email: req.user.email,
      role: req.user.role,
      device,
      tokenPreview: token ? token.substring(0, 30) + '...' : 'NO_TOKEN'
    });
    
    if (!token) {
      console.error('❌ FCM token missing in request');
      return res.status(400).json({ error: 'FCM token is required' });
    }
    
    await User.findByIdAndUpdate(req.user._id, {
      fcmToken: token,
      $addToSet: {
        fcmTokens: { 
          token, 
          device: device || 'unknown',
          updatedAt: new Date()
        }
      }
    });
    
    console.log(`✅ FCM token saved for user: ${req.user.email}`);
    res.json({ success: true, message: 'FCM token saved' });
  } catch (error) {
    console.error('❌ Error saving FCM token:', error);
    res.status(500).json({ error: error.message });
  }
});

// @route   DELETE /api/fcm/remove-token
// @desc    Remove FCM token (on logout)
// @access  Private
router.delete('/remove-token', protect, async (req, res) => {
  try {
    const { token } = req.body;
    
    await User.findByIdAndUpdate(req.user._id, {
      $pull: { fcmTokens: { token } }
    });
    
    res.json({ success: true, message: 'FCM token removed' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
